#include "/lib/sky.glsl"
#include "/lib/emissive.glsl"
#include "/lib/portal.glsl"
#include "/lib/held_light.glsl"
#include "/lib/ore_light.glsl"
#include "/lib/snow.glsl"

uniform sampler2D gtexture;
uniform float far;
uniform int isEyeInWater;
uniform float sunAngle;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in float fogDist;
in vec3 worldPos;
in vec3 worldNormal;
in vec3 tintColor;
flat in int matId;
flat in vec3 frameAmb;
flat in vec3 frameFog;
flat in float frameDay;
flat in vec4 frameFlick;

/* RENDERTARGETS: 0,4,5 */

void main() {
    vec4 tex = texture(gtexture, texcoord);
    vec3 tint = tintColor;
    if (matId == 10030) {
        // water: keep the original texture pattern, shift the color towards WATER_COLOR
        float lum = dot(tex.rgb * glcolor.rgb, vec3(0.299, 0.587, 0.114));
        tex.rgb = mix(tex.rgb * glcolor.rgb, vec3(lum) * WATER_COLOR * 3.0 * WATER_BRIGHTNESS, 0.85);
        tint = vec3(1.0);
    }
    float alpha = matId == 10030 ? WATER_OPACITY : glcolor.a; // murk is computed by composite from the water thickness
    if (matId == 10031) {
        // ice: its own transparency instead of the texture alpha
        tex.a = 1.0;
        alpha = ICE_OPACITY;
    }
    vec4 c = tex * vec4(tint, alpha);
    if (c.a < 0.1) discard;
#ifdef SNOWIFY
#if !defined NETHER && !defined END
    // water, redstone and portal are tinted as well, leave them alone
    if (matId != 10030 && matId != 10021 && matId != 10022) c.rgb = snowify(c.rgb, tex.rgb, glcolor.rgb, tint, worldNormal, lmcoord);
#endif
#endif

    vec3 albedo = c.rgb;
    float flick = getFlicker(worldPos, frameFlick);
    vec3 light = getLight(lmcoord, frameAmb, frameDay, flick);
    // water lighting without MIN_LIGHT: in full darkness the murk in composite must fade to black
    float waterLit = clamp(dot(light - MIN_LIGHT, vec3(0.333)), 0.0, 1.0);
    c.rgb *= light;
    // purple portal light on neighbouring blocks (the portal itself already glows via emission, no light added to it)
    vec3 portalAdd = portalFrameLight(matId, lmcoord.x);
    if (matId != 10022) portalAdd += portalLight(worldPos, lmcoord.x);
    c.rgb += albedo * portalAdd * PORTAL_LIGHT_STRENGTH;
    c.rgb += albedo * heldLight(worldPos);
    // colored ore light on the block itself and its neighbours
    c.rgb += albedo * oreLight(worldPos, worldNormal);
    // by day in lit places the glow is stronger, in the dark it stays weak
    float dayGlow = 1.0 + 3.0 * ORE_DAY_GLOW * frameDay * lmcoord.y;
    c.rgb = max(c.rgb, getEmission(matId, tex.rgb, glcolor.rgb, fogDist) * dayGlow);

    if (isEyeInWater == 0) {
        float fogAmt = getFogAmount(fogDist, FOG_FAR);
        c.rgb = mix(c.rgb, frameFog, fogAmt) + getFogGlow(fogAmt, fogDist, lmcoord.x, flick);
    } else if (isEyeInWater == 1) {
        c.rgb = underwaterFog(c.rgb, fogDist, sunAngle);
    }

    gl_FragData[0] = c;
    // water mask for composite; alpha 1 so blending does not distort the values
    gl_FragData[1] = vec4(matId == 10030 ? 1.0 : 0.0, waterLit, 0.0, 1.0);
    // the surface color itself: composite puts it back over the murk, otherwise the water pattern is lost
    gl_FragData[2] = vec4(c.rgb, 1.0);
}
