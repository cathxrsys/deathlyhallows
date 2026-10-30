package com.cathxrsys.deathlyhallows;

import net.minecraft.Util;
import net.minecraft.client.Minecraft;
import net.minecraft.server.ServerTickRateManager;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.util.Mth;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.Mob;
import net.minecraft.world.entity.NeutralMob;
import net.minecraft.world.entity.monster.Creeper;
import net.minecraft.world.entity.monster.Monster;
import net.minecraft.world.level.GameRules;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.pathfinder.Path;
import net.minecraft.world.phys.AABB;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Realistic sleep on the integrated server (singleplayer or a LAN world).
 * <p>
 * The night is not skipped: while everyone needed is asleep, the server runs faster and the whole night really
 * happens, so crops and cane grow, furnaces smelt and mobs live on. The players wake at dawn, like in vanilla.
 * When the computer cannot run that many ticks, every tick is worth several: the time of day, random ticks
 * (crops, cane, saplings) and furnaces get the extra ticks, the rest of the world runs at the speed it can.
 * With Night Dangers a monster that can walk up to a sleeper may find them, and a creeper that starts to hiss
 * next to a sleeper wakes them at once.
 */
public final class RealisticSleep {
    // a whole night (from when beds work till dawn) is played in Config.nightLength seconds
    private static final float NIGHT_TICKS = 11500.0f;
    // a sleeper must lie this long before the night speeds up (vanilla skips at 100)
    private static final int START_TICKS = 60;
    private static final long RAMP_MS = 2500;
    // the last ticks before dawn slow down, so the sunrise is not rushed
    private static final float SLOW_TICKS = 1500.0f;
    private static final float MAX_RATE = 1200.0f;
    // at most this many game ticks per server tick when the server is too slow
    private static final float MAX_WARP = 10.0f;
    // the client draws at most 10 ticks per frame, a few spare for a smooth sky
    private static final int CLIENT_TICKS_PER_FRAME = 8;
    // the server may use this share of the real time, the rest is left to the client
    private static final double LOAD = 0.8;
    private static final long PUSH_MS = 50;

    // monsters spawn 24+ blocks away from players, so they are heard a bit beyond that
    private static final double DANGER_RADIUS = 32.0;
    // closer than this a monster coming for a sleeper gets the normal speed, farther it walks up at double speed
    private static final double CLOSE_DIST_SQR = 8.0 * 8.0;
    private static final double HISS_DIST_SQR = 6.0 * 6.0;
    // how often (in ticks of the time of day, so a slow server is not safer) a monster nearby may "hear" a sleeper and come
    private static final float LURE_INTERVAL = 40.0f;
    private static final float LURE_CHANCE = 0.35f;
    private static final int LURE_PATHS = 4;
    // a monster after a sleeper is checked this often (in ticks) for a way to the bed
    private static final int REACH_RECHECK = 20;

    // shared with the client thread
    private static volatile boolean timelapse;
    private static volatile boolean sleepersReady;
    private static volatile long alarmTime = Long.MIN_VALUE / 2;
    private static volatile float warp = 1.0f;

    private static ServerLevel serverLevel;
    private static boolean active;
    private static long startTime;
    private static long targetTime;
    private static long rampStart;
    private static long lastPush;
    private static float normalRate;
    private static float warpDebt;
    private static float lureClock;
    // extra game ticks of this server tick
    private static int extraTicks;

    private static float clientDebt;

    private record Reach(boolean reaches, long until) {}
    private static final Map<Monster, Reach> reach = new HashMap<>();

    private RealisticSleep() {}

    /** True while a night is being played fast. */
    public static boolean timelapse() {
        return timelapse;
    }

    /** True while enough players are in bed for the night to pass. */
    public static boolean sleepersReady() {
        return sleepersReady;
    }

    /** True for a moment after a sleeper was woken by danger. */
    public static boolean alarmed() {
        return Util.getMillis() - alarmTime < 3000;
    }

    /** Whether this level passes its nights itself instead of the vanilla skip. */
    public static boolean handles(ServerLevel level) {
        if (!Config.realisticSleep || level.dimension() != Level.OVERWORLD) return false;
        if (!level.getGameRules().getBoolean(GameRules.RULE_DAYLIGHT)) return false;
        ServerTickRateManager rate = level.getServer().tickRateManager();
        return !rate.isFrozen() && !rate.isSprinting();
    }

    /** Vanilla wakes sleepers as soon as it is day; during the timelapse they sleep until dawn instead. */
    public static boolean keepsAsleep(Level level) {
        return active && level == serverLevel;
    }

