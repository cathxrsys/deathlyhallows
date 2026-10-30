package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.RealisticSleep;
import com.llamalad7.mixinextras.injector.ModifyExpressionValue;
import net.minecraft.world.entity.player.Player;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;

@Mixin(Player.class)
public abstract class PlayerMixin {
    // vanilla gets a sleeper up as soon as the sky is light; during the timelapse they sleep through the sunrise.
    // Fabric API already redirects this call, so the result is modified instead (a second @Redirect crashes the game)
    @ModifyExpressionValue(method = "tick", at = @At(value = "INVOKE", target = "Lnet/minecraft/world/level/Level;isDay()Z"))
    private boolean deathlyhallows$isDay(boolean isDay) {
        return isDay && !RealisticSleep.keepsAsleep(((Player) (Object) this).level());
    }
}
