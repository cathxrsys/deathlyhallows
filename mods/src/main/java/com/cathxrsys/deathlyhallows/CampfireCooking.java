package com.cathxrsys.deathlyhallows;

import com.mojang.blaze3d.platform.NativeImage;
import com.mojang.blaze3d.vertex.VertexConsumer;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.entity.ItemRenderer;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.client.renderer.texture.DynamicTexture;
import net.minecraft.client.renderer.texture.TextureAtlasSprite;
import net.minecraft.resources.ResourceLocation;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.core.BlockPos;
import net.minecraft.util.Mth;
import net.minecraft.world.item.Item;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.item.crafting.CampfireCookingRecipe;
import net.minecraft.world.item.crafting.RecipeHolder;
import net.minecraft.world.item.crafting.RecipeType;
import net.minecraft.world.item.crafting.SingleRecipeInput;
import net.minecraft.world.level.Level;
import net.minecraft.world.level.block.CampfireBlock;
import net.minecraft.world.level.block.entity.CampfireBlockEntity;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Cooking progress of food on a campfire, followed on the client: the server does not send it, only the items.
 * Counts ticks the same way the server does (+1 while lit, -2 while burnt out), so it can drift a little
 * and starts from zero for food that was already cooking when the campfire came into view.
 */
public final class CampfireCooking {
    private static final long STALE_TICKS = 2400;
    // number of distinct blends between raw and cooked
    private static final int STEPS = 24;

    private static final Map<Long, Slot[]> CAMPFIRES = new HashMap<>();
    private static final Map<Key, ResourceLocation> TEXTURES = new HashMap<>();
    private static final Map<ResourceLocation, NativeImage> IMAGES = new HashMap<>();
    private static Level level;

    private CampfireCooking() {}

    /** The cooked result and how far the food is to it, 0..1. */
    public record Progress(ItemStack result, float fraction) {}

    private static final class Slot {
        Item item;
        ItemStack result;
        int total;
        float progress;
        float last;
        boolean lit;
        float seen;
    }

    /** Forgets the slots that are empty now, so food put in later starts from zero. */
    public static void sync(CampfireBlockEntity campfire) {
        Slot[] slots = CAMPFIRES.get(campfire.getBlockPos().asLong());
        if (slots == null) return;
        for (int i = 0; i < 4; i++) {
            if (campfire.getItems().get(i).isEmpty()) slots[i] = null;
        }
    }

    /** Progress of the food in a campfire slot, or null if it is not cooking food. */
    public static Progress get(CampfireBlockEntity campfire, int index, ItemStack stack, float partialTick) {
        Level world = campfire.getLevel();
        if (world == null || index < 0 || index > 3) return null;
        if (world != level) {
            CAMPFIRES.clear();
            TEXTURES.values().forEach(Minecraft.getInstance().getTextureManager()::release);
            TEXTURES.clear();
            IMAGES.values().forEach(i -> {
                if (i != null) i.close();
            });
            IMAGES.clear();
            level = world;
        }

        float now = world.getGameTime() + partialTick;
        boolean lit = campfire.getBlockState().getValue(CampfireBlock.LIT);
        BlockPos pos = campfire.getBlockPos();
        Slot[] slots = CAMPFIRES.computeIfAbsent(pos.asLong(), k -> new Slot[4]);
        Slot s = slots[index];
        if (s == null) s = slots[index] = new Slot();

        if (s.item != stack.getItem()) {
            s.item = stack.getItem();
            s.progress = 0;
            s.last = now;
            s.lit = lit;
            Optional<RecipeHolder<CampfireCookingRecipe>> recipe = world.getRecipeManager()
                    .getRecipeFor(RecipeType.CAMPFIRE_COOKING, new SingleRecipeInput(stack), world);
            s.result = recipe.map(r -> r.value().getResultItem(world.registryAccess())).orElse(null);
            s.total = recipe.map(r -> r.value().getCookingTime()).orElse(0);
        } else if (now > s.last) {
            if (s.lit == lit) s.progress = Mth.clamp(s.progress + (lit ? 1 : -2) * (now - s.last), 0, s.total);
            s.last = now;
            s.lit = lit;
        }
        s.seen = now;

        if (CAMPFIRES.size() > 64) prune(now);
        if (s.result == null || s.result.isEmpty() || s.total <= 0) return null;
        return new Progress(s.result, s.progress / s.total);
    }

