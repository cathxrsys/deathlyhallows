package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.CampfireCooking;
import com.cathxrsys.deathlyhallows.Config;
import com.llamalad7.mixinextras.injector.wrapoperation.Operation;
import com.llamalad7.mixinextras.injector.wrapoperation.WrapOperation;
import com.llamalad7.mixinextras.sugar.Local;
import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.blockentity.CampfireRenderer;
import net.minecraft.client.renderer.entity.ItemRenderer;
import net.minecraft.world.item.ItemDisplayContext;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.CampfireBlockEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(CampfireRenderer.class)
public abstract class CampfireRendererMixin {
    @Inject(method = "render(Lnet/minecraft/world/level/block/entity/CampfireBlockEntity;FLcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/MultiBufferSource;II)V",
            at = @At("HEAD"))
    private void deathlyhallows$sync(CampfireBlockEntity campfire, float partialTick, PoseStack pose,
                                     MultiBufferSource buffer, int light, int overlay, CallbackInfo ci) {
        CampfireCooking.sync(campfire);
    }

    // the raw item is drawn with a texture that gradually becomes the cooked one
    @WrapOperation(method = "render(Lnet/minecraft/world/level/block/entity/CampfireBlockEntity;FLcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/MultiBufferSource;II)V",
            at = @At(value = "INVOKE",
                    target = "Lnet/minecraft/client/renderer/entity/ItemRenderer;renderStatic(Lnet/minecraft/world/item/ItemStack;Lnet/minecraft/world/item/ItemDisplayContext;IILcom/mojang/blaze3d/vertex/PoseStack;Lnet/minecraft/client/renderer/MultiBufferSource;Lnet/minecraft/world/level/Level;I)V"))
    private void deathlyhallows$cooking(ItemRenderer self, ItemStack stack, ItemDisplayContext context, int light, int overlay,
                                        PoseStack pose, MultiBufferSource buffer, Level level, int seed, Operation<Void> original,
                                        @Local(argsOnly = true) CampfireBlockEntity campfire,
                                        @Local(argsOnly = true) float partialTick) {
        // the seed is the block position plus the slot index
        int slot = seed - (int) campfire.getBlockPos().asLong();
        CampfireCooking.Progress progress = Config.campfireCooking ? CampfireCooking.get(campfire, slot, stack, partialTick) : null;
        if (progress == null) {
            original.call(self, stack, context, light, overlay, pose, buffer, level, seed);
            return;
        }
        float fraction = progress.fraction();
        if (fraction >= 0.98f) {
            original.call(self, progress.result(), context, light, overlay, pose, buffer, level, seed);
            return;
        }
        MultiBufferSource blended = fraction > 0.02f
                ? CampfireCooking.blended(self, stack, progress.result(), level, fraction, buffer) : null;
        original.call(self, stack, context, light, overlay, pose, blended != null ? blended : buffer, level, seed);
    }
}
