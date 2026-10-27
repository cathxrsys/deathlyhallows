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

    public ConfigScreen(Screen parent) {
        super(Component.literal("Deathly Hallows"));
        this.parent = parent;
    }

    @Override
    protected void init() {
        int x = width / 2 - 100;
        int y = height / 4;

        addRenderableWidget(CycleButton.onOffBuilder(Config.realisticThunder)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "Thunder is heard only when its sound reaches you, like in real life.")))
                .create(x, y, 200, 20, Component.literal("Realistic Thunder"), (b, v) -> {
                    Config.realisticThunder = v;
                    speedSlider.active = v;
                }));

        speedSlider = addRenderableWidget(new StepSlider(x, y + 24, "Speed of Sound", "m/s",
                Config.SOUND_SPEEDS, Config.soundSpeed, 1, v -> Config.soundSpeed = v,
                "How fast thunder sound travels. Real air: ~340 m/s."));
        speedSlider.active = Config.realisticThunder;

        addRenderableWidget(CycleButton.onOffBuilder(Config.distantLightning)
                .withTooltip(v -> Tooltip.create(Component.literal(
                        "Simulated strikes kilometers away during thunderstorms: a dim flash on the horizon and quiet rumble.")))
                .create(x, y + 56, 200, 20, Component.literal("Distant Lightning"), (b, v) -> {
                    Config.distantLightning = v;
                    rangeSlider.active = v;
                }));

        rangeSlider = addRenderableWidget(new StepSlider(x, y + 80, "Max Distance", "km",
                Config.LIGHTNING_RANGES, Config.lightningRange, 3, v -> Config.lightningRange = v,
                "How far away simulated strikes can happen."));
        rangeSlider.active = Config.distantLightning;

        addRenderableWidget(Button.builder(CommonComponents.GUI_DONE, b -> onClose())
                .bounds(x, height - 28, 200, 20)
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

    // discrete slider over a fixed list of values
    private static class StepSlider extends AbstractSliderButton {
        private final String label;
        private final String unit;
        private final int[] values;
        private final IntConsumer setter;

        StepSlider(int x, int y, String label, String unit, int[] values, int current, int fallback,
                   IntConsumer setter, String tooltip) {
            super(x, y, 200, 20, Component.empty(),
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
