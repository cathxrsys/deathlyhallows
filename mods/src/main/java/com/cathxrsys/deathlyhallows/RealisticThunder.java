package com.cathxrsys.deathlyhallows;

import net.minecraft.client.Minecraft;
import net.minecraft.client.resources.sounds.SimpleSoundInstance;
import net.minecraft.sounds.SoundEvent;
import net.minecraft.sounds.SoundEvents;
import net.minecraft.sounds.SoundSource;
import net.minecraft.util.RandomSource;
import net.minecraft.world.phys.Vec3;

public final class RealisticThunder {
    private RealisticThunder() {}

    /** Plays a lightning sound once it has travelled from the bolt to the camera. Returns false if disabled. */
    public static boolean play(double x, double y, double z, SoundEvent sound, SoundSource source, float volume, float pitch) {
        if (!Config.realisticThunder) return false;
        Minecraft mc = Minecraft.getInstance();
        Vec3 cam = mc.gameRenderer.getMainCamera().getPosition();
        double dist = cam.distanceTo(new Vec3(x, y, z));
        int ticks = (int) Math.round(dist / Config.soundSpeed * 20.0);

        if (sound == SoundEvents.LIGHTNING_BOLT_THUNDER) {
            // vanilla thunder is equally loud at any range; distant thunder gets quieter and lower
            double gain = 1.0 / (1.0 + Math.max(dist - 300.0, 0.0) / 2500.0);
            if (gain < 0.999) {
                // linear attenuation reaches zero at 16 * volume blocks, so pick volume to hit 'gain' at 'dist'
                volume = (float) (dist / (16.0 * (1.0 - gain)));
                pitch *= (float) (1.0 - 0.25 * (1.0 - gain));
            }
        }

        SimpleSoundInstance instance = new SimpleSoundInstance(sound, source, volume, pitch, RandomSource.create(), x, y, z);
        if (ticks > 0) {
            mc.getSoundManager().playDelayed(instance, ticks);
        } else {
            mc.getSoundManager().play(instance);
        }
        return true;
    }
}
