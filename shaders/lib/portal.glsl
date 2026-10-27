#include "/lib/portal_buf.glsl"

const vec3 PORTAL_COLOR = vec3(0.6, 0.18, 1.0);

// Colored light from the nearest portal on neighbouring blocks (as a share of albedo)
vec3 portalLight(vec3 worldPos, float blockLight) {
#ifdef PORTAL_LIGHT
    // behind a wall there is little block light and the glow must not leak through (the smoothstep below gives 0 at blockLight <= 0.15),
    // hence the check before reading the SSBO
    if (blockLight <= 0.15) return vec3(0.0);
    if (portalBuf.latKey == 0xFFFFFFFFu || portalBuf.latPos.w < 0.5) return vec3(0.0);

    float a = 1.0 - smoothstep(0.0, float(PORTAL_LIGHT_RADIUS), distance(worldPos, portalBuf.latPos.xyz));
    return PORTAL_COLOR * a * a * smoothstep(0.15, 0.65, blockLight);
#else
    return vec3(0.0);
#endif
}

// Portal frame obsidian: the block light around it is tinted purple
vec3 portalFrameLight(int id, float blockLight) {
#ifdef PORTAL_FRAME_TINT
    if (id == 10023) return PORTAL_COLOR * smoothstep(0.45, 0.7, blockLight) * 0.8;
#endif
    return vec3(0.0);
}
