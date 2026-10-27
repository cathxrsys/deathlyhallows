#include "/lib/sky.glsl"
#ifdef INTRO_TITLE
#include "/lib/intro.glsl"
#endif

uniform sampler2D colortex0;
#if defined(GLOW) || defined(SHARPEN)
const bool colortex0MipmapEnabled = true;
#endif
uniform float sunAngle;
uniform float viewWidth;
uniform float viewHeight;
#ifdef FILM_GRAIN
uniform int frameCounter;
#endif
#ifdef LOW_HEALTH
uniform float currentPlayerHealth; // Iris: fraction 0..1, -1 in creative mode
uniform float maxPlayerHealth;
#endif
#if defined(LOW_HEALTH) || defined(LOW_AIR)
uniform float currentPlayerAir; // Iris: fraction 0..1, goes below zero when drowning
uniform float maxPlayerAir;
#endif
#if defined(NETHER) && defined(NETHER_HAZE)
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
#endif

in vec2 texcoord;

/* RENDERTARGETS: 0 */

float luma(vec3 c) {
    return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 fetch(vec2 uv) {
    // textureLod, because a plain texture() inside branches gives an undefined mip
    return textureLod(colortex0, uv, 0.0).rgb;
}

#ifdef FXAA
// light FXAA: early exit without blurring when there is no edge
vec3 fxaa(vec2 uv) {
    vec2 px = 1.0 / vec2(viewWidth, viewHeight);

    vec3  rgbM = fetch(uv);
    float lM   = luma(rgbM);
    float lNW  = luma(fetch(uv + vec2(-1.0, -1.0) * px));
    float lNE  = luma(fetch(uv + vec2( 1.0, -1.0) * px));
    float lSW  = luma(fetch(uv + vec2(-1.0,  1.0) * px));
    float lSE  = luma(fetch(uv + vec2( 1.0,  1.0) * px));

    float lMin = min(lM, min(min(lNW, lNE), min(lSW, lSE)));
    float lMax = max(lM, max(max(lNW, lNE), max(lSW, lSE)));

    if (lMax - lMin < max(0.0625, lMax * 0.2)) return rgbM;

    vec2 dir;
    dir.x = -((lNW + lNE) - (lSW + lSE));
    dir.y =  ((lNW + lSW) - (lNE + lSE));

    float dirReduce = max((lNW + lNE + lSW + lSE) * 0.03125, 1.0 / 128.0);
    float rcpMin    = 1.0 / (min(abs(dir.x), abs(dir.y)) + dirReduce);
    dir = clamp(dir * rcpMin, -2.0, 2.0) * px;

    vec3 rgbA = 0.5 * (fetch(uv + dir * (1.0 / 3.0 - 0.5)) + fetch(uv + dir * (2.0 / 3.0 - 0.5)));
    vec3 rgbB = rgbA * 0.5 + 0.25 * (fetch(uv - dir * 0.5) + fetch(uv + dir * 0.5));

    float lB = luma(rgbB);
    vec3 aa = (lB < lMin || lB > lMax) ? rgbA : rgbB;
    return mix(rgbM, aa, FXAA_STRENGTH);
}
#endif

#if defined(NETHER) && defined(NETHER_HAZE)
float hazeDist(vec2 uv) {
    float d = textureLod(depthtex0, uv, 0.0).r;
    if (d >= 1.0) return 1e4;
    vec4 p = gbufferProjectionInverse * vec4(uv * 2.0 - 1.0, d * 2.0 - 1.0, 1.0);
    return length(p.xyz / p.w);
}

// Nether heat haze: the distance shimmers like air above a campfire. Waves in screen space rise upwards,
// closer than NETHER_HAZE_DIST there is no distortion (hand and near blocks stay sharp), at 2.5 * NETHER_HAZE_DIST it is full
vec2 netherHaze(vec2 uv) {
    float D = float(NETHER_HAZE_DIST);
    float k = smoothstep(D, D * 2.5, hazeDist(uv));
    if (k <= 0.0) return uv;

    // speed drifts smoothly between MIN and MAX (two slow sines, periods ~17 and ~27 s, gusts do not repeat rhythmically).
    // t is the phase, the integral of speed over time: simply multiplying time by speed makes the pattern jerk and roll back
    float T = frameTimeCounter;
    float mid = 0.5 * (NETHER_HAZE_SPEED_MIN + NETHER_HAZE_SPEED_MAX);
    float amp = 0.5 * (NETHER_HAZE_SPEED_MAX - NETHER_HAZE_SPEED_MIN);
    float t = mid * T - amp * (0.6 / 0.37 * cos(T * 0.37) + 0.4 / 0.23 * cos(T * 0.23));
    float aspect = viewWidth / viewHeight;
    vec2 p = vec2(uv.x * aspect, uv.y);
    // texture y grows upwards, so "- t" in the y phase makes waves rise
    // four layers: large slow waves and fine fast ripples with incommensurate frequencies.
    // Ripples are stronger on the crests of the large wave, so they shimmer in patches rather than as an even grid
    vec2 big = vec2(sin(p.y * 70.0 - t * 2.3 + sin(p.x * 27.0 + t * 0.9) * 2.0),
                    sin(p.x * 53.0 + t * 1.4 + sin(p.y * 37.0 - t * 1.6) * 2.0));
    vec2 small = vec2(sin(p.y * 460.0 - t * 4.0 + sin(p.x * 190.0 + t * 1.3) * 1.5),
                      sin(p.x * 360.0 + t * 2.1 + sin(p.y * 250.0 - t * 2.7) * 1.5));
    // two more layers at the ends of the spectrum: a huge half-screen wave and a tiny few-pixel ripple.
    // Frequencies are incommensurate with the rest, so pattern repeats between layers never form a visible grid
    vec2 huge = vec2(sin(p.y * 9.0 - t * 0.7 + sin(p.x * 5.3 + t * 0.3) * 2.0),
                     sin(p.x * 7.1 + t * 0.5 + sin(p.y * 6.1 - t * 0.4) * 2.0));
    vec2 tiny = vec2(sin(p.y * 1130.0 - t * 5.3 + sin(p.x * 870.0 + t * 1.9) * 1.5),
                     sin(p.x * 970.0 + t * 3.1 + sin(p.y * 1290.0 - t * 3.7) * 1.5));
    vec2 w = huge * 0.3 + big * 0.4 + small * 0.3 * (0.6 + 0.4 * big.y) + tiny * 0.2 * (0.6 + 0.4 * huge.x);
    vec2 suv = uv + vec2(w.x / aspect, w.y) * k * NETHER_HAZE_STRENGTH * 0.0006;

    // the shift must not pull a near object (wall edge, mob) into a far pixel
    if (hazeDist(suv) < D) return uv;
    return suv;
}
#endif

#ifdef LOW_HEALTH
// Low health: the edges flood red in time with the heartbeat (double beat, faster at lower health), colors fade.
// No effect if Iris provides no values (maxPlayerHealth = 0) or the player is in creative mode
vec3 lowHealth(vec3 c, float r2) {
    if (maxPlayerHealth <= 0.0 || currentPlayerHealth < 0.0) return c;
    float k = 1.0 - smoothstep(0.2, 0.6, currentPlayerHealth);
    if (k <= 0.0) return c;
    // no red while drowning: air damage is shown by the air effect only
    if (maxPlayerAir > 0.0) k *= smoothstep(0.0, 0.3, currentPlayerAir);
    k *= LOW_HEALTH_STRENGTH;

    // slow heart (~45 -> 70 bpm) and soft, wide beats
    float ph = fract(frameTimeCounter * mix(0.75, 1.15, min(k, 1.0)));
    float a = (ph - 0.08) * 5.5;
    float b = (ph - 0.38) * 5.5;
    float beat = max(exp(-a * a), 0.6 * exp(-b * b));

    float edge = clamp(r2 * 4.0, 0.0, 1.0);
    float red = edge * (0.35 + 0.45 * beat) * min(k, 1.0);
    c = mix(c, vec3(luma(c)), 0.5 * min(k, 1.0));
    return c * (1.0 - red * 0.5) + vec3(0.30, 0.0, 0.02) * red;
}
#endif

#ifdef LOW_AIR
// Running out of air: the image darkens and narrows towards the center, colors go cold gray, the pulse speeds up.
// Works for any air supply, not only underwater (potions, effects)
vec3 lowAir(vec3 c, float r2) {
    if (maxPlayerAir <= 0.0) return c;
    float air = clamp(currentPlayerAir, 0.0, 1.0);
    // starts early and ramps up smoothly (squared), darkens sharply only at the very end
    float t = 1.0 - smoothstep(0.0, 0.65, air);
    float k = t * t * min(LOW_AIR_STRENGTH, 1.5);
    if (k <= 0.0) return c;

    float pulse = 0.5 + 0.5 * sin(frameTimeCounter * mix(2.0, 7.0, air < 0.2 ? 1.0 - air * 5.0 : 0.0));
    float edge = clamp(r2 * 4.0, 0.0, 1.0);
    c = mix(c, vec3(luma(c)) * vec3(0.8, 0.95, 1.1), 0.5 * min(k, 1.0));
    c *= 1.0 - 0.3 * min(k, 1.0);
    return c * (1.0 - edge * min(k, 1.0) * (0.55 + 0.25 * pulse));
}
#endif

#ifdef FILM_GRAIN
// integer hash (pcg3d): three independent values for about a dozen integer operations
uvec3 pcg3d(uvec3 v) {
    v = v * 1664525u + 1013904223u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    v ^= v >> 16u;
    v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
    return v;
}

// rgb - per-channel noise 0..1, w - random number for grain sparsity
vec4 grainCell(vec2 cell, uint fr) {
    uvec3 h = pcg3d(uvec3(uvec2(cell), fr));
    return vec4(vec3(h >> 8u) * (1.0 / 16777216.0), float(h.x & 255u) * (1.0 / 255.0));
}

// Film grain, new every frame. GRAIN_SIZE - grain size in pixels (above 1 - soft blobs),
// GRAIN_CONTRAST - soft ripple or hard specks, GRAIN_OPACITY - how visible the grain is,
// GRAIN_COLOR - share of colored noise, GRAIN_DENSITY - share of grains (lower = sparser, single specks)
vec3 filmGrain(vec3 c, vec2 fragCoord) {
    uint fr = uint(frameCounter);
    vec2 p = (fragCoord - 0.5) / GRAIN_SIZE;
    vec4 g;
    // constant condition: at size 1 the compiler keeps one hash sample instead of four
    if (GRAIN_SIZE <= 1.0) {
        g = grainCell(p, fr);
    } else {
        vec2 i = floor(p);
        vec2 f = fract(p);
        f = f * f * (3.0 - 2.0 * f);
        g = mix(mix(grainCell(i, fr), grainCell(i + vec2(1.0, 0.0), fr), f.x),
                mix(grainCell(i + vec2(0.0, 1.0), fr), grainCell(i + 1.0, fr), f.x), f.y);
    }

    vec3 n = clamp((mix(vec3(g.x), g.xyz, GRAIN_COLOR) * 2.0 - 1.0) * GRAIN_CONTRAST, -1.0, 1.0);
    // sparse grain: some specks vanish, the rest are brighter so the overall strength does not drop
    float mask = GRAIN_DENSITY >= 1.0 ? 1.0 : smoothstep(1.0 - GRAIN_DENSITY, 1.0 - GRAIN_DENSITY + 0.08, g.w) / sqrt(GRAIN_DENSITY);
    // grain is most visible in midtones, weaker in black and white
    float l = luma(c);
    float resp = 0.5 + 2.0 * l * (1.0 - l);
    return max(c + n * mask * resp * GRAIN_OPACITY * 0.25, 0.0);
}
#endif

void main() {
    vec2 uv = texcoord;
#if defined(NETHER) && defined(NETHER_HAZE)
    uv = netherHaze(uv);
#endif

#ifdef FXAA
    vec3 c = fxaa(uv);
#else
    vec3 c = fetch(uv);
#endif

    // light sharpening: a single read of a lower mip level, only paid for when enabled
#ifdef SHARPEN
    c = max(c + (c - textureLod(colortex0, uv, 1.0).rgb) * SHARPEN_STRENGTH, 0.0);
#endif

    vec2  d  = texcoord - 0.5;
    float r2 = dot(d, d);

    // 0. chromatic aberration: screen edges only, the center is skipped
#ifdef CHROMA
    float mask = smoothstep(0.3, 1.2, r2 * 4.0);
    if (mask > 0.001) {
        vec2 off = d * CHROMA_STRENGTH * 0.02 * mask;
        vec3 ca = vec3(fetch(uv + off).r, c.g, fetch(uv - off).b);
        c = mix(c, ca, CHROMA_OPACITY * mask);
    }
#endif

    // 1. highlight boost, at night only (always in the Nether)
#if defined(NETHER) || defined(END)
    float night = 0.6;
#else
    float night = 1.0 - getDay(sunAngle);
#endif
    float hl = smoothstep(0.35, 0.9, luma(c));
    c += c * hl * HIGHLIGHT_BOOST * night;

    // 2. glow + light haze
#ifdef GLOW
    vec3 blur = texture(colortex0, texcoord, 5.0).rgb;
    c += max(blur - 0.45, 0.0) * GLOW_STRENGTH;
    c = mix(c, blur, 0.12);
#endif

    // 3. dark areas lose color (weaker in the Nether, no color shift)
    float l    = luma(c);
    float dark = 1.0 - smoothstep(0.0, 0.3, l);
#if defined(NETHER) || defined(END)
    c = mix(c, vec3(l), dark * NIGHT_DESATURATION * 0.3);
#else
    // the world is dim in warm twilight, and desaturating the dark would eat the whole sunset tint
    float warmTw = getTwilightWarm(sunAngle) * min(TWILIGHT_STRENGTH, 1.0);
    c = mix(c, vec3(l) * vec3(0.85, 0.95, 1.2), dark * NIGHT_DESATURATION * (1.0 - 0.75 * warmTw));
#endif

    // 4. global desaturation + cold tint (no tint in the Nether, weaker at sunset)
    l = luma(c);
#if defined(NETHER) || defined(END)
    c = mix(c, vec3(l), DESATURATION);
#else
    c = mix(c, vec3(l), DESATURATION * (1.0 - 0.6 * warmTw));
    c *= mix(vec3(0.96, 0.98, 1.03), vec3(1.0), warmTw);
#endif

    // 5. vignette
#ifdef VIGNETTE
    c *= 1.0 - r2 * 0.9;
#endif

#ifdef LOW_HEALTH
    c = lowHealth(c, r2);
#endif
#ifdef LOW_AIR
    c = lowAir(c, r2);
#endif

#ifdef FILM_GRAIN
    c = filmGrain(c, gl_FragCoord.xy);
#endif

#ifdef INTRO_TITLE
    c = introTitle(c, texcoord, vec2(viewWidth, viewHeight));
#endif

    gl_FragData[0] = vec4(c + dither8(gl_FragCoord.xy), 1.0);
}
