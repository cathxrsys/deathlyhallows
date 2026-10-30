package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.SleepCamera;
import net.minecraft.client.sounds.SoundEngine;
import net.minecraft.sounds.SoundSource;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(SoundEngine.class)
public abstract class SoundEngineMixin {
    // every new and every looping sound gets its volume here
    @Inject(method = "calculateVolume(FLnet/minecraft/sounds/SoundSource;)F", at = @At("RETURN"), cancellable = true)
    private void deathlyhallows$volume(float volume, SoundSource source, CallbackInfoReturnable<Float> cir) {
        cir.setReturnValue(SleepCamera.volume(source, cir.getReturnValueF()));
    }
}
