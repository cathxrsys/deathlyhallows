package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.CustomWeather;
import com.cathxrsys.deathlyhallows.DistantLightning;
import net.minecraft.client.multiplayer.ClientLevel;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import java.util.function.BooleanSupplier;

@Mixin(ClientLevel.class)
public abstract class ClientLevelMixin {
    @Inject(method = "tick", at = @At("HEAD"))
    private void deathlyhallows$tick(BooleanSupplier hasTimeLeft, CallbackInfo ci) {
        CustomWeather.tickClient((ClientLevel) (Object) this);
        DistantLightning.tick((ClientLevel) (Object) this);
    }
}
