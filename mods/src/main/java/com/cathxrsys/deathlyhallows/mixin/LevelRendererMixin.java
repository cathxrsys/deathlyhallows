package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.CropMarkers;
import net.minecraft.client.Camera;
import net.minecraft.client.DeltaTracker;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.client.renderer.LevelRenderer;
import net.minecraft.client.renderer.LightTexture;
import org.joml.Matrix4f;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(LevelRenderer.class)
public abstract class LevelRendererMixin {
    // after the entities, before the block entities: the same buffers and shader state as the mob health bars
    @Inject(method = "renderLevel", at = @At(value = "INVOKE_STRING",
            target = "Lnet/minecraft/util/profiling/ProfilerFiller;popPush(Ljava/lang/String;)V", args = "ldc=blockentities"))
    private void deathlyhallows$cropMarkers(DeltaTracker deltaTracker, boolean renderBlockOutline, Camera camera,
                                            GameRenderer gameRenderer, LightTexture lightTexture,
                                            Matrix4f frustumMatrix, Matrix4f projectionMatrix, CallbackInfo ci) {
        CropMarkers.render(camera);
    }
}
