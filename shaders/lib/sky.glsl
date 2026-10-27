#include "/lib/settings.glsl"

uniform float boltOn;
uniform float boltFade;
uniform float boltGlow;
uniform float boltFar;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform ivec2 eyeBrightnessSmooth;

#ifdef NETHER
const vec3 NETHER_AMBIENT = vec3(0.30, 0.25, 0.23); // flat light instead of a sky
const vec3 NETHER_FOG     = vec3(0.13, 0.07, 0.06); // dark fog, ignores vanilla fogColor
#endif

#ifdef END
const vec3 END_AMBIENT = vec3(0.50, 0.42, 0.62); // flat cold purple light instead of a sky
const vec3 END_FOG     = vec3(0.20, 0.13, 0.28); // fog at the horizon
const vec3 END_ZENITH  = vec3(0.10, 0.06, 0.17); // top of the sky
#endif

// ---------- colors ----------
const vec3  HORIZON_COLOR = vec3(0.38, 0.40, 0.43);
const vec3  ZENITH_COLOR  = vec3(0.62, 0.64, 0.66);
const float NIGHT_SKY     = 0.06 * NIGHT_BRIGHTNESS;
const float DAY_LEVEL     = 1.0 - 0.35 * DAY_GLOOM; // daytime sky and fog level

const vec3  TWILIGHT_WARM = vec3(1.00, 0.50, 0.22); // sunset / sunrise
const vec3  TWILIGHT_COOL = vec3(0.22, 0.32, 0.70); // blue hour after sunset

// the overcast deck dims the horizon: fog and the lower sky use the same multiplier as the clouds,
// otherwise bright fog detaches from the darker sky
#ifdef CLOUDS
// warm correction: HORIZON_COLOR is bluish and final_pass cools dark areas and the whole image further,
// without it the overcast looks noticeably blue; SKY_COOL brings some of the cold back
const vec3  CLOUD_TINT = mix(vec3(1.08, 1.0, 0.88), vec3(0.96, 0.98, 1.02), SKY_COOL);
vec3 getOvercast() {
    return CLOUD_TINT * (1.0 - CLOUD_DARKNESS) * (1.0 - RAIN_SKY_DARKNESS * rainStrength);
}
#else
vec3 getOvercast() {
    return vec3(1.0);
}
#endif

// strength of the rain haze: only where the player sees the sky, absent in caves, fades back in on exit
// (eyeBrightnessSmooth.y is the skylight at the eyes, 0..240, already smoothed over time)
float getHazeDensity() {
    return RAIN_FOG * rainStrength * smoothstep(0.1, 0.6, float(eyeBrightnessSmooth.y) / 240.0);
}

// rain haze amount at distance dist, r = getHazeDensity.
// Density is in blocks rather than relative to far: the haze builds up near the player at any render distance
float getHazeAmount(float dist, float r) {
    return (1.0 - exp(-0.008 * r * dist)) * min(0.6 * r, 0.95);
}

// fog edge distance: with Distant Horizons the fog hides the LOD edge instead of the vanilla render distance
#ifdef DISTANT_HORIZONS
uniform int dhRenderDistance;
#define FOG_FAR float(dhRenderDistance)
#else
#define FOG_FAR far
#endif

// fog amount at distance dist: normally it only hides the render distance edge (0.3 far .. 0.9 far),
// in rain the haze is added on top, starting right at the player
float getFogAmount(float dist, float farDist) {
    // fully fogged slightly before far: a mountain at the very edge no longer shows through
    float edge = smoothstep(farDist * 0.3, farDist * 0.9, dist);
    return max(edge, getHazeAmount(dist, getHazeDensity()));
}

// ---------- water ----------
const vec3  WATER_COLOR    = vec3(0.28, 0.21, 0.14); // dark gray-brown water instead of the biome blue
const vec3  WATER_MURK     = vec3(0.23, 0.19, 0.13); // brown murk inside the water when looking from above
const vec3  UNDERWATER_FOG = WATER_MURK; // underwater uses the same color as the murk seen from above

// ---------- light ----------
const vec3  DAY_AMBIENT     = vec3(0.92, 0.95, 1.00) * DAY_LEVEL;
const vec3  NIGHT_AMBIENT   = vec3(0.06, 0.07, 0.12) * NIGHT_BRIGHTNESS;
const vec3  BLOCK_LIGHT     = vec3(1.00, 0.62, 0.30);
const vec3  LIGHTNING_COLOR = vec3(0.75, 0.82, 1.00);
const float MIN_LIGHT       = 0.012;

