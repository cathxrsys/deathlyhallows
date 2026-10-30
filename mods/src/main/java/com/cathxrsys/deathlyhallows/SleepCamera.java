package com.cathxrsys.deathlyhallows;

import net.minecraft.Util;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.player.LocalPlayer;
import net.minecraft.core.BlockPos;
import net.minecraft.core.SectionPos;
import net.minecraft.sounds.SoundSource;
import net.minecraft.util.Mth;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.level.ClipContext;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.LightLayer;
import net.minecraft.world.level.levelgen.Heightmap;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;
import net.minecraft.world.phys.shapes.CollisionContext;

/**
 * The camera of realistic sleep: once in bed, it leaves the house for a spot outside, from where the night is seen
 * passing (the server runs it fast, see RealisticSleep), and comes back when you wake up.
 * It flies there when nothing is in the way, otherwise it dips to black and cuts.
 */
public final class SleepCamera {
    private enum Phase { NONE, WAITING, STAY, OUT, OUTSIDE, BACK }

    // lying down in vanilla takes about a second
    private static final long WAIT_MS = 1200;
    private static final long FADE_OUT_MS = 1400;
    private static final long FADE_BACK_MS = 1000;
    // the shot: candidate spots around the bed, the camera looks at the house and a bit up into the sky
    private static final int[] RADII = {7, 10, 13, 16, 20};
    private static final int ANGLES = 16;
    private static final float TILT = 18.0f;
    // the camera slowly drifts towards the house during the night
    private static final double DOLLY_MAX = 3.0;
    private static final double DOLLY_MS = 25000.0;

    public record Pose(Vec3 pos, float yaw, float pitch) {}

    private static Phase phase = Phase.NONE;
    private static long phaseStart;
    private static boolean fly;
    private static long flyMs;

    private static Vec3 shotPos;
    private static Vec3 shotDir;
    private static float shotYaw, shotPitch;
    private static double dolly;
    private static long dollyStart;

    // where the camera was on the last frame, the way back starts there
    private static Pose last;
    private static Pose backFrom;
    private static boolean overriding;

    private SleepCamera() {}

    private static boolean enabled(Minecraft mc) {
        return Config.realisticSleep && Config.sleepCamera && mc.hasSingleplayerServer()
                && mc.level != null && mc.level.dimension() == Level.OVERWORLD;
    }

    /**
     * Called at the end of Camera.setup with the pose vanilla gave it. Returns the pose to use instead, or null.
     */
    public static Pose update(Entity entity, Vec3 pos, float yaw, float pitch) {
        Minecraft mc = Minecraft.getInstance();
        LocalPlayer player = mc.player;
        Pose vanilla = new Pose(pos, yaw, pitch);
        long now = Util.getMillis();
        boolean sleeping = player != null && entity == player && player.isSleeping();

        Pose pose = null;
        switch (phase) {
            case NONE -> {
                if (sleeping && enabled(mc)) begin(Phase.WAITING, now);
            }
            case WAITING -> {
                if (!sleeping || !enabled(mc)) {
                    phase = Phase.NONE;
                } else if (now - phaseStart >= WAIT_MS && RealisticSleep.sleepersReady()) {
                    if (findShot(mc.level, player, pos)) {
                        fly = clear(mc.level, pos, shotPos);
                        flyMs = fly ? (long) Mth.clamp(1800.0 + pos.distanceTo(shotPos) * 60.0, 1800.0, 3500.0) : FADE_OUT_MS;
                        dollyStart = now + (fly ? flyMs : FADE_OUT_MS / 2);
                        begin(Phase.OUT, now);
                    } else {
                        // underground or walled in: stay in bed and watch the room
                        begin(Phase.STAY, now);
                    }
                }
            }
            case STAY -> {
                if (!sleeping) phase = Phase.NONE;
            }
            case OUT, OUTSIDE -> {
                if (!sleeping) {
                    wake(mc, player, vanilla, now);
                    pose = phase == Phase.BACK ? back(vanilla, now) : null;
                } else if (phase == Phase.OUT) {
                    float t = (now - phaseStart) / (float) flyMs;
                    if (t >= 1.0f) {
                        phase = Phase.OUTSIDE;
                        pose = shot(now);
                    } else if (fly) {
                        pose = lerp(vanilla, shot(now), smootherstep(t));
                    } else {
                        // the cut happens in the dark
                        pose = t < 0.5f ? null : shot(now);
                    }
                } else {
                    pose = shot(now);
                }
            }
            case BACK -> pose = back(vanilla, now);
        }

        overriding = pose != null;
        if (pose != null) last = pose;
        return pose;
    }

    private static void begin(Phase next, long now) {
        phase = next;
        phaseStart = now;
    }

    private static void wake(Minecraft mc, LocalPlayer player, Pose vanilla, long now) {
        // woken by a monster: you are back in your body at once
        if (RealisticSleep.alarmed() || player == null || player.hurtTime > 0 || last == null) {
            phase = Phase.NONE;
            return;
        }
        backFrom = last;
        fly = clear(mc.level, backFrom.pos(), vanilla.pos());
        flyMs = fly ? (long) Mth.clamp(1200.0 + backFrom.pos().distanceTo(vanilla.pos()) * 50.0, 1200.0, 2500.0) : FADE_BACK_MS;
        begin(Phase.BACK, now);
    }

    private static Pose back(Pose vanilla, long now) {
        float t = (now - phaseStart) / (float) flyMs;
        if (t >= 1.0f) {
            phase = Phase.NONE;
            return null;
        }
        if (fly) return lerp(backFrom, vanilla, smootherstep(t));
        return t < 0.45f ? backFrom : null;
    }

