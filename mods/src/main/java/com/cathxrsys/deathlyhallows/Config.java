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
    // selectable sizes of an idle shield in the left hand, percent
    public static final int[] SHIELD_SCALES = {50, 60, 70, 80, 90};
    // selectable distances up to which health bars are shown, blocks
    public static final int[] BAR_RANGES = {8, 16, 24, 32};
    // selectable opacities of health bars, percent
    public static final int[] BAR_OPACITIES = {20, 40, 60, 80, 100};

    public static boolean realisticThunder = true;
    public static int soundSpeed = 300;
    public static boolean distantLightning = true;
    public static int lightningRange = 20;
    public static boolean smallShield = true;
    public static int shieldScale = 80;
    public static boolean campfireCooking = true;
    public static boolean mobHealthBars = false;
    public static int healthBarRange = 24;
    public static int healthBarOpacity = 100;
    public static WeatherFrequency rainFrequency = WeatherFrequency.DEFAULT;
    public static WeatherFrequency thunderFrequency = WeatherFrequency.DEFAULT;

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
        smallShield = Boolean.parseBoolean(p.getProperty("smallShield", "true"));
        shieldScale = SHIELD_SCALES[indexOf(SHIELD_SCALES, parseInt(p.getProperty("shieldScale")), 3)];
        campfireCooking = Boolean.parseBoolean(p.getProperty("campfireCooking", "true"));
        mobHealthBars = Boolean.parseBoolean(p.getProperty("mobHealthBars", "false"));
        healthBarRange = BAR_RANGES[indexOf(BAR_RANGES, parseInt(p.getProperty("healthBarRange")), 2)];
        healthBarOpacity = BAR_OPACITIES[indexOf(BAR_OPACITIES, parseInt(p.getProperty("healthBarOpacity")), 4)];
        rainFrequency = WeatherFrequency.parse(p.getProperty("rainFrequency"));
        thunderFrequency = WeatherFrequency.parse(p.getProperty("thunderFrequency"));
    }

    public static void save() {
        Properties p = new Properties();
        p.setProperty("realisticThunder", Boolean.toString(realisticThunder));
        p.setProperty("soundSpeed", Integer.toString(soundSpeed));
        p.setProperty("distantLightning", Boolean.toString(distantLightning));
        p.setProperty("lightningRange", Integer.toString(lightningRange));
        p.setProperty("smallShield", Boolean.toString(smallShield));
        p.setProperty("shieldScale", Integer.toString(shieldScale));
        p.setProperty("campfireCooking", Boolean.toString(campfireCooking));
        p.setProperty("mobHealthBars", Boolean.toString(mobHealthBars));
        p.setProperty("healthBarRange", Integer.toString(healthBarRange));
        p.setProperty("healthBarOpacity", Integer.toString(healthBarOpacity));
        p.setProperty("rainFrequency", rainFrequency.name());
        p.setProperty("thunderFrequency", thunderFrequency.name());
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