    /** Without Night Dangers monsters do not go for players asleep. */
    public static boolean shields(LivingEntity target) {
        return active && !Config.nightDangers && target instanceof ServerPlayer player && player.isSleeping();
    }

    /** Extra game ticks the overworld gets in this server tick; 0 unless the server is too slow for the night. */
    public static int extraTicks(Level level) {
        return level == serverLevel && active ? extraTicks : 0;
    }

    /** The same for the client clock, so the sun moves smoothly between the time updates of the server. */
    public static int clientExtraTicks() {
        if (!timelapse) {
            clientDebt = 0.0f;
            return 0;
        }
        clientDebt += warp - 1.0f;
        int n = (int) clientDebt;
        clientDebt -= n;
        return n;
    }

    /** Called at the start of every server level tick. Returns true when the night is over and everyone must wake. */
    public static boolean tickServer(ServerLevel level) {
        if (level.dimension() != Level.OVERWORLD) return false;
        extraTicks = 0;
        if (level != serverLevel) {
            serverLevel = level;
            active = false;
            timelapse = false;
        }

        List<ServerPlayer> sleepers = new ArrayList<>();
        int players = 0;
        int lyingLongEnough = 0;
        for (ServerPlayer player : level.players()) {
            if (player.isSpectator()) continue;
            players++;
            if (!player.isSleeping()) continue;
            sleepers.add(player);
            if (player.getSleepTimer() >= START_TICKS) lyingLongEnough++;
        }
        int pct = level.getGameRules().getInt(GameRules.RULE_PLAYERS_SLEEPING_PERCENTAGE);
        int needed = Math.max(1, Mth.ceil(players * pct / 100.0f));
        sleepersReady = players > 0 && sleepers.size() >= needed;

        boolean handles = handles(level);
        if (!active) {
            if (!handles || players == 0 || lyingLongEnough < needed) return false;
            start(level);
        }
        // someone left the bed or was hurt
        if (!handles || sleepers.size() < needed) {
            stop(level);
            return false;
        }

        long time = level.getDayTime();
        if (time < startTime) {
            // the time was set back by a command
            startTime = time;
            targetTime = nextDawn(time);
        }
        if (time >= targetTime) {
            stop(level);
            return true;
        }

        double threat = Double.MAX_VALUE;
        if (Config.nightDangers) {
            lureClock += warp;
            boolean lureNow = lureClock >= LURE_INTERVAL;
            if (lureNow) lureClock -= LURE_INTERVAL;
            for (ServerPlayer sleeper : sleepers) {
                if (sleeper.isCreative()) continue;
                if (creeperHisses(level, sleeper)) {
                    sleeper.stopSleepInBed(true, true);
                    alarmTime = Util.getMillis();
                    stop(level);
                    return false;
                }
                threat = Math.min(threat, hunted(level, sleeper));
                if (lureNow) lure(level, sleeper);
            }
        } else {
            if (level.getGameTime() % 20 == 0) {
                for (ServerPlayer sleeper : sleepers) forget(level, sleeper);
            }
        }

        updateRate(level, targetTime - time, threat);
        return false;
    }

    private static long nextDawn(long time) {
        return (time / 24000L + 1L) * 24000L;
    }

    private static void start(ServerLevel level) {
        active = true;
        timelapse = true;
        startTime = level.getDayTime();
        targetTime = nextDawn(startTime);
        normalRate = level.getServer().tickRateManager().tickrate();
        rampStart = Util.getMillis();
        lastPush = 0;
        warpDebt = 0.0f;
        warp = 1.0f;
        reach.clear();
    }

    private static void stop(ServerLevel level) {
        active = false;
        timelapse = false;
        warp = 1.0f;
        extraTicks = 0;
        reach.clear();
        ServerTickRateManager rate = level.getServer().tickRateManager();
        if (rate.tickrate() != normalRate) rate.setTickRate(normalRate);
    }