    private static Pose shot(long now) {
        double d = dolly * (1.0 - Math.exp(-Math.max(0L, now - dollyStart) / DOLLY_MS));
        return new Pose(shotPos.add(shotDir.scale(d)), shotYaw, shotPitch);
    }

    private static Pose lerp(Pose a, Pose b, float t) {
        return new Pose(a.pos().lerp(b.pos(), t),
                a.yaw() + Mth.wrapDegrees(b.yaw() - a.yaw()) * t,
                Mth.lerp(t, a.pitch(), b.pitch()));
    }

    private static float smootherstep(float t) {
        t = Mth.clamp(t, 0.0f, 1.0f);
        return t * t * t * (t * (t * 6.0f - 15.0f) + 10.0f);
    }

    private static boolean clear(ClientLevel level, Vec3 from, Vec3 to) {
        return level.clip(new ClipContext(from, to, ClipContext.Block.VISUAL, ClipContext.Fluid.ANY,
                CollisionContext.empty())).getType() == HitResult.Type.MISS;
    }

    /** Picks a spot under the open sky around the bed with a free view of the house, preferably looking east at the dawn. */
    private static boolean findShot(ClientLevel level, LocalPlayer player, Vec3 eye) {
        BlockPos bed = player.getSleepingPos().orElse(player.blockPosition());
        Vec3 target = Vec3.atCenterOf(bed).add(0.0, 1.0, 0.0);
        double best = Double.NEGATIVE_INFINITY;
        BlockPos.MutableBlockPos cell = new BlockPos.MutableBlockPos();

        for (int r : RADII) {
            for (int k = 0; k < ANGLES; k++) {
                double a = (k + 0.5 * (r & 1)) * Math.PI * 2.0 / ANGLES;
                double x = target.x + Math.cos(a) * r;
                double z = target.z + Math.sin(a) * r;
                int bx = Mth.floor(x), bz = Mth.floor(z);
                if (!level.hasChunk(SectionPos.blockToSectionCoord(bx), SectionPos.blockToSectionCoord(bz))) continue;

                int ground = level.getHeight(Heightmap.Types.MOTION_BLOCKING, bx, bz);
                double y = Math.max(ground + 2.0, bed.getY() + 3.0);
                if (y - ground > 12.0) continue;
                Vec3 cam = new Vec3(x, y, z);
                cell.set(bx, Mth.floor(y), bz);
                if (level.getBrightness(LightLayer.SKY, cell) < 15) continue;
                if (!level.getFluidState(cell).isEmpty()) continue;
                if (!level.noCollision(new AABB(cam, cam).inflate(0.5))) continue;

                Vec3 look = target.subtract(cam);
                double len = look.length();
                HitResult hit = level.clip(new ClipContext(cam, target, ClipContext.Block.VISUAL, ClipContext.Fluid.NONE,
                        CollisionContext.empty()));
                double free = hit.getType() == HitResult.Type.MISS ? len : hit.getLocation().distanceTo(cam);
                // something close in front of the lens (a tree, a wall) spoils the shot
                if (free < len * 0.45) continue;

                double score = 2.0 * free / len
                        + 0.8 * look.x / len
                        - Math.abs(r - 13) / 13.0
                        - 0.04 * (y - ground);
                if (score <= best) continue;
                best = score;
                shotPos = cam;
                shotDir = look.normalize();
                dolly = Mth.clamp(free - 4.0, 0.0, DOLLY_MAX);
                shotYaw = (float) (Mth.atan2(look.z, look.x) * Mth.RAD_TO_DEG) - 90.0f;
                float lookPitch = (float) -(Mth.atan2(look.y, Math.sqrt(look.x * look.x + look.z * look.z)) * Mth.RAD_TO_DEG);
                shotPitch = Mth.clamp(lookPitch - TILT, -40.0f, 10.0f);
            }
        }
        return best > Double.NEGATIVE_INFINITY;
    }

    // ---- HUD ----

    /** The HUD is hidden while the camera is away from the player. */
    public static boolean hidesHud() {
        return overriding;
    }

    /** The vanilla darkening of the screen in bed is not used: you see the night, or the room, instead. */
    public static boolean hidesSleepOverlay() {
        Minecraft mc = Minecraft.getInstance();
        return Config.realisticSleep && mc.hasSingleplayerServer() && mc.level != null && mc.level.dimension() == Level.OVERWORLD;
    }

    public static void renderFade(GuiGraphics g) {
        float alpha = fade();
        if (alpha <= 0.0f) return;
        g.fill(0, 0, g.guiWidth(), g.guiHeight(), Math.round(alpha * 255.0f) << 24);
    }

    // black dip over the cut: fade in, hold around the cut, fade out
    private static float fade() {
        if (fly || (phase != Phase.OUT && phase != Phase.BACK)) return 0.0f;
        float t = (Util.getMillis() - phaseStart) / (float) flyMs;
        float in = phase == Phase.OUT ? 0.43f : 0.4f;
        float out = phase == Phase.OUT ? 0.57f : 0.5f;
        if (t < in) return smootherstep(t / in);
        if (t < out) return 1.0f;
        return 1.0f - smootherstep((t - out) / (1.0f - out));
    }

    // ---- sounds ----

    /** While the night runs fast, animals, blocks and rain would be a racket; monsters stay loud on purpose. */
    public static float volume(SoundSource source, float volume) {
        if (!RealisticSleep.timelapse()) return volume;
        switch (source) {
            case NEUTRAL, BLOCKS, WEATHER, AMBIENT, PLAYERS -> {
            }
            default -> {
                return volume;
            }
        }
        ClientLevel level = Minecraft.getInstance().level;
        if (level == null) return volume;
        float rate = level.tickRateManager().tickrate();
        if (rate <= 20.0f) return volume;
        return volume * Math.max(0.15f, (float) Math.sqrt(20.0f / rate));
    }
}
