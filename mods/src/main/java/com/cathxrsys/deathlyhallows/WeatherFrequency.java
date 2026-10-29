package com.cathxrsys.deathlyhallows;

import net.minecraft.network.chat.Component;

/** How often a kind of weather happens. DEFAULT leaves the vanilla weather untouched. */
public enum WeatherFrequency {
    NEVER("Never"),
    RARE("Rare"),
    DEFAULT("Default"),
    OFTEN("Often"),
    ALWAYS("Always");

    private final String label;

    WeatherFrequency(String label) {
        this.label = label;
    }

    public Component label() {
        return Component.literal(label);
    }

    public static WeatherFrequency parse(String name) {
        if (name != null) {
            for (WeatherFrequency f : values()) {
                if (f.name().equalsIgnoreCase(name.trim())) return f;
            }
        }
        return DEFAULT;
    }
}
