package com.cathxrsys.deathlyhallows;

import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.util.Mth;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.ShieldItem;

/** Scale of the first-person shield in the left hand: smaller while idle, full size and smoothly while blocking. */
public final class SmallShield {
    private static float current = 1.0f;
    private static long lastNanos;

    private SmallShield() {}

    /** Scales the pose for the shield about to be drawn. Returns false if the item is not affected. */
    public static boolean apply(LivingEntity entity, ItemStack stack, PoseStack pose) {
        if (!Config.smallShield || !(stack.getItem() instanceof ShieldItem)) return false;
        // only the off-hand one; a shield in the main hand stays as it is
        if (entity.getOffhandItem() != stack || entity.getMainHandItem() == stack) return false;

        boolean blocking = entity.isUsingItem() && entity.getUsedItemHand() == InteractionHand.OFF_HAND;
        float target = blocking ? 1.0f : Config.shieldScale / 100.0f;

        // ease towards the target independently of the frame rate
        long now = System.nanoTime();
        float dt = lastNanos == 0 ? 1.0f : Mth.clamp((now - lastNanos) / 1.0e9f, 0.0f, 0.5f);
        lastNanos = now;
        current += (target - current) * (1.0f - (float) Math.exp(-dt * 18.0f));

        pose.scale(current, current, current);
        return true;
    }
}
