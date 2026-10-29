package com.cathxrsys.deathlyhallows;

import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.util.Mth;
import net.minecraft.util.RandomSource;
import net.minecraft.world.level.levelgen.Heightmap;
import net.minecraft.world.phys.Vec3;

/** Spawns client-side bolts beyond the server's lightning range during thunderstorms. */
public final class DistantLightning {
    // the server sends bolts only within ~256 blocks, so simulated ones start past that
    private static final double MIN_DISTANCE = 300.0;
    // with simulated weather there are no server bolts at all, so strikes also happen closer
    private static final double MIN_DISTANCE_SIMULATED = 100.0;

    private static final RandomSource RANDOM = RandomSource.create();
    // negative ids never collide with server entities (ClientLevel.addEntity replaces an entity with the same id)
    private static int nextId = -1_000_000;

    private DistantLightning() {}

    public static void tick(ClientLevel level) {
        if (!Config.distantLightning || !level.isThundering()) return;
        if (RANDOM.nextFloat() >= chancePerTick()) return;

        double min = CustomWeather.replacesServerBolts() ? MIN_DISTANCE_SIMULATED : MIN_DISTANCE;
        double max = Config.lightningRange * 1000.0;
        // uniform over the ring area: far strikes are more common, as in reality
        double d = Math.sqrt(Mth.lerp(RANDOM.nextDouble(), min * min, max * max));
        double a = RANDOM.nextDouble() * Math.PI * 2.0;
        Vec3 cam = Minecraft.getInstance().gameRenderer.getMainCamera().getPosition();
        double x = cam.x + Math.sin(a) * d;
        double z = cam.z + Math.cos(a) * d;

        DistantLightningBolt bolt = new DistantLightningBolt(level, d);
        bolt.setId(nextId--);
        bolt.moveTo(x, groundY(level, x, z), z);
        level.addEntity(bolt);
    }

    // one strike every ~10 s on average, more often in constant storms
    private static float chancePerTick() {
        return switch (WeatherCycle.effectiveThunder(Config.rainFrequency, Config.thunderFrequency)) {
            case ALWAYS -> 1.0f / 90.0f;
            case OFTEN -> 1.0f / 130.0f;
            default -> 1.0f / 200.0f;
        };
    }

    // close strikes land on the terrain when its chunk is loaded
    private static double groundY(ClientLevel level, double x, double z) {
        int bx = Mth.floor(x);
        int bz = Mth.floor(z);
        if (level.hasChunk(bx >> 4, bz >> 4)) return level.getHeight(Heightmap.Types.MOTION_BLOCKING, bx, bz);
        return level.getSeaLevel();
    }
}
