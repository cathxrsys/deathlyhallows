package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.CustomWeather;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.world.level.storage.ServerLevelData;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(ServerLevel.class)
public abstract class ServerLevelMixin {
    @Shadow
    @Final
    private ServerLevelData serverLevelData;

    // only the integrated server exists in this client mod, i.e. singleplayer or a LAN world
    @Inject(method = "advanceWeatherCycle", at = @At("HEAD"))
    private void deathlyhallows$weather(CallbackInfo ci) {
        CustomWeather.tickServer((ServerLevel) (Object) this, serverLevelData);
    }
}
