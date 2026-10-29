package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.SmallShield;
import com.llamalad7.mixinextras.injector.wrapoperation.Operation;
import com.llamalad7.mixinextras.injector.wrapoperation.WrapOperation;
import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.client.renderer.ItemInHandRenderer;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;

@Mixin(ItemInHandRenderer.class)
public abstract class ItemInHandRendererMixin {
    // the pose is already at the held item here, so the scaling shrinks the shield around its own position
    @WrapOperation(method = "renderArmWithItem", at = @At(value = "INVOKE",
            target = "Lnet/minecraft/client/renderer/ItemInHandRenderer;renderItem(Lnet/minecraft/world/entity/LivingEntity;Lnet/minecraft/world/item/ItemStack;Lnet/minecraft/world/item/ItemDisplayContext;ZLcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/MultiBufferSource;I)V"))
    private void deathlyhallows$smallShield(ItemInHandRenderer self, LivingEntity entity, ItemStack stack, ItemDisplayContext context,
                                            boolean leftHand, PoseStack pose, MultiBufferSource buffer, int light, Operation<Void> original) {
        pose.pushPose();
        SmallShield.apply(entity, stack, pose);
        original.call(self, entity, stack, context, leftHand, pose, buffer, light);
        pose.popPose();
    }
}
