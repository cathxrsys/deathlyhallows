package com.cathxrsys.deathlyhallows;

import net.minecraft.world.entity.EntityType;
import net.minecraft.world.entity.LightningBolt;
import net.minecraft.world.level.Level;

/** Client-only bolt far outside the loaded chunks. Goes through the vanilla bolt logic (sound, Iris uniform). */
public class DistantLightningBolt extends LightningBolt {
    // further than this the vanilla whole-world flash is skipped, the shader dims its own flash by distance
    private static final double FLASH_DISTANCE = 1000.0;

    private final boolean far;

    public DistantLightningBolt(Level level, double distance) {
        super(EntityType.LIGHTNING_BOLT, level);
        setVisualOnly(true);
        far = distance > FLASH_DISTANCE;
    }

    public boolean isFar() {
        return far;
    }

    // the chunk under the bolt is not loaded, so the level would never tick it otherwise
    @Override
    public boolean isAlwaysTicking() {
        return true;
    }
}
