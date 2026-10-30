package com.cathxrsys.deathlyhallows;

import com.mojang.blaze3d.vertex.PoseStack;
import com.mojang.blaze3d.vertex.VertexConsumer;
import net.minecraft.client.Camera;
import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.player.LocalPlayer;
import net.minecraft.client.renderer.MultiBufferSource;
import net.minecraft.client.renderer.RenderType;
import net.minecraft.core.BlockPos;
import net.minecraft.world.level.block.CropBlock;
import net.minecraft.world.level.block.state.BlockState;
import net.minecraft.world.phys.Vec3;
import org.joml.Matrix4f;

import java.util.ArrayList;
import java.util.List;

/** Green check mark over fully grown crops near the player. */
public final class CropMarkers {
    private static final int RADIUS = 16;
    private static final int HEIGHT = 4;
    private static final int SCAN_INTERVAL = 10;
    private static final int FULL_BRIGHT = 0xF000F0;
    private static final int GREEN = 0x3CD83C;

    // the check mark as a polyline, in blocks around the center of the mark
    private static final float[][] LINE = {{-0.30f, 0.02f}, {-0.10f, -0.20f}, {0.32f, 0.26f}};
    private static final float HALF_WIDTH = 0.065f;

    private static final List<BlockPos> CROPS = new ArrayList<>();
    private static ClientLevel level;

    private CropMarkers() {}

    private static boolean grown(BlockState state) {
        return state.getBlock() instanceof CropBlock crop && crop.isMaxAge(state);
    }

    /** Looks for grown crops around the player a few times a second. */
    public static void tick(ClientLevel world) {
        if (world != level) {
            CROPS.clear();
            level = world;
        }
        LocalPlayer player = Minecraft.getInstance().player;
        if (!Config.cropMarkers || player == null || world.getGameTime() % SCAN_INTERVAL != 0) {
            if (!Config.cropMarkers) CROPS.clear();
            return;
        }
        CROPS.clear();
        BlockPos center = player.blockPosition();
        BlockPos.MutableBlockPos pos = new BlockPos.MutableBlockPos();
        for (int dx = -RADIUS; dx <= RADIUS; dx++) {
            for (int dz = -RADIUS; dz <= RADIUS; dz++) {
                if (dx * dx + dz * dz > RADIUS * RADIUS) continue;
                for (int dy = -HEIGHT; dy <= HEIGHT; dy++) {
                    pos.set(center.getX() + dx, center.getY() + dy, center.getZ() + dz);
                    if (grown(world.getBlockState(pos))) CROPS.add(pos.immutable());
                }
            }
        }
    }

    public static void render(Camera camera) {
        Minecraft mc = Minecraft.getInstance();
        if (!Config.cropMarkers || CROPS.isEmpty() || mc.level == null || mc.options.hideGui) return;

        Vec3 cam = camera.getPosition();
        float size = Config.cropMarkerSize / 100.0f;
        int alpha = Math.round(255 * Config.cropMarkerOpacity / 100.0f);
        int color = (alpha << 24) | GREEN;
        MultiBufferSource.BufferSource buffers = mc.renderBuffers().bufferSource();
        VertexConsumer vc = buffers.getBuffer(RenderType.textBackground());
        PoseStack pose = new PoseStack();

        for (BlockPos pos : CROPS) {
            // checked again every frame, so a broken crop loses its mark at once
            if (!grown(mc.level.getBlockState(pos))) continue;
            pose.pushPose();
            pose.translate(pos.getX() + 0.5 - cam.x, pos.getY() + 1.0 + 0.45 * size - cam.y, pos.getZ() + 0.5 - cam.z);
            pose.mulPose(camera.rotation());
            pose.scale(size, size, size);
            check(vc, pose.last().pose(), color);
            pose.popPose();
        }
    }

    // two strokes that meet at a mitered joint, so they share an edge and never overlap
    private static void check(VertexConsumer vc, Matrix4f m, int color) {
        float[] p0 = LINE[0], p1 = LINE[1], p2 = LINE[2];
        float[] n1 = normal(p0, p1), n2 = normal(p1, p2);
        float mx = n1[0] + n2[0];
        float my = n1[1] + n2[1];
        float len = (float) Math.sqrt(mx * mx + my * my);
        mx /= len;
        my /= len;
        float miter = HALF_WIDTH / (mx * n1[0] + my * n1[1]);
        float h = HALF_WIDTH;

        quad(vc, m, color,
                p0[0] - n1[0] * h, p0[1] - n1[1] * h,
                p1[0] - mx * miter, p1[1] - my * miter,
                p1[0] + mx * miter, p1[1] + my * miter,
                p0[0] + n1[0] * h, p0[1] + n1[1] * h);
        quad(vc, m, color,
                p1[0] - mx * miter, p1[1] - my * miter,
                p2[0] - n2[0] * h, p2[1] - n2[1] * h,
                p2[0] + n2[0] * h, p2[1] + n2[1] * h,
                p1[0] + mx * miter, p1[1] + my * miter);
    }

    private static float[] normal(float[] a, float[] b) {
        float dx = b[0] - a[0];
        float dy = b[1] - a[1];
        float len = (float) Math.sqrt(dx * dx + dy * dy);
        return new float[]{-dy / len, dx / len};
    }

    private static void quad(VertexConsumer vc, Matrix4f m, int color, float x0, float y0, float x1, float y1,
                             float x2, float y2, float x3, float y3) {
        vc.addVertex(m, x0, y0, 0.0f).setColor(color).setLight(FULL_BRIGHT);
        vc.addVertex(m, x1, y1, 0.0f).setColor(color).setLight(FULL_BRIGHT);
        vc.addVertex(m, x2, y2, 0.0f).setColor(color).setLight(FULL_BRIGHT);
        vc.addVertex(m, x3, y3, 0.0f).setColor(color).setLight(FULL_BRIGHT);
    }
}
