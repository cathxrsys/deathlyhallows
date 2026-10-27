package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.DistantLightningBolt;
import com.cathxrsys.deathlyhallows.RealisticThunder;
import com.llamalad7.mixinextras.injector.wrapoperation.Operation;
import com.llamalad7.mixinextras.injector.wrapoperation.WrapOperation;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.LightningBolt;
import net.minecraft.world.level.Level;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;

@Mixin(LightningBolt.class)
public abstract class LightningBoltMixin {
    // vanilla plays thunder and impact instantly on the client; delay both by distance / speed of sound
    @WrapOperation(method = "tick", at = @At(value = "INVOKE",
            target = "Lnet/minecraft/world/level/Level;playLocalSound(DDDLnet/minecraft/sounds/SoundEvent;Lnet/minecraft/sounds/SoundSource;FFZ)V"))
    private void deathlyhallows$delaySound(Level level, double x, double y, double z, SoundEvent sound, SoundSource source,
                                           float volume, float pitch, boolean distanceDelay, Operation<Void> original) {
        if (!level.isClientSide() || !RealisticThunder.play(x, y, z, sound, source, volume, pitch)) {
            original.call(level, x, y, z, sound, source, volume, pitch, distanceDelay);
        }
    }

    // a strike kilometers away should not light up the whole world
    @WrapOperation(method = "tick", at = @At(value = "INVOKE",
            target = "Lnet/minecraft/world/level/Level;setSkyFlashTime(I)V"))
    private void deathlyhallows$skipFarFlash(Level level, int time, Operation<Void> original) {
        if (!((Object) this instanceof DistantLightningBolt bolt && bolt.isFar())) {
            original.call(level, time);
        }
    }
}
