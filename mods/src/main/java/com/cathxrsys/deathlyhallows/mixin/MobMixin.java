package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.RealisticSleep;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.entity.Mob;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Mob.class)
public abstract class MobMixin {
    @Inject(method = "setTarget", at = @At("HEAD"), cancellable = true)
    private void deathlyhallows$target(LivingEntity target, CallbackInfo ci) {
        if (RealisticSleep.shields(target)) ci.cancel();
    }
}
