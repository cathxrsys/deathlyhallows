package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.MobHealthBars;
import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.entity.LivingEntityRenderer;
import net.minecraft.world.entity.LivingEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(LivingEntityRenderer.class)
public abstract class LivingEntityRendererMixin {
    // the pose is at the entity's feet here
    @Inject(method = "render(Lnet/minecraft/world/entity/LivingEntity;FFLcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/MultiBufferSource;I)V",
            at = @At("TAIL"))
    private void deathlyhallows$healthBar(LivingEntity entity, float yaw, float partialTick, PoseStack pose,
                                          MultiBufferSource buffer, int light, CallbackInfo ci) {
        MobHealthBars.render(entity, pose, buffer);
    }
}
