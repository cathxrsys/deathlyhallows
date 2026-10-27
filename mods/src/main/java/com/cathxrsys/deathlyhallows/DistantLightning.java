package com.cathxrsys.deathlyhallows;

import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.util.Mth;
import net.minecraft.util.RandomSource;
import net.minecraft.world.phys.Vec3;

/** Spawns client-side bolts beyond the server's lightning range during thunderstorms. */
public final class DistantLightning {
    // the server sends bolts only within ~256 blocks, so simulated ones start past that
    private static final double MIN_DISTANCE = 300.0;
    // one strike every ~10 s on average
    private static final float CHANCE_PER_TICK = 1.0f / 200.0f;

    private static final RandomSource RANDOM = RandomSource.create();
    // negative ids never collide with server entities (ClientLevel.addEntity replaces an entity with the same id)
    private static int nextId = -1_000_000;

    private DistantLightning() {}

    public static void tick(ClientLevel level) {
        if (!Config.distantLightning || !level.isThundering()) return;
        if (RANDOM.nextFloat() >= CHANCE_PER_TICK) return;

        double max = Config.lightningRange * 1000.0;
        // uniform over the ring area: far strikes are more common, as in reality
        double d = Math.sqrt(Mth.lerp(RANDOM.nextDouble(), MIN_DISTANCE * MIN_DISTANCE, max * max));
        double a = RANDOM.nextDouble() * Math.PI * 2.0;
        Vec3 cam = Minecraft.getInstance().gameRenderer.getMainCamera().getPosition();

        DistantLightningBolt bolt = new DistantLightningBolt(level, d);
        bolt.setId(nextId--);
        bolt.moveTo(cam.x + Math.sin(a) * d, level.getSeaLevel(), cam.z + Math.cos(a) * d);
        level.addEntity(bolt);
    }
}
