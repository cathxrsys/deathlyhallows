#include "/lib/settings.glsl"

// One step of ore light propagation over the 32^3 grid (see lib/ore_buf.glsl)
#ifdef ORE_LIGHT
layout(local_size_x = 8, local_size_y = 8, local_size_z = 8) in;
const ivec3 workGroups = ivec3(4, 4, 4);
#else
// Iris always runs the compute pass (program.*.enabled has no effect on compute),
// so without ORE_LIGHT it is shrunk to a single empty thread
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);
#endif

#include "/lib/ore_buf.glsl"

uniform vec3 cameraPosition;
uniform int frameCounter;
uniform float frameTime;

// speed of the smooth fade in / out of light in a cell, 1/s: ~1 s to full strength
const float ORE_LIGHT_FADE_SPEED = 4.0;

#ifdef ORE_LIGHT
vec4 orePrev(uint i, bool even) {
    return even ? oreBuf.lightB[i] : oreBuf.lightA[i];
}
#endif

void main() {
#ifdef ORE_LIGHT
    ivec3 base = oreBase(cameraPosition);
    ivec3 block = base + ivec3(gl_GlobalInvocationID);
    uint i = oreCell(block);
    bool even = (frameCounter & 1) == 0;
    if (!oreInReach(block, cameraPosition)) {
        if (even) oreBuf.lightA[i] = vec4(0.0);
        else      oreBuf.lightB[i] = vec4(0.0);
        return;
    }
    // occ/emit were written by the previous frame's terrain with its frameCounter + 1, i.e. the current frameCounter
    uint cur = uint(frameCounter);
    float stepDown = 1.0 / float(ORE_LIGHT_RADIUS);

    vec4 res = vec4(0.0);
    uint e = oreBuf.emit[i];
    if (oreStampValid(oreBuf.occ[i], cur)) {
        res = vec4(0.0, 0.0, 0.0, -1.0);
    } else if (oreStampValid(e >> 4, cur)) {
        res = vec4(ORE_COLORS[e & 15u], 1.0);
    } else {
        // neighbour light is one block weaker; colors of different ores are mixed by per-channel maximum
        const ivec3 dirs[6] = ivec3[6](ivec3(1, 0, 0), ivec3(-1, 0, 0), ivec3(0, 1, 0),
                                       ivec3(0, -1, 0), ivec3(0, 0, 1), ivec3(0, 0, -1));
        for (int k = 0; k < 6; k++) {
            ivec3 nb = block + dirs[k];
            if (!oreInGrid(nb, base)) continue;
            vec4 l = orePrev(oreCell(nb), even);
            if (l.w <= stepDown) continue;
            float w = l.w - stepDown;
            res.rgb = max(res.rgb, l.rgb * (w / l.w));
            res.w = max(res.w, w);
        }
    }

    // light in a cell eases towards the new value: an ore entering the grid or mined
    // lights up and fades out over ~a second instead of popping. Walls (w < 0) change instantly.
    // The outer grid layers switch to other blocks as the camera moves (cell = block & 31),
    // so the previous value there belongs to another block and is replaced immediately.
    ivec3 g = ivec3(gl_GlobalInvocationID);
    bool border = any(lessThan(g, ivec3(3))) || any(greaterThan(g, ivec3(28)));
    vec4 prev = orePrev(i, even);
    if (!border && res.w >= 0.0 && prev.w >= 0.0) {
        res = mix(prev, res, 1.0 - exp(-frameTime * ORE_LIGHT_FADE_SPEED));
        if (res.w < 0.01) res = vec4(0.0);
    }

    if (even) oreBuf.lightA[i] = res;
    else      oreBuf.lightB[i] = res;
#endif
}