    private static void prune(float now) {
        CAMPFIRES.values().removeIf(slots -> {
            for (Slot s : slots) {
                if (s != null && now - s.seen < STALE_TICKS) return false;
            }
            return true;
        });
    }

    /**
     * Buffers that draw the raw item with a texture blended between the raw and the cooked sprite, or null if
     * that is not possible. It is one item with one texture, so there is nothing to fight over depth.
     */
    public static MultiBufferSource blended(ItemRenderer renderer, ItemStack raw, ItemStack cooked, Level world,
                                            float fraction, MultiBufferSource source) {
        int step = Mth.clamp(Math.round(fraction * STEPS), 1, STEPS - 1);
        TextureAtlasSprite from = renderer.getModel(raw, world, null, 0).getParticleIcon();
        TextureAtlasSprite to = renderer.getModel(cooked, world, null, 0).getParticleIcon();
        Key key = new Key(from.contents().name(), to.contents().name(), step);
        ResourceLocation texture = TEXTURES.get(key);
        if (texture == null) {
            NativeImage a = image(from);
            NativeImage b = image(to);
            if (a == null || b == null) return null;
            texture = Minecraft.getInstance().getTextureManager()
                    .register("campfire_" + TEXTURES.size(), new DynamicTexture(mix(a, b, step / (float) STEPS)));
            TEXTURES.put(key, texture);
        }
        RenderType type = RenderType.entityTranslucentCull(texture);
        return t -> new Remapped(source.getBuffer(type), from);
    }

    private record Key(ResourceLocation from, ResourceLocation to, int step) {}

    private static NativeImage image(TextureAtlasSprite sprite) {
        ResourceLocation name = sprite.contents().name();
        if (IMAGES.containsKey(name)) return IMAGES.get(name);
        NativeImage image = null;
        try (InputStream in = Minecraft.getInstance().getResourceManager()
                .open(name.withPrefix("textures/").withSuffix(".png"))) {
            image = NativeImage.read(in);
        } catch (IOException ignored) {
        }
        IMAGES.put(name, image);
        return image;
    }

    private static NativeImage mix(NativeImage a, NativeImage b, float t) {
        int w = a.getWidth();
        int h = a.getHeight();
        NativeImage out = new NativeImage(w, h, false);
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                int p = a.getPixelRGBA(x, y);
                int q = b.getPixelRGBA(x * b.getWidth() / w, y * b.getHeight() / h);
                float pa = (p >>> 24) / 255.0f * (1.0f - t);
                float qa = (q >>> 24) / 255.0f * t;
                float alpha = pa + qa;
                int result = 0;
                if (alpha > 0.0f) {
                    // colors are weighted by opacity, so transparent pixels do not darken the edges
                    for (int shift = 0; shift < 24; shift += 8) {
                        float c = (((p >> shift) & 0xFF) * pa + ((q >> shift) & 0xFF) * qa) / alpha;
                        result |= Math.round(c) << shift;
                    }
                    result |= Math.round(alpha * 255.0f) << 24;
                }
                out.setPixelRGBA(x, y, result);
            }
        }
        return out;
    }

    /** Forwards the vertices of an atlas sprite with the texture coordinates remapped to a whole texture. */
    private static final class Remapped implements VertexConsumer {
        private final VertexConsumer out;
        private final TextureAtlasSprite sprite;

        Remapped(VertexConsumer out, TextureAtlasSprite sprite) {
            this.out = out;
            this.sprite = sprite;
        }

        @Override
        public VertexConsumer addVertex(float x, float y, float z) {
            out.addVertex(x, y, z);
            return this;
        }

        @Override
        public VertexConsumer setColor(int r, int g, int b, int a) {
            out.setColor(r, g, b, a);
            return this;
        }

        @Override
        public VertexConsumer setUv(float u, float v) {
            out.setUv((u - sprite.getU0()) / (sprite.getU1() - sprite.getU0()),
                    (v - sprite.getV0()) / (sprite.getV1() - sprite.getV0()));
            return this;
        }

        @Override
        public VertexConsumer setUv1(int u, int v) {
            out.setUv1(u, v);
            return this;
        }

        @Override
        public VertexConsumer setUv2(int u, int v) {
            out.setUv2(u, v);
            return this;
        }

        @Override
        public VertexConsumer setNormal(float x, float y, float z) {
            out.setNormal(x, y, z);
            return this;
        }
    }
}