    private static void updateRate(ServerLevel level, long remaining, double threat) {
        ServerTickRateManager manager = level.getServer().tickRateManager();
        long now = Util.getMillis();
        float current = manager.tickrate();

        float want;
        if (threat < Double.MAX_VALUE) {
            // something is coming: let it walk up, and let it happen at normal speed, then speed up again from scratch
            want = threat < CLOSE_DIST_SQR ? normalRate : 2.0f * normalRate;
            rampStart = now;
        } else {
            float peak = Math.max(normalRate, NIGHT_TICKS / Config.nightLength);
            float up = smoothstep((now - rampStart) / (float) RAMP_MS);
            float down = (float) Math.sqrt(Mth.clamp(remaining / SLOW_TICKS, 0.0f, 1.0f));
            want = normalRate + (peak - normalRate) * Math.min(up, down);
        }
        // never ask for more ticks than this computer can run, nor more than the client can draw
        float rate = Mth.clamp(want, normalRate, MAX_RATE);
        long tickNanos = level.getServer().getAverageTickTimeNanos();
        if (tickNanos > 0) rate = Math.min(rate, (float) (LOAD * 1.0e9 / tickNanos));
        rate = Math.max(normalRate, Math.min(rate, Minecraft.getInstance().getFps() * CLIENT_TICKS_PER_FRAME));

        // what the ticks cannot do, every tick does several times
        warp = Mth.clamp(want / current, 1.0f, MAX_WARP);
        warpDebt += warp - 1.0f;
        extraTicks = Math.min((int) warpDebt, (int) Math.max(0L, remaining - 1L));
        warpDebt -= (int) warpDebt;

        // every change is sent to the client, so do it a few times a second, but slow down at once
        boolean slowDown = rate == normalRate && current != normalRate;
        if (!slowDown && (now - lastPush < PUSH_MS || Math.abs(rate - current) < current * 0.03f)) return;
        manager.setTickRate(rate);
        lastPush = now;
    }

    private static float smoothstep(float t) {
        t = Mth.clamp(t, 0.0f, 1.0f);
        return t * t * (3.0f - 2.0f * t);
    }

    private static AABB around(ServerPlayer sleeper, double radius) {
        return sleeper.getBoundingBox().inflate(radius, radius / 2.0, radius);
    }

    // the hiss is what wakes you: a creeper started to swell right next to the bed
    private static boolean creeperHisses(ServerLevel level, ServerPlayer sleeper) {
        for (Creeper creeper : level.getEntitiesOfClass(Creeper.class, around(sleeper, 8.0), Entity::isAlive)) {
            if ((creeper.getSwellDir() > 0 || creeper.isIgnited()) && creeper.distanceToSqr(sleeper) < HISS_DIST_SQR) return true;
        }
        return false;
    }

    // squared distance of the closest monster on its way to the sleeper that can get there, MAX_VALUE if none.
    // A monster that saw the sleeper through a window or stands at a closed door is no danger, the night goes on
    private static double hunted(ServerLevel level, ServerPlayer sleeper) {
        double closest = Double.MAX_VALUE;
        for (Monster monster : level.getEntitiesOfClass(Monster.class, around(sleeper, DANGER_RADIUS), Entity::isAlive)) {
            if (monster.getTarget() != sleeper) continue;
            double d = monster.distanceToSqr(sleeper);
            if (d < closest && reaches(level, monster, sleeper)) closest = d;
        }
        reach.keySet().removeIf(m -> m.isRemoved() || m.getTarget() == null);
        return closest;
    }

    // whether the monster can walk up to the bed, by its own pathfinder: a closed door stops it,
    // unless it is a zombie that breaks doors (hard difficulty)
    private static boolean reaches(ServerLevel level, Monster monster, ServerPlayer sleeper) {
        long now = level.getGameTime();
        Reach known = reach.get(monster);
        if (known != null && now < known.until()) return known.reaches();
        Path path = monster.getNavigation().createPath(sleeper, 1);
        boolean reaches = path != null && path.canReach();
        reach.put(monster, new Reach(reaches, now + REACH_RECHECK));
        return reaches;
    }

    // monsters nearby may hear a sleeper; they come only if they can walk up to the bed (an open door, a hole in the wall)
    private static void lure(ServerLevel level, ServerPlayer sleeper) {
        List<Monster> idle = level.getEntitiesOfClass(Monster.class, around(sleeper, DANGER_RADIUS),
                m -> m.isAlive() && !m.isNoAi() && m.getTarget() == null && !(m instanceof NeutralMob));
        idle.sort(Comparator.comparingDouble(m -> m.distanceToSqr(sleeper)));
        int tries = 0;
        for (Monster monster : idle) {
            if (tries >= LURE_PATHS) break;
            if (level.getRandom().nextFloat() >= LURE_CHANCE) continue;
            tries++;
            if (reaches(level, monster, sleeper)) monster.setTarget(sleeper);
        }
    }

    // safe sleep: mobs that were already after a player lose interest once they fall asleep
    private static void forget(ServerLevel level, ServerPlayer sleeper) {
        for (Mob mob : level.getEntitiesOfClass(Mob.class, around(sleeper, 2.0 * DANGER_RADIUS), m -> m.getTarget() == sleeper)) {
            mob.setTarget(null);
        }
    }
}
