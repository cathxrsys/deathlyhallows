// Glow of ores, redstone torches and redstone dust.
// Returns a color that must not be darker than the lighting (0 = no glow).
// Ores glow only with the ore pixels themselves, not the surrounding stone.
vec3 getEmission(int id, vec3 tex, vec3 tint, float dist) {
    if (id < 10010 || id > 10046) return vec3(0.0);

    float mx = max(tex.r, max(tex.g, tex.b));
    float mn = min(tex.r, min(tex.g, tex.b));
    float lum = dot(tex, vec3(0.299, 0.587, 0.114));

    float mask = 0.0;
    float k = 0.0;

    // distant ores glow weaker: full strength up close, ORE_FAR_GLOW at ORE_FADE_DIST
    float near = mix(1.0, ORE_FAR_GLOW, smoothstep(4.0, float(ORE_FADE_DIST), dist));

    if (id >= 10040 && id <= 10046) {
        // colored ore on gray stone: the stone has almost no saturation
        mask = smoothstep(0.10, 0.20, mx - mn);
        k = ORE_GLOW * 0.4 * near;
    } else if (id == 10011) {
        // coal: dark specks
        mask = 1.0 - smoothstep(0.12, 0.22, lum);
        k = ORE_GLOW * 0.4 * near;
    } else if (id == 10012 || id == 10013) {
        // nether ores: light specks on dark red stone
        mask = smoothstep(0.45, 0.60, lum);
        k = ORE_GLOW * 0.4 * near;
    } else if (id == 10020) {
        // burning tip of a redstone torch
        mask = smoothstep(0.25, 0.40, tex.r - max(tex.g, tex.b)) * smoothstep(0.5, 0.7, tex.r);
        k = REDSTONE_GLOW * 1.0;
    } else if (id == 10024) {
        // powered repeater: red torches on a gray base
        mask = smoothstep(0.25, 0.40, tex.r - max(tex.g, tex.b)) * smoothstep(0.5, 0.7, tex.r);
        k = REDSTONE_GLOW * 1.0;
    } else if (id == 10021) {
        // dust glows stronger the higher the signal (tint.r: 0.3 .. 1.0)
        mask = tint.r * tint.r;
        return tex * tint * mask * REDSTONE_GLOW * 1.0;
    } else if (id == 10022) {
        // nether portal: purple glow driven by texture brightness (the animation is already in it), no extra samples
        float v = 0.35 + 1.4 * lum;
        return mix(vec3(0.55, 0.15, 1.0), vec3(0.85, 0.45, 1.0), lum) * v * PORTAL_GLOW;
    }

    return tex * mask * k;
}
