#ifdef ORE_LIGHT
// Colored ore light spreads over a 32^3 block grid around the camera, like vanilla light:
// one block per frame (prepare_a.csh), full cubes block it.
// Cells are tied to world coordinates (block & 31), so the grid never needs to be shifted when the camera moves.
// occ  - frame stamp for full cubes (terrain vertex shader),
// emit - frame stamp << 4 | ore type for the air in front of an exposed ore face (terrain vertex shader),
// lightA/lightB - light, ping-pong: an even frame writes A and reads B, an odd one the opposite.
//   rgb - color including strength, w - strength (1 at an ore face, -1 = full cube).
layout(std430, binding = 2) buffer OreBuf {
    uint occ[32768];
    uint emit[32768];
    vec4 lightA[32768];
    vec4 lightB[32768];
} oreBuf;

// Light color per ore type (see oreType)
const vec3 ORE_COLORS[9] = vec3[9](
    vec3(0.95, 0.65, 0.45), // iron
    vec3(1.00, 0.50, 0.25), // copper
    vec3(1.00, 0.80, 0.20), // gold
    vec3(1.00, 0.08, 0.05), // redstone
    vec3(0.15, 0.30, 1.00), // lapis
    vec3(0.25, 0.95, 1.00), // diamond
    vec3(0.15, 1.00, 0.30), // emerald
    vec3(1.00, 0.75, 0.20), // nether gold, gilded blackstone
    vec3(1.00, 0.92, 0.85)  // quartz
);

// Ore type (index into ORE_COLORS), -1 = no light (coal and others)
int oreType(int id) {
    if (id >= 10040 && id <= 10046) return id - 10040;
    if (id == 10012) return 7;
    if (id == 10013) return 8;
    return -1;
}

// Ore light visibility by distance from the camera: full strength up to 0.4 * ORE_LIGHT_DIST, then fades
// smoothly to ORE_LIGHT_DIST. Quintic curve: no kink at either end, the light appears unnoticed.
float oreLightFade(float dist) {
    float D = float(ORE_LIGHT_DIST);
    float x = clamp((dist - 0.4 * D) / (0.6 * D), 0.0, 1.0);
    return 1.0 - x * x * x * (x * (x * 6.0 - 15.0) + 10.0);
}

// Blocks farther than ORE_LIGHT_DIST + ORE_LIGHT_RADIUS from the camera (per axis) do not affect visible light:
// terrain does not mark them and propagation does not process them
bool oreInReach(ivec3 block, vec3 camPos) {
    ivec3 d = abs(block - ivec3(floor(camPos)));
    return max(d.x, max(d.y, d.z)) <= ORE_LIGHT_DIST + ORE_LIGHT_RADIUS + 1;
}

// Grid corner: the grid covers blocks base .. base + 31 on every axis
ivec3 oreBase(vec3 camPos) {
    return ivec3(floor(camPos)) - 16;
}

bool oreInGrid(ivec3 block, ivec3 base) {
    return all(greaterThanEqual(block, base)) && all(lessThan(block, base + 32));
}

uint oreCell(ivec3 block) {
    ivec3 b = block & 31;
    return uint(b.x | (b.y << 5) | (b.z << 10));
}

// The stamp was written in the previous or the one before (cur = the reader's frameCounter)
bool oreStampValid(uint s, uint cur) {
    return s == cur || s + 1u == cur;
}
#endif
