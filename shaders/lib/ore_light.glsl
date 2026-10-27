#include "/lib/ore_buf.glsl"

uniform vec3 cameraPosition;
uniform int frameCounter;

// In the Nether the ambient is brighter and ore light drowns in it, so it is stronger there (like the portal)
#ifdef NETHER
const float ORE_DIM_BOOST = 2.2;
#else
const float ORE_DIM_BOOST = 1.0;
#endif

// Colored ore light at a point (as a share of albedo): trilinear sampling of the grid filled by prepare_a.csh.
// Full-cube cells are excluded from the sampling, so light is not picked up through walls.
// Terrain surfaces pass a point half a block in front of the face (in the air), entities and the hand pass their own position.
vec3 oreLightAt(vec3 p) {
#ifdef ORE_LIGHT
    // no light beyond ORE_LIGHT_DIST, do not read the grid
    float fade = oreLightFade(length(p - cameraPosition));
    if (fade <= 0.0) return vec3(0.0);

    ivec3 base = oreBase(cameraPosition);
    bool even = (frameCounter & 1) == 0; // prepare_a wrote A on an even frame
    vec3 q = p - 0.5;
    ivec3 c0 = ivec3(floor(q));
    vec3 f = q - vec3(c0);

    vec3 sum = vec3(0.0);
    float wsum = 0.0;
    for (int k = 0; k < 8; k++) {
        ivec3 o = ivec3(k & 1, (k >> 1) & 1, k >> 2);
        vec3 t = mix(1.0 - f, f, vec3(o));
        float wt = t.x * t.y * t.z;
        if (wt < 1e-4) continue;
        ivec3 c = c0 + o;
        if (!oreInGrid(c, base)) continue;
        uint i = oreCell(c);
        vec4 l = even ? oreBuf.lightA[i] : oreBuf.lightB[i];
        if (l.w < 0.0) continue; // full cube
        sum += l.rgb * l.w * wt; // quadratic falloff: rgb is already multiplied by strength
        wsum += wt;
    }
    if (wsum <= 0.0) return vec3(0.0);

    // light fades smoothly at the grid edge
    ivec3 dc = abs(ivec3(floor(p)) - (base + 16));
    float edge = 1.0 - smoothstep(12.0, 16.0, float(max(dc.x, max(dc.y, dc.z))));
    return sum / wsum * edge * fade * ORE_LIGHT_STRENGTH * ORE_DIM_BOOST;
#else
    return vec3(0.0);
#endif
}

vec3 oreLight(vec3 worldPos, vec3 normal) {
    return oreLightAt(worldPos + normalize(normal) * 0.5);
}
