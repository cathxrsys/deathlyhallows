package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.SleepCamera;
import net.minecraft.client.DeltaTracker;
import net.minecraft.client.gui.Gui;
import net.minecraft.client.gui.GuiGraphics;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Gui.class)
public abstract class GuiMixin {
    // no hotbar or hearts while the sleep camera is outside
    @Inject(method = "render", at = @At("HEAD"), cancellable = true)
    private void deathlyhallows$hideHud(GuiGraphics g, DeltaTracker deltaTracker, CallbackInfo ci) {
        if (!SleepCamera.hidesHud()) return;
        SleepCamera.renderFade(g);
        ci.cancel();
    }

    @Inject(method = "render", at = @At("TAIL"))
    private void deathlyhallows$fade(GuiGraphics g, DeltaTracker deltaTracker, CallbackInfo ci) {
        SleepCamera.renderFade(g);
    }

    @Inject(method = "renderSleepOverlay", at = @At("HEAD"), cancellable = true)
    private void deathlyhallows$sleepOverlay(GuiGraphics g, DeltaTracker deltaTracker, CallbackInfo ci) {
        if (SleepCamera.hidesSleepOverlay()) ci.cancel();
    }
}
