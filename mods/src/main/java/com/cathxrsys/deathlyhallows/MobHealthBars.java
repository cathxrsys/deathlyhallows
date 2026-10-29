package com.cathxrsys.deathlyhallows;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import it.unimi.dsi.fastutil.ints.Int2ObjectOpenHashMap;
import it.unimi.dsi.fastutil.ints.IntIterator;
import it.unimi.dsi.fastutil.ints.IntOpenHashSet;
import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.entity.EntityRenderDispatcher;
import net.minecraft.util.Mth;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.Mob;
import org.joml.Matrix4f;

/** Red health bar over the mobs the player has hurt, shown while the player is near them. */
public final class MobHealthBars {
    private static final int FULL_BRIGHT = 0xF000F0;
    private static final int BACK = 0xE6101010;
    private static final int LOST = 0xFFF0B8B8;
    private static final int HEALTH = 0xFFD41F1F;

    private static final IntOpenHashSet HURT = new IntOpenHashSet();
    private static final Int2ObjectOpenHashMap<Ghost> GHOSTS = new Int2ObjectOpenHashMap<>();
    private static ClientLevel level;

    private MobHealthBars() {}

    /** Health that was just lost, shrinking to the real value. */
    private static final class Ghost {
        float fraction;
        long nanos;
    }

    /** Called on the client for every damage event; remembers mobs hurt by the player or their projectiles. */
    public static void onDamage(LivingEntity victim, DamageSource source) {
        if (!Config.mobHealthBars || !(victim instanceof Mob) || !victim.level().isClientSide) return;
        Entity attacker = source.getEntity();
        if (attacker == null || attacker != Minecraft.getInstance().player) return;

        if (HURT.add(victim.getId())) {
            // the new health usually has not arrived yet, so this is the health before the hit
            Ghost g = new Ghost();
            g.fraction = fraction(victim);
            GHOSTS.put(victim.getId(), g);
        }
    }

    public static void tick(ClientLevel world) {
        if (world != level) {
            HURT.clear();
            GHOSTS.clear();
            level = world;
        }
        if (HURT.isEmpty() || world.getGameTime() % 20 != 0) return;
        IntIterator it = HURT.iterator();
        while (it.hasNext()) {
            int id = it.nextInt();
            Entity e = world.getEntity(id);
            if (e == null || e.isRemoved() || !e.isAlive()) {
                it.remove();
                GHOSTS.remove(id);
            }
        }
    }

    public static void render(LivingEntity entity, PoseStack pose, MultiBufferSource buffer) {
        if (!Config.mobHealthBars || HURT.isEmpty() || !HURT.contains(entity.getId())) return;
        Minecraft mc = Minecraft.getInstance();
        if (mc.options.hideGui || entity.isInvisible() || !entity.isAlive()) return;
        EntityRenderDispatcher dispatcher = mc.getEntityRenderDispatcher();
        double range = Config.healthBarRange;
        if (dispatcher.distanceToSqr(entity) > range * range) return;

        float health = fraction(entity);
        float opacity = Config.healthBarOpacity / 100.0f;
        Ghost g = GHOSTS.computeIfAbsent(entity.getId(), k -> {
            Ghost n = new Ghost();
            n.fraction = health;
            return n;
        });
        // ease the lost part down independently of the frame rate
        long now = System.nanoTime();
        float dt = g.nanos == 0 ? 0.0f : Mth.clamp((now - g.nanos) / 1.0e9f, 0.0f, 0.5f);
        g.nanos = now;
        if (health >= g.fraction) g.fraction = health;
        else g.fraction += (health - g.fraction) * (1.0f - (float) Math.exp(-dt * 2.5f));
        float lost = Math.max(g.fraction, health);

        float w = Mth.clamp(entity.getBbWidth() * 1.4f, 0.7f, 1.6f);
        float h = 0.09f;
        float border = 0.02f;
        float x = -w / 2;

        pose.pushPose();
        pose.translate(0.0f, entity.getBbHeight() + 0.35f, 0.0f);
        pose.mulPose(dispatcher.cameraOrientation());
        Matrix4f m = pose.last().pose();
        VertexConsumer vc = buffer.getBuffer(RenderType.textBackground());
        // the parts lie side by side in one plane, so they cannot shift against each other when the view moves
        quad(vc, m, x - border, -border, x + w + border, h + border, -0.005f, BACK, opacity);
        quad(vc, m, x, 0.0f, x + w * health, h, 0.0f, HEALTH, opacity);
        quad(vc, m, x + w * health, 0.0f, x + w * lost, h, 0.0f, LOST, opacity);
        pose.popPose();
    }

    private static float fraction(LivingEntity e) {
        float max = e.getMaxHealth();
        return max <= 0 ? 0 : Mth.clamp(e.getHealth() / max, 0.0f, 1.0f);
    }

    private static void quad(VertexConsumer vc, Matrix4f m, float x0, float y0, float x1, float y1, float z, int argb, float opacity) {
        int color = ((int) ((argb >>> 24) * opacity) << 24) | (argb & 0xFFFFFF);
        vc.addVertex(m, x0, y0, z).setColor(color).setLight(FULL_BRIGHT);
        vc.addVertex(m, x1, y0, z).setColor(color).setLight(FULL_BRIGHT);
        vc.addVertex(m, x1, y1, z).setColor(color).setLight(FULL_BRIGHT);
        vc.addVertex(m, x0, y1, z).setColor(color).setLight(FULL_BRIGHT);
    }
}
