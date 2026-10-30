package com.cathxrsys.deathlyhallows;

import net.minecraft.client.gui.GuiGraphics;
import net.minecraft.client.gui.components.AbstractSliderButton;
import net.minecraft.client.gui.components.Button;
import net.minecraft.client.gui.components.CycleButton;
import net.minecraft.client.gui.components.Tooltip;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.network.chat.CommonComponents;
import net.minecraft.network.chat.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.function.IntConsumer;

public class ConfigScreen extends Screen {
    private final Screen parent;
    private static final int ROW = 24;
    private static final int HEADER = 13;
    private static final int GROUP_GAP = 8;

    private StepSlider speedSlider;
    private StepSlider rangeSlider;
    private StepSlider shieldSlider;
    private StepSlider barRangeSlider;
    private StepSlider barOpacitySlider;
    private StepSlider cropOpacitySlider;
    private StepSlider cropSizeSlider;
    private CycleButton<WeatherFrequency> thunderButton;

    // group titles drawn above their widgets: x, y, text
    private final List<Object[]> headers = new ArrayList<>();
    private int colWidth;
    private int[] colX;
    private int[] colY;

    public ConfigScreen(Screen parent) {
        super(Component.literal("Deathly Hallows"));
        this.parent = parent;
    }

    // starts a group of widgets in a column
    private void group(int col, String title) {
        headers.add(new Object[]{colX[col], colY[col], title});
        colY[col] += HEADER;
    }

    // next free row of a column
    private int row(int col) {
        int y = colY[col];
        colY[col] += ROW;
        return y;
    }

    private void endGroup(int col) {
        colY[col] += GROUP_GAP - (ROW - 20);
    }

