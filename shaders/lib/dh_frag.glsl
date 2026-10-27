// Distant Horizons LODs: the same lighting, snow and fog as lib/terrain_frag.glsl, without per-block effects
// (dynamic light, ore glow, portals are invisible at this distance anyway). DH_WATER = dh_water program
#include "/lib/sky.glsl"
#include "/lib/snow.glsl"

uniform float far;
uniform int isEyeInWater;
uniform float sunAngle;
#ifdef DH_WATER
uniform sampler2D depthtex1;
#endif

in vec2 lmcoord;
in vec4 glcolor;
in float fogDist;
in float cullDist;
in vec3 worldPos;
in vec3 worldNormal;
flat in int matId;
flat in vec3 frameAmb;
flat in vec3 frameFog;
flat in float frameDay;
flat in vec4 frameFlick;

#ifdef DH_WATER
/* RENDERTARGETS: 0,4,5 */
#else
/* RENDERTARGETS: 0 */
#endif

void main() {
    // inside the vanilla render distance real chunks are drawn: vanilla always wins (it has its own depth buffer),
    // the margin covers the chunk-sized steps of the loaded area
    if (cullDist < far - 16.0) discard;
#ifdef DH_WATER
    // DH depth knows nothing about vanilla blocks: water must not cover a vanilla mountain in front of it
    if (texelFetch(depthtex1, ivec2(gl_FragCoord.xy), 0).r < 1.0) discard;
#endif

    vec4 c = glcolor;
#ifdef DH_WATER
    bool water = matId == DH_BLOCK_WATER;
    if (water) {
        // same recolor as lib/terrain_frag.glsl, the vertex color stands in for the texture
        float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
        c.rgb = mix(c.rgb, vec3(lum) * WATER_COLOR * 3.0 * WATER_BRIGHTNESS, 0.85);
        c.a = WATER_OPACITY;
    }
#endif
#ifdef SNOWIFY
#if !defined NETHER && !defined END
    // only grass and leaves carry a biome tint: other colors go through the plain snow cover branch
    bool foliage = matId == DH_BLOCK_GRASS || matId == DH_BLOCK_LEAVES;
#ifdef DH_WATER
    if (!water)
#endif
    c.rgb = snowify(c.rgb, c.rgb, foliage ? c.rgb : vec3(1.0), vec3(1.0), worldNormal, lmcoord);
#endif
#endif

    vec3 albedo = c.rgb;
    float flick = getFlicker(worldPos, frameFlick);
    vec3 light = getLight(lmcoord, frameAmb, frameDay, flick);
    c.rgb *= light;
    // glowstone, lamps, lava: keep their own color at night
    if (matId == DH_BLOCK_ILLUMINATED || matId == DH_BLOCK_LAVA) c.rgb = max(c.rgb, albedo);

    if (isEyeInWater == 0) {
        float fogAmt = getFogAmount(fogDist, FOG_FAR);
        c.rgb = mix(c.rgb, frameFog, fogAmt) + getFogGlow(fogAmt, fogDist, lmcoord.x, flick);
    } else if (isEyeInWater == 1) {
        c.rgb = underwaterFog(c.rgb, fogDist, sunAngle);
    }

    gl_FragData[0] = c;
#ifdef DH_WATER
    // water mask and surface color for composite, as in lib/terrain_frag.glsl
    float waterLit = clamp(dot(light - MIN_LIGHT, vec3(0.333)), 0.0, 1.0);
    gl_FragData[1] = vec4(water ? 1.0 : 0.0, waterLit, 0.0, 1.0);
    gl_FragData[2] = vec4(c.rgb, 1.0);
#endif
}
