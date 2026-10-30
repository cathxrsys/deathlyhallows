package com.cathxrsys.deathlyhallows.mixin;

import com.cathxrsys.deathlyhallows.SleepCamera;
import net.minecraft.client.Camera;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.level.BlockGetter;
import net.minecraft.world.phys.Vec3;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

@Mixin(Camera.class)
public abstract class CameraMixin {
    @Shadow
    private boolean detached;

    @Shadow
    protected abstract void setPosition(Vec3 pos);

    @Shadow
    protected abstract void setRotation(float yRot, float xRot);

    @Shadow
    public abstract Vec3 getPosition();

    @Shadow
    public abstract float getYRot();

    @Shadow
    public abstract float getXRot();

    // vanilla has placed the camera in bed by now; the sleep camera may take it elsewhere
    @Inject(method = "setup", at = @At("TAIL"))
    private void deathlyhallows$sleep(BlockGetter level, Entity entity, boolean thirdPerson, boolean mirror, float partial,
                                      CallbackInfo ci) {
        SleepCamera.Pose pose = SleepCamera.update(entity, getPosition(), getYRot(), getXRot());
        if (pose == null) return;
        setPosition(pose.pos());
        setRotation(pose.yaw(), pose.pitch());
        this.detached = true;
    }
}
