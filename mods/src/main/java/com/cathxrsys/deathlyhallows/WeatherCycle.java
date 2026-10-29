package com.cathxrsys.deathlyhallows;

import net.minecraft.util.RandomSource;

/**
 * Alternating dry/wet periods for rain and thunder, driven by the selected frequencies.
 * Pure state machine: the integrated server writes it into the level data, the client turns it into fake weather levels.
 */
public final class WeatherCycle {
    // durations in ticks: {min wet, max wet, min dry, max dry}
    private static final int[] RAIN_RARE = {6000, 12000, 36000, 120000};
    private static final int[] RAIN_DEFAULT = {12000, 24000, 12000, 180000}; // same as vanilla
    private static final int[] RAIN_OFTEN = {9000, 24000, 6000, 18000};
    private static final int[] THUNDER_RARE = {2400, 6000, 48000, 180000};
    private static final int[] THUNDER_DEFAULT = {3600, 15600, 12000, 180000}; // same as vanilla
    private static final int[] THUNDER_OFTEN = {6000, 15600, 6000, 24000};

    private final Channel rain = new Channel();
    private final Channel thunder = new Channel();

    /** The thunder mode that actually applies: a thunderstorm cannot exist without rain. */
    public static WeatherFrequency effectiveThunder(WeatherFrequency rain, WeatherFrequency thunder) {
        return rain == WeatherFrequency.NEVER ? WeatherFrequency.NEVER : thunder;
    }

    /** Frequent thunderstorms bring their own rain. */
    public static boolean bringsRain(WeatherFrequency thunder) {
        return thunder == WeatherFrequency.OFTEN || thunder == WeatherFrequency.ALWAYS;
    }

    public void tick(WeatherFrequency rainMode, WeatherFrequency thunderMode, RandomSource random) {
        rain.tick(rainMode, rainTable(rainMode), random);
        WeatherFrequency t = effectiveThunder(rainMode, thunderMode);
        thunder.tick(t, thunderTable(t), random);
    }

    /** Adopts a state set from outside (a command); a channel without a real timer (<= 1 tick) starts over instead. */
    public void adopt(boolean rainOn, int rainLeft, boolean thunderOn, int thunderLeft) {
        rain.adopt(rainOn, rainLeft);
        thunder.adopt(thunderOn, thunderLeft);
    }

    /** The cycle's own rain, not counting rain brought by a thunderstorm. */
    public boolean rain() {
        return rain.on;
    }

    public boolean thunder() {
        return thunder.on;
    }

    private static int[] rainTable(WeatherFrequency f) {
        return f == WeatherFrequency.RARE ? RAIN_RARE : f == WeatherFrequency.OFTEN ? RAIN_OFTEN : RAIN_DEFAULT;
    }

    private static int[] thunderTable(WeatherFrequency f) {
        return f == WeatherFrequency.RARE ? THUNDER_RARE : f == WeatherFrequency.OFTEN ? THUNDER_OFTEN : THUNDER_DEFAULT;
    }

    private static final class Channel {
        boolean on;
        int left; // ticks until the state flips
        WeatherFrequency mode;

        void adopt(boolean wet, int ticks) {
            if (ticks > 1) {
                on = wet;
                left = ticks;
            } else {
                mode = null; // rolled again on the next tick
            }
        }

        void tick(WeatherFrequency m, int[] table, RandomSource random) {
            if (m != mode) {
                mode = m;
                roll(table, random, true);
                return;
            }
            if (--left > 0) return;
            roll(table, random, false);
        }

        private void roll(int[] table, RandomSource random, boolean midPhase) {
            if (mode == WeatherFrequency.NEVER || mode == WeatherFrequency.ALWAYS) {
                on = mode == WeatherFrequency.ALWAYS;
                left = Integer.MAX_VALUE;
                return;
            }
            if (midPhase) {
                // joining a cycle at a random moment: wet with the probability of the average wet share
                float wet = (table[0] + table[1]) * 0.5f;
                float dry = (table[2] + table[3]) * 0.5f;
                on = random.nextFloat() < wet / (wet + dry);
            } else {
                on = !on;
            }
            int duration = on ? between(random, table[0], table[1]) : between(random, table[2], table[3]);
            left = midPhase ? Math.max(1, (int) (duration * random.nextFloat())) : duration;
        }

        private static int between(RandomSource random, int min, int max) {
            return min + random.nextInt(max - min + 1);
        }
    }
}