    @Override
    protected void init() {
        headers.clear();
        // three columns of groups
        colWidth = Math.min(200, (width - 32) / 3);
        int left = width / 2 - (3 * colWidth + 12) / 2;
        colX = new int[]{left, left + colWidth + 6, left + 2 * (colWidth + 6)};
        int top = Math.max(32, height / 8);
        colY = new int[]{top, top, top};
        int w = colWidth;

        group(0, "Thunder");
        addRenderableWidget(CycleButton.onOffBuilder(Config.realisticThunder)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "Thunder is heard only when its sound reaches you, like in real life.")))
                .create(colX[0], row(0), w, 20, Component.literal("Realistic Thunder"), (b, v) -> {
                    Config.realisticThunder = v;
                    speedSlider.active = v;
                }));
        speedSlider = addRenderableWidget(new StepSlider(colX[0], row(0), w, "Speed of Sound", "m/s",
                Config.SOUND_SPEEDS, Config.soundSpeed, 1, v -> Config.soundSpeed = v,
                "How fast thunder sound travels. Real air: ~340 m/s."));
        speedSlider.active = Config.realisticThunder;
        addRenderableWidget(CycleButton.onOffBuilder(Config.distantLightning)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "Simulated strikes kilometers away during thunderstorms: a dim flash on the horizon and quiet rumble.")))
                .create(colX[0], row(0), w, 20, Component.literal("Distant Lightning"), (b, v) -> {
                    Config.distantLightning = v;
                    rangeSlider.active = v;
                }));
        rangeSlider = addRenderableWidget(new StepSlider(colX[0], row(0), w, "Max Distance", "km",
                Config.LIGHTNING_RANGES, Config.lightningRange, 3, v -> Config.lightningRange = v,
                "How far away simulated strikes can happen."));
        rangeSlider.active = Config.distantLightning;
        endGroup(0);

        group(0, "Campfire");
        addRenderableWidget(CycleButton.onOffBuilder(Config.campfireCooking)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "Food on a campfire gradually turns from raw into cooked while it cooks.")))
                .create(colX[0], row(0), w, 20, Component.literal("Cooking Progress"), (b, v) -> Config.campfireCooking = v));
        endGroup(0);

        group(1, "Weather");
        addRenderableWidget(CycleButton.builder(WeatherFrequency::label)
                .withValues(WeatherFrequency.values())
                .withInitialValue(Config.rainFrequency)
                .withTooltip(v -> Tooltip.create(Component.literal(rainTooltip(v))))
                .create(colX[1], row(1), w, 20, Component.literal("Rain"), (b, v) -> {
                    Config.rainFrequency = v;
                    thunderButton.active = v != WeatherFrequency.NEVER;
                }));
        thunderButton = addRenderableWidget(CycleButton.builder(WeatherFrequency::label)
                .withValues(WeatherFrequency.values())
                .withInitialValue(Config.thunderFrequency)
                .withTooltip(v -> Tooltip.create(Component.literal(thunderTooltip(v))))
                .create(colX[1], row(1), w, 20, Component.literal("Thunderstorms"), (b, v) -> Config.thunderFrequency = v));
        thunderButton.active = Config.rainFrequency != WeatherFrequency.NEVER;
        endGroup(1);

        group(1, "Crop Markers");
        addRenderableWidget(CycleButton.onOffBuilder(Config.cropMarkers)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "A green check mark over fully grown crops (wheat, carrots, potatoes, beetroots) near you.")))
                .create(colX[1], row(1), w, 20, Component.literal("Crop Markers"), (b, v) -> {
                    Config.cropMarkers = v;
                    cropOpacitySlider.active = v;
                    cropSizeSlider.active = v;
                }));
        cropOpacitySlider = addRenderableWidget(new StepSlider(colX[1], row(1), w, "Opacity", "%",
                Config.OPACITIES, Config.cropMarkerOpacity, 3, v -> Config.cropMarkerOpacity = v,
                "How opaque the check marks are."));
        cropSizeSlider = addRenderableWidget(new StepSlider(colX[1], row(1), w, "Size", "%",
                Config.MARKER_SIZES, Config.cropMarkerSize, 2, v -> Config.cropMarkerSize = v,
                "Size of the check marks in percent of the default."));
        cropOpacitySlider.active = Config.cropMarkers;
        cropSizeSlider.active = Config.cropMarkers;
        endGroup(1);

        group(2, "Shield");
        addRenderableWidget(CycleButton.onOffBuilder(Config.smallShield)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "Draws a shield in the left hand smaller while you are not blocking, so it does not cover the screen.")))
                .create(colX[2], row(2), w, 20, Component.literal("Smaller Shield"), (b, v) -> {
                    Config.smallShield = v;
                    shieldSlider.active = v;
                }));
        shieldSlider = addRenderableWidget(new StepSlider(colX[2], row(2), w, "Size", "%",
                Config.SHIELD_SCALES, Config.shieldScale, 3, v -> Config.shieldScale = v,
                "Size of the idle shield in percent of the normal one."));
        shieldSlider.active = Config.smallShield;
        endGroup(2);

        group(2, "Mob Health Bars");
        addRenderableWidget(CycleButton.onOffBuilder(Config.mobHealthBars)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "A red health bar over a mob that you have hurt, so you can see how much damage you deal.")))
                .create(colX[2], row(2), w, 20, Component.literal("Health Bars"), (b, v) -> {
                    Config.mobHealthBars = v;
                    barRangeSlider.active = v;
                    barOpacitySlider.active = v;
                }));
        barRangeSlider = addRenderableWidget(new StepSlider(colX[2], row(2), w, "Distance", "blocks",
                Config.BAR_RANGES, Config.healthBarRange, 2, v -> Config.healthBarRange = v,
                "How close you must be to a mob to see its health bar."));
        barOpacitySlider = addRenderableWidget(new StepSlider(colX[2], row(2), w, "Opacity", "%",
                Config.OPACITIES, Config.healthBarOpacity, 8, v -> Config.healthBarOpacity = v,
                "How opaque the mob health bars are."));
        barRangeSlider.active = Config.mobHealthBars;
        barOpacitySlider.active = Config.mobHealthBars;
        endGroup(2);

        addRenderableWidget(Button.builder(CommonComponents.GUI_DONE, b -> onClose())
                .bounds(width / 2 - 100, height - 28, 200, 20)
                .build());
    }

    @Override
    public void render(GuiGraphics g, int mouseX, int mouseY, float delta) {
        super.render(g, mouseX, mouseY, delta);
        g.drawCenteredString(font, title, width / 2, 12, 0xFFFFFF);
        for (Object[] h : headers) {
            g.drawString(font, (String) h[2], (int) h[0], (int) h[1] + 1, 0xFFAAAAAA);
        }
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