// sun height: 1 = noon, 0 = horizon, -1 = midnight
float getSunHeight(float sunAngle) {
    return sin(sunAngle * 6.28318);
}

// smooth day/night transition; TWILIGHT_LENGTH stretches it
float getDay(float sunAngle) {
#if defined(NETHER) || defined(END)
    return 0.0;
#else
    float L = TWILIGHT_LENGTH;
    return smoothstep(-0.25 * L, 0.30 + 0.15 * (L - 1.0), getSunHeight(sunAngle));
#endif
}

// 1 at the horizon line, fades smoothly towards day and night
float getTwilight(float sunAngle) {
    float s = getSunHeight(sunAngle);
    float w = 0.2 * TWILIGHT_LENGTH;
    return exp(-(s * s) / (w * w));
}

vec3 getTwilightColor(float sunAngle) {
    float L = TWILIGHT_LENGTH;
    return mix(TWILIGHT_COOL, TWILIGHT_WARM, smoothstep(-0.12 * L, 0.08 * L, getSunHeight(sunAngle)));
}

// 0..1: how strong the warm phase of twilight is (sun at the horizon), blue hour is not included
float getTwilightWarm(float sunAngle) {
    float L = TWILIGHT_LENGTH;
    return getTwilight(sunAngle) * smoothstep(-0.12 * L, 0.08 * L, getSunHeight(sunAngle));
}

// Orange hour / blue hour: color multiplier for light, fog, sky and clouds.
// The warm phase (sun at the horizon) tints stronger, the blue hour after sunset is softer.
vec3 getTwilightTint(float sunAngle) {
    vec3 t = 1.0 + (getTwilightColor(sunAngle) - 0.5) * TWILIGHT_STRENGTH
                 * (getTwilight(sunAngle) * 0.6 + getTwilightWarm(sunAngle) * 1.0);
    return max(t, 0.0);
}

// Twilight glow without the view height (per-vertex, not per-pixel).
// The height factor pow(1 - h, 2.5) is applied in getSkyColor; fog has h = 0 -> factor 1,
// so the fog matches the sky at the horizon.
// Under the overcast deck the glow is weaker: the main color comes from getTwilightTint.
vec3 getTwilightBase(float sunAngle) {
#ifdef CLOUDS
    return getTwilightColor(sunAngle) * getTwilight(sunAngle) * TWILIGHT_STRENGTH * 0.14;
#else
    return getTwilightColor(sunAngle) * getTwilight(sunAngle) * TWILIGHT_STRENGTH * 0.25;
#endif
}

// interleaved gradient noise, -0.5/255 .. 0.5/255: dithering before the 8-bit write removes gradient banding
float dither8(vec2 fragCoord) {
    return (fract(52.9829189 * fract(dot(fragCoord, vec2(0.06711056, 0.00583715)))) - 0.5) / 255.0;
}

