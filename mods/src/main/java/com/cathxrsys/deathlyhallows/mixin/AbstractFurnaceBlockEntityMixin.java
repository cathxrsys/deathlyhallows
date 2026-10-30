package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.RealisticSleep;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.entity.AbstractFurnaceBlockEntity;
import net.minecraft.world.level.block.state.BlockState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Unique;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(AbstractFurnaceBlockEntity.class)
public abstract class AbstractFurnaceBlockEntityMixin {
    @Unique
    private static boolean deathlyhallows$extraTick;

    // furnaces, smokers and blast furnaces keep up with the warped night of a slow server
    @Inject(method = "serverTick", at = @At("HEAD"))
    private static void deathlyhallows$warp(Level level, BlockPos pos, BlockState state, AbstractFurnaceBlockEntity furnace,
                                            CallbackInfo ci) {
        if (deathlyhallows$extraTick) return;
        int extra = RealisticSleep.extraTicks(level);
        if (extra <= 0) return;
        deathlyhallows$extraTick = true;
        try {
            // a tick may light or put out the furnace, so the state is read again each time
            for (int i = 0; i < extra && !furnace.isRemoved(); i++) {
                AbstractFurnaceBlockEntity.serverTick(level, pos, level.getBlockState(pos), furnace);
            }
        } finally {
            deathlyhallows$extraTick = false;
        }
    }
}
