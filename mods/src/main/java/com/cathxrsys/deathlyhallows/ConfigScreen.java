package com.cathxrsys.deathlyhallows;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.AbstractSliderButton;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.CycleButton;
import net.minecraft.client.gui.components.Tooltip;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.CommonComponents;
import net.minecraft.network.chat.Component;

import java.util.function.IntConsumer;

public class ConfigScreen extends Screen {
    private final Screen parent;
    private StepSlider speedSlider;
    private StepSlider rangeSlider;
    private StepSlider shieldSlider;
    private CycleButton<WeatherFrequency> thunderButton;

    public ConfigScreen(Screen parent) {
        super(Component.literal("Deathly Hallows"));
        this.parent = parent;
    }

    @Override
    protected void init() {
        // two columns: sound and lightning on the left, weather and shield on the right
        int w = Math.min(200, (width - 30) / 2);
        int x = width / 2 - w - 5;
        int rx = width / 2 + 5;
        int y = Math.max(34, height / 6);

        addRenderableWidget(CycleButton.onOffBuilder(Config.realisticThunder)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "Thunder is heard only when its sound reaches you, like in real life.")))
                .create(x, y, w, 20, Component.literal("Realistic Thunder"), (b, v) -> {
                    Config.realisticThunder = v;
                    speedSlider.active = v;
                }));

        speedSlider = addRenderableWidget(new StepSlider(x, y + 24, w, "Speed of Sound", "m/s",
                Config.SOUND_SPEEDS, Config.soundSpeed, 1, v -> Config.soundSpeed = v,
                "How fast thunder sound travels. Real air: ~340 m/s."));
        speedSlider.active = Config.realisticThunder;

        addRenderableWidget(CycleButton.onOffBuilder(Config.distantLightning)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "Simulated strikes kilometers away during thunderstorms: a dim flash on the horizon and quiet rumble.")))
                .create(x, y + 56, w, 20, Component.literal("Distant Lightning"), (b, v) -> {
                    Config.distantLightning = v;
                    rangeSlider.active = v;
                }));

        rangeSlider = addRenderableWidget(new StepSlider(x, y + 80, w, "Max Distance", "km",
                Config.LIGHTNING_RANGES, Config.lightningRange, 3, v -> Config.lightningRange = v,
                "How far away simulated strikes can happen."));
        rangeSlider.active = Config.distantLightning;

        addRenderableWidget(CycleButton.builder(WeatherFrequency::label)
                .withValues(WeatherFrequency.values())
                .withInitialValue(Config.rainFrequency)
                .withTooltip(v -> Tooltip.create(Component.literal(rainTooltip(v))))
                .create(rx, y, w, 20, Component.literal("Rain"), (b, v) -> {
                    Config.rainFrequency = v;
                    thunderButton.active = v != WeatherFrequency.NEVER;
                }));

        thunderButton = addRenderableWidget(CycleButton.builder(WeatherFrequency::label)
                .withValues(WeatherFrequency.values())
                .withInitialValue(Config.thunderFrequency)
                .withTooltip(v -> Tooltip.create(Component.literal(thunderTooltip(v))))
                .create(rx, y + 24, w, 20, Component.literal("Thunderstorms"), (b, v) -> Config.thunderFrequency = v));
        thunderButton.active = Config.rainFrequency != WeatherFrequency.NEVER;

        addRenderableWidget(CycleButton.onOffBuilder(Config.smallShield)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "Draws a shield in the left hand smaller while you are not blocking, so it does not cover the screen.")))
                .create(rx, y + 56, w, 20, Component.literal("Smaller Shield"), (b, v) -> {
                    Config.smallShield = v;
                    shieldSlider.active = v;
                }));

        shieldSlider = addRenderableWidget(new StepSlider(rx, y + 80, w, "Shield Size", "%",
                Config.SHIELD_SCALES, Config.shieldScale, 3, v -> Config.shieldScale = v,
                "Size of the idle shield in percent of the normal one."));
        shieldSlider.active = Config.smallShield;

        addRenderableWidget(Button.builder(CommonComponents.GUI_DONE, b -> onClose())
                .bounds(width / 2 - 100, height - 28, 200, 20)
                .build());
    }

    @Override
    public void render(GuiGraphics g, int mouseX, int mouseY, float delta) {
        super.render(g, mouseX, mouseY, delta);
        g.drawCenteredString(font, title, width / 2, 15, 0xFFFFFF);
    }

    @Override
    public void onClose() {
        Config.save();
        minecraft.setScreen(parent);
    }

    private static String rainTooltip(WeatherFrequency f) {
        return switch (f) {
            case NEVER -> "It never rains, whatever the world or server says.";
            case RARE -> "Showers are rarer than in vanilla.";
            case DEFAULT -> "Vanilla weather.";
            case OFTEN -> "It rains more than half of the time.";
            case ALWAYS -> "It rains all the time.";
        };
    }

    private static String thunderTooltip(WeatherFrequency f) {
        return switch (f) {
            case NEVER -> "No thunderstorms and no lightning. Rain is unaffected.";
            case RARE -> "Thunderstorms are rarer than in vanilla.";
            case DEFAULT -> "Vanilla thunderstorms.";
            case OFTEN -> "Frequent thunderstorms. They bring rain with them.";
            case ALWAYS -> "A thunderstorm all the time. It brings rain with it.";
        };
    }

    // discrete slider over a fixed list of values
    private static class StepSlider extends AbstractSliderButton {
        private final String label;
        private final String unit;
        private final int[] values;
        private final IntConsumer setter;

        StepSlider(int x, int y, int width, String label, String unit, int[] values, int current, int fallback,
                   IntConsumer setter, String tooltip) {
            super(x, y, width, 20, Component.empty(),
                    (double) Config.indexOf(values, current, fallback) / (values.length - 1));
            this.label = label;
            this.unit = unit;
            this.values = values;
            this.setter = setter;
            setTooltip(Tooltip.create(Component.literal(tooltip)));
            updateMessage();
        }

        private int current() {
            return values[(int) Math.round(value * (values.length - 1))];
        }

        @Override
        protected void updateMessage() {
            if (values == null) return; // fields are not set yet
            setMessage(Component.literal(label + ": " + current() + " " + unit));
        }

        @Override
        protected void applyValue() {
            value = Math.round(value * (values.length - 1)) / (double) (values.length - 1);
            setter.accept(current());
        }
    }
}
