package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.CustomWeather;
import com.cathxrsys.deathlyhallows.CropMarkers;
import com.cathxrsys.deathlyhallows.DistantLightning;
import com.cathxrsys.deathlyhallows.MobHealthBars;
import com.cathxrsys.deathlyhallows.RealisticSleep;
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
        CropMarkers.tick((ClientLevel) (Object) this);
        MobHealthBars.tick((ClientLevel) (Object) this);
    }

    // the client clock follows the warped time of a slow server between its time updates
    @Inject(method = "tickTime", at = @At("TAIL"))
    private void deathlyhallows$warpTime(CallbackInfo ci) {
        int extra = RealisticSleep.clientExtraTicks();
        ClientLevel level = (ClientLevel) (Object) this;
        if (extra > 0) level.setDayTime(level.getDayTime() + extra);
    }
}
