package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.CustomWeather;
import com.cathxrsys.deathlyhallows.RealisticSleep;
import com.llamalad7.mixinextras.injector.ModifyExpressionValue;
import net.minecraft.server.level.ServerLevel;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.server.players.SleepStatus;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.level.storage.ServerLevelData;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.ModifyVariable;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

import java.util.List;
import java.util.function.BooleanSupplier;

@Mixin(ServerLevel.class)
public abstract class ServerLevelMixin {
    @Shadow
    @Final
    private ServerLevelData serverLevelData;

    @Shadow
    @Final
    private SleepStatus sleepStatus;

    @Shadow
    public abstract List<ServerPlayer> players();

    // only the integrated server exists in this client mod, i.e. singleplayer or a LAN world
    @Inject(method = "advanceWeatherCycle", at = @At("HEAD"))
    private void deathlyhallows$weather(CallbackInfo ci) {
        CustomWeather.tickServer((ServerLevel) (Object) this, serverLevelData);
    }

    @Inject(method = "tick", at = @At("HEAD"))
    private void deathlyhallows$sleep(BooleanSupplier hasTimeLeft, CallbackInfo ci) {
        if (!RealisticSleep.tickServer((ServerLevel) (Object) this)) return;
        // dawn: the same as vanilla wakeUpAllPlayers, but the night was not skipped
        sleepStatus.removeAllSleepers();
        players().stream().filter(LivingEntity::isSleeping).toList().forEach(p -> p.stopSleepInBed(false, false));
    }

    // a slow server makes up for the ticks it cannot run: the sun moves several ticks per tick
    @Inject(method = "tickTime", at = @At("TAIL"))
    private void deathlyhallows$warpTime(CallbackInfo ci) {
        ServerLevel level = (ServerLevel) (Object) this;
        int extra = RealisticSleep.extraTicks(level);
        if (extra > 0) level.setDayTime(level.getDayTime() + extra);
    }

    // ...and crops, cane and saplings get as many more random ticks
    @ModifyVariable(method = "tickChunk", at = @At("HEAD"), argsOnly = true)
    private int deathlyhallows$warpRandomTicks(int randomTickSpeed) {
        return randomTickSpeed * (1 + RealisticSleep.extraTicks((ServerLevel) (Object) this));
    }

    // the vanilla night skip
    // (other mods may redirect these calls too, so the result is modified rather than redirected)
    @ModifyExpressionValue(method = "tick", at = @At(value = "INVOKE",
            target = "Lnet/minecraft/server/players/SleepStatus;areEnoughDeepSleeping(ILjava/util/List;)Z"))
    private boolean deathlyhallows$skipNight(boolean enough) {
        return enough && !RealisticSleep.handles((ServerLevel) (Object) this);
    }
}