float hash11(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

// Lightning: the main strike + a series of repeated flashes (like real return strokes).
// Every bolt gets its own random parameters: flicker pace, repeat chance,
// brightness and tail length, so two strikes in a row never look the same.
// The seed changes every few seconds, i.e. between bolts.
float getFlash() {
    // no bolt (boltOn = 0, boltGlow tail below the 0.1 minimum): the flash is always 0
    if (boltOn <= 0.0 && boltGlow < 0.1) return 0.0;

    float seed = floor(frameTimeCounter / 4.0) * 7.31;
    float rPace  = hash11(seed + 1.0);
    float rChance = hash11(seed + 2.0);
    float rPower = hash11(seed + 3.0);
    float rTail  = hash11(seed + 4.0);

    // main strike
    float f = 1.0 - boltFade;
    float main = boltOn * f * f * mix(0.75, 1.15, rPower);

    // repeated flashes: cells of random length, some are empty -> pauses and 2-3 volleys
    float cellLen = mix(0.05, 0.12, rPace);
    float tc = frameTimeCounter / cellLen;
    float cell = floor(tc);
    float r = hash11(cell + seed * 13.0);
    float thr = mix(0.35, 0.65, rChance);
    float pulse = step(thr, r) * mix(0.5, 1.0, hash11(cell * 1.7 + seed)) * exp(-fract(tc) * 2.5);

    // a bolt lives for a varying time: the tail is cut at a random decay level
    float alive = step(mix(0.1, 0.8, rTail), boltGlow);

    // a strike kilometers away lights the sky much less than one next to you
    return max(main, pulse * alive * 0.8) * LIGHTNING_STRENGTH * (1.0 - boltFar);
}

// Everything below that depends only on sunAngle and time is per-frame, not per-pixel: it is computed
// in prepare.csh or the vertex shader and reaches the fragment shader as flat (frameAmb / frameFog / frameDay etc.)
vec3 getFogColor(float sunAngle) {
#ifdef NETHER
    return NETHER_FOG * NETHER_BRIGHTNESS;
#elif defined(END)
    return END_FOG * END_BRIGHTNESS;
#else
    float day = getDay(sunAngle);
    return HORIZON_COLOR * getOvercast() * mix(NIGHT_SKY, DAY_LEVEL, day) * getTwilightTint(sunAngle)
         + getTwilightBase(sunAngle)
         + LIGHTNING_COLOR * getFlash() * 0.5;
#endif
}

// underwater fog: dense, dark, darker at night
vec3 getUnderwaterFog(float sunAngle) {
    // like regular fog: NIGHT_SKY at night, not 0.35 of day (otherwise underwater is brighter than outside)
    float lit = mix(NIGHT_SKY, DAY_LEVEL, getDay(sunAngle));
    // fog does not glow by itself: without sky overhead (cave, depth) it darkens, a torch near the eyes lights it
    float sky = float(eyeBrightnessSmooth.y) / 240.0;
    float blk = float(eyeBrightnessSmooth.x) / 240.0;
    return UNDERWATER_FOG * max(lit * smoothstep(0.0, 0.8, sky), blk * 0.5);
}

vec3 getWaterMurk(float sunAngle) {
    return WATER_MURK * mix(0.35, 1.0, getDay(sunAngle));
}

vec3 underwaterFog(vec3 c, float dist, float sunAngle) {
    return mix(c, getUnderwaterFog(sunAngle), 1.0 - exp(-dist * UNDERWATER_DENSITY));
}

// sky brightness multiplier
float getSkyMul(float sunAngle) {
    return mix(NIGHT_SKY, DAY_LEVEL, getDay(sunAngle));
}

// height from which the sky twilight falls off. Under the deck, up to CLOUD_HORIZON degrees the value stays at 0:
// the sky twilight there matches the fog (h = 0), so a mountain at the render edge is not brighter than the sky behind it
float getTwilightH(float h) {
#ifdef CLOUDS
    return max(h - sin(radians(float(CLOUD_HORIZON))), 0.0);
#else
    return h;
#endif
}

// twilight tint at height h: full at the horizon (like fog), half as strong at the zenith
vec3 getSkyTint(vec3 skyTint, float h) {
    return mix(skyTint, vec3(1.0), 0.5 * getTwilightH(h));
}

// sunset glow at height h, full at the horizon (like fog)
vec3 getSkyGlow(vec3 twBase, float h) {
    return twBase * pow(1.0 - getTwilightH(h), 2.5);
}

// h - view height above the horizon, 0..1; skyMul = getSkyMul, skyTint = getTwilightTint,
// twBase = getTwilightBase, flash = getFlash
vec3 getSkyColor(float h, float skyMul, vec3 skyTint, vec3 twBase, float flash) {
#ifdef END
    return mix(END_FOG, END_ZENITH, pow(h, 0.5)) * END_BRIGHTNESS;
#else
#ifdef CLOUDS
    // under the deck the lower sky is exactly the fog color: otherwise the sky brightens right above the horizon
    // and a fogged mountain at the render edge looks darker than the sky behind it
    vec3 sky = HORIZON_COLOR * getOvercast() * skyMul * getSkyTint(skyTint, h);
    return sky + getSkyGlow(twBase, h) + LIGHTNING_COLOR * flash * 0.5;
#else
    vec3 sky = mix(HORIZON_COLOR, ZENITH_COLOR, pow(h, 0.6)) * getOvercast() * skyMul * getSkyTint(skyTint, h);
    return sky + getSkyGlow(twBase, h) + LIGHTNING_COLOR * flash * 0.6;
#endif
#endif
}

// ambient without the pixel's skylight
vec3 getAmbient(float sunAngle) {
#ifdef NETHER
    // no sky and no skylight: flat warm ambient
    return NETHER_AMBIENT * NETHER_BRIGHTNESS;
#elif defined(END)
    // no skylight: flat ambient
    return END_AMBIENT * END_BRIGHTNESS;
#else
    float day = getDay(sunAngle);

    vec3 amb = mix(NIGHT_AMBIENT, DAY_AMBIENT, day);
    amb *= getTwilightTint(sunAngle);
    amb += LIGHTNING_COLOR * getFlash() * 1.2;
    return amb;
#endif
}

// Fire flicker: block light "breathes". Four independent signals are mixed by a static XZ map
// (patches of ~6 blocks): torches a few blocks apart flicker out of phase, but the phase does not move
// in space, so no stripes run along walls. The map is the same at every height, so a wall under a torch pulses as a whole.
// The lightmap does not tell what the source is, so lamps flicker too.

// the four flicker signals depend only on time: prepare.csh computes them once per frame (frameBuf.flick)
vec4 getFlickerWave() {
#ifdef TORCH_FLICKER
    float t = frameTimeCounter * FLICKER_SPEED;
    return 0.5 * sin(t * vec4(7.3, 8.7, 6.1, 9.4) + vec4(0.0, 2.2, 3.7, 5.1))
         + 0.3 * sin(t * vec4(12.9, 15.3, 13.7, 11.9) + vec4(1.3, 0.4, 2.9, 4.4))
         + 0.2 * sin(t * vec4(23.1, 19.7, 21.3, 25.7) + vec4(4.1, 5.3, 0.8, 2.6));
#else
    return vec4(0.0);
#endif
}

// s = getFlickerWave
float getFlicker(vec3 p, vec4 s) {
#ifdef TORCH_FLICKER
    // two waves at an angle to each other (period ~13 blocks), their combination selects a mix of the 4 signals;
    // oblique directions so the patches do not line up with the block grid
    vec2 uv = 0.5 + 0.5 * sin(vec2(dot(p.xz, vec2(0.41, 0.23)), dot(p.xz, vec2(-0.19, 0.44))));
    vec4 w = vec4((1.0 - uv.x) * (1.0 - uv.y), uv.x * (1.0 - uv.y), (1.0 - uv.x) * uv.y, uv.x * uv.y);
    // signals cancel each other between patches, so divide by the mix length
    float n = dot(w, s) / max(length(w), 0.5);
    return 1.0 + n * FLICKER_STRENGTH;
#else
    return 1.0;
#endif
}

// amb = getAmbient, day = getDay, flick = getFlicker
vec3 getLight(vec2 lm, vec3 amb, float day, float flick) {
    vec3 blockL = BLOCK_LIGHT * (lm.x * lm.x) * 1.4 * flick;

#if defined(NETHER) || defined(END)
    return amb + blockL;
#else
    // the curve is steeper by day: deeper shadows, volume is preserved
    float skyCurve = pow(lm.y, 2.0 + 0.8 * DAY_GLOOM * day);
    // skylight drops by 1 per block, so at the mouth of a big cave lm.y is already ~0.4-0.6 and the power curve
    // crushes it to black; a smooth tail keeps some diffuse light there and dies out only below lm.y ~0.05
    skyCurve = max(skyCurve, smoothstep(0.05, 0.6, lm.y) * CAVE_LIGHT);

    return amb * skyCurve + blockL + MIN_LIGHT;
#endif
}

// Torch and campfire light scatters in fog: the air in front of a lit surface glows with its block light,
// so rain haze gets a warm halo around fires. There is no halo without rain, and the fog at the render edge
// does not glow either (it only hides the edge). In full fog the halo fades out, otherwise the outlines
// of lit chunks would show at the render edge.
// fogAmt = getFogAmount, bl = lmcoord.x, flick = getFlicker
vec3 getFogGlow(float fogAmt, float dist, float bl, float flick) {
#ifdef FOG_GLOW
    float r = getHazeDensity();
    if (r <= 0.0) return vec3(0.0); // no haze, nothing to glow
    float amt = getHazeAmount(dist, r) * (1.0 - fogAmt) * 1.5;
    return BLOCK_LIGHT * (bl * bl) * amt * flick * FOG_GLOW_STRENGTH;
#else
    return vec3(0.0);
#endif
}
