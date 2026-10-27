// Snowify World: biome foliage and grass turn white with frost, upward faces under the open sky get covered with snow
const vec3 SNOW_COLOR = vec3(0.93, 0.96, 1.0); // slightly cold white

// col - tinted texture, tex - raw texture, vcol - vertex color (biome * AO), tint - tintColor
vec3 snowify(vec3 col, vec3 tex, vec3 vcol, vec3 tint, vec3 n, vec2 lm) {
    float lum = dot(tex, vec3(0.299, 0.587, 0.114));
    float ao  = max(tint.r, max(tint.g, tint.b)); // corner shading on blocks without a biome color
    // snow is the brightest surface: compensate the overcast daylight (DAY_LEVEL), otherwise it turns out gray
    vec3 snowCol = SNOW_COLOR * SNOW_BRIGHTNESS / DAY_LEVEL;
    float sky  = smoothstep(0.5, 0.85, lm.y);
    float melt = 1.0 - smoothstep(0.55, 0.85, lm.x); // snow melts near torches, fire and lava

    // AO darkens all channels equally, so the channel spread = the biome color (grass, leaves, vines)
    float sat = max(vcol.r, max(vcol.g, vcol.b)) - min(vcol.r, min(vcol.g, vcol.b));
    if (sat > 0.03) {
        // on tinted blocks the bright channel = biome color (~0.75) * AO, divide by the biome color to leave only AO
        float fao = clamp(max(vcol.r, max(vcol.g, vcol.b)) / 0.75, 0.0, 1.0);
        // foliage textures are gray: keep the pattern through brightness, frost is weaker under canopies
        vec3 frost = snowCol * (0.7 + 0.45 * lum) * fao;
        return mix(col, frost, SNOW_AMOUNT * melt * mix(0.6, 1.0, sky));
    }

    float top = smoothstep(0.5, 0.9, n.y);
    vec3 snow = snowCol * (0.85 + 0.2 * lum) * ao;
    return mix(col, snow, SNOW_AMOUNT * top * sky * melt);
}
