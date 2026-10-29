package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.CustomWeather;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.world.level.Level;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

@Mixin(Level.class)
public abstract class LevelMixin {
    // rain, thunder, sky darkening, fog, sounds and the shader uniforms all read the weather through these two
    @Inject(method = "getRainLevel", at = @At("RETURN"), cancellable = true)
    private void deathlyhallows$rain(float partial, CallbackInfoReturnable<Float> cir) {
        if ((Object) this instanceof ClientLevel level) {
            cir.setReturnValue(CustomWeather.rainLevel(level, cir.getReturnValueF(), partial));
        }
    }

    @Inject(method = "getThunderLevel", at = @At("RETURN"), cancellable = true)
    private void deathlyhallows$thunder(float partial, CallbackInfoReturnable<Float> cir) {
        if ((Object) this instanceof ClientLevel level) {
            cir.setReturnValue(CustomWeather.thunderLevel(level, cir.getReturnValueF(), partial));
        }
    }
}
