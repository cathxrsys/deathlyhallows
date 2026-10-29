package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.MobHealthBars;
import net.minecraft.world.damagesource.DamageSource;
import net.minecraft.world.entity.LivingEntity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(LivingEntity.class)
public abstract class LivingEntityMixin {
    @Inject(method = "handleDamageEvent", at = @At("HEAD"))
    private void deathlyhallows$damaged(DamageSource source, CallbackInfo ci) {
        MobHealthBars.onDamage((LivingEntity) (Object) this, source);
    }
}
