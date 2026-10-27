// Static overcast deck of a long rain (nimbostratus): almost uniform dark gray,
// no shapes, wind or sun. Only very large blurry patches slightly darker / lighter,
// so the sky does not look like a flat fill. 2 octaves of value noise over the view direction.

const float CLOUD_SCALE = 0.8; // patch size: larger = smaller patches

float cloudHash(vec2 p) {
    vec3 p3 = fract(p.xyx * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// value noise with a quintic curve: no grid diamonds show on large soft patches
float cloudNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    float a = cloudHash(i);
    float b = cloudHash(i + vec2(1.0, 0.0));
    float c = cloudHash(i + vec2(0.0, 1.0));
    float d = cloudHash(i + 1.0);
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// col = sky color from getSkyColor, dir.y > 0; skyMul / skyTint / twBase / flash are the same as for getSkyColor
vec3 applyClouds(vec3 col, vec3 dir, float skyMul, vec3 skyTint, vec3 twBase, float flash) {
    float h = dir.y;

    // up to CLOUD_HORIZON degrees above the horizon the sky is exactly the fog color, over the next ~20 degrees
    // the patches fade in: this way a mountain at the render edge does not stand out against darker patches
    float hStart = sin(radians(float(CLOUD_HORIZON)));
    float hEnd   = sin(radians(float(CLOUD_HORIZON) + 20.0));
    // blend weight 0 -> the deck is invisible, skip the noise and the rest
    if (h <= hStart) return col;
    float w = smoothstep(hStart, hEnd, h);

    // projection onto a plane; the large +0.35 strongly softens the squeeze towards the horizon
    vec2 p = dir.xz / (h + 0.35) * CLOUD_SCALE;
    float d = cloudNoise(p + 3.7) * 0.7 + cloudNoise(p * 2.3 + 11.1) * 0.3;

    // base deck of the same color as the fog (getOvercast in sky.glsl), with barely visible patches
    vec3 deck = HORIZON_COLOR * getOvercast() * skyMul * (1.0 - (d - 0.5) * CLOUD_VARIATION);
    // orange / blue hour tints the whole deck, like the sky below it
    deck *= getSkyTint(skyTint, h);

    // sunset glow (already weakened in getTwilightBase) is the same as for the sky below the deck:
    // in the transition band to the patches the deck is neither darker nor lighter than the sky
    deck += getSkyGlow(twBase, h);
    // lightning lights the deck from within
    deck += LIGHTNING_COLOR * flash * (0.35 + 0.5 * d);

    return mix(col, deck, w);
}
