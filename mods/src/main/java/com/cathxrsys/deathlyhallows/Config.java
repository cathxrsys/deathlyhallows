package com.cathxrsys.deathlyhallows;

import net.fabricmc.loader.api.FabricLoader;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

public final class Config {
    // selectable speeds of sound, m/s (1 block = 1 m)
    public static final int[] SOUND_SPEEDS = {150, 300, 600, 1200, 2400};
    // selectable max distances of simulated strikes, km
    public static final int[] LIGHTNING_RANGES = {2, 5, 10, 20};

    public static boolean realisticThunder = true;
    public static int soundSpeed = 300;
    public static boolean distantLightning = true;
    public static int lightningRange = 20;

    private static final Path FILE = FabricLoader.getInstance().getConfigDir().resolve("deathlyhallows.properties");

    private Config() {}

    public static int indexOf(int[] values, int value, int fallback) {
        for (int i = 0; i < values.length; i++) {
            if (values[i] == value) return i;
        }
        return fallback;
    }

    public static void load() {
        if (!Files.exists(FILE)) return;
        Properties p = new Properties();
        try (Reader r = Files.newBufferedReader(FILE)) {
            p.load(r);
        } catch (IOException e) {
            return;
        }
        realisticThunder = Boolean.parseBoolean(p.getProperty("realisticThunder", "true"));
        soundSpeed = SOUND_SPEEDS[indexOf(SOUND_SPEEDS, parseInt(p.getProperty("soundSpeed")), 1)];
        distantLightning = Boolean.parseBoolean(p.getProperty("distantLightning", "true"));
        lightningRange = LIGHTNING_RANGES[indexOf(LIGHTNING_RANGES, parseInt(p.getProperty("lightningRange")), 3)];
    }

    public static void save() {
        Properties p = new Properties();
        p.setProperty("realisticThunder", Boolean.toString(realisticThunder));
        p.setProperty("soundSpeed", Integer.toString(soundSpeed));
        p.setProperty("distantLightning", Boolean.toString(distantLightning));
        p.setProperty("lightningRange", Integer.toString(lightningRange));
        try {
            Files.createDirectories(FILE.getParent());
            try (Writer w = Files.newBufferedWriter(FILE)) {
                p.store(w, "Deathly Hallows");
            }
        } catch (IOException ignored) {
        }
    }

    private static int parseInt(String s) {
        try {
            return Integer.parseInt(s);
        } catch (NumberFormatException e) {
            return -1;
        }
    }
}
