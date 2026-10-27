#include "/lib/sky.glsl"
#include "/lib/held_light.glsl"
#include "/lib/ore_light.glsl"

uniform sampler2D gtexture;
uniform float far;
uniform int isEyeInWater;
uniform float sunAngle;

#ifdef IS_ENTITY
uniform vec4 entityColor; // red hit flash
uniform int entityId;
#endif

in vec2 texcoord;
in vec2 lmcoord;
in vec3 worldPos;
in vec4 glcolor;
in float fogDist;
in float shade;
flat in vec3 frameAmb;
flat in vec3 frameFog;
flat in float frameDay;
flat in vec4 frameFlick;
flat in vec4 heldGlow;

void main() {
    vec4 tex = texture(gtexture, texcoord);
    vec4 c = tex * glcolor;
#ifndef IS_PARTICLE
    if (c.a < 0.1) discard;
#endif

#ifdef IS_ENTITY
#ifdef LIGHTNING_BOLT
    if (entityId == 1000) discard; // the procedural bolt replaces the vanilla one (lib/bolt.glsl)
#endif
    c.rgb = mix(c.rgb, entityColor.rgb, entityColor.a);
#endif

#ifdef IS_PARTICLE
    // rain splashes: blue either by vertex color or by the texture itself (depends on the game version)
    // purple particles (portal break) are also bluer than red and green, but their red is clearly above green: splashes have no such thing
    // red vs green is judged relative to brightness: the enchantment glint (purple, gray texture * color)
    // passed an absolute threshold in dim pixels and was drawn as yellow dots of the light color
    vec3 cn = c.rgb / max(max(c.r, max(c.g, c.b)), 0.001);
    vec3 gn = glcolor.rgb / max(max(glcolor.r, max(glcolor.g, glcolor.b)), 0.001);
    float splash = step(0.08, c.b - max(c.r, c.g)) * step(cn.r - cn.g, 0.1);
    splash = max(splash, step(0.08, glcolor.b - max(glcolor.r, glcolor.g)) * step(gn.r - gn.g, 0.1));

    // the splash texture has binary alpha and the particle layer is drawn without blending,
    // so thinness is driven by the texture shade (light pixels are removed first),
    // and transparency by random pixel rejection
    float cover = clamp(1.0 - tex.r * 2.0, 0.0, 1.0);
    float sa = clamp(pow(cover, 1.0 + RAIN_THINNESS * 3.0) * c.a * RAIN_OPACITY, 0.0, 1.0);
    float rnd = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453);

    // rejection before lighting: discarded pixels do not need it
    if (splash > 0.5) {
        if (sa < 0.01 || rnd > sa) discard;
        c.a = 1.0;
    } else if (c.a < 0.1) {
        discard;
    }
#endif

#if defined(END) && defined(IS_PARTICLE)
    // the End sky cube goes through this same pass with a leftover lightmap from the previous draw:
    // fire flicker showed on the sky. In the End it is disabled for particles and the sky
    float flick = 1.0;
#else
    float flick = getFlicker(worldPos, frameFlick);
#endif
    vec3 light = getLight(lmcoord, frameAmb, frameDay, flick) + heldLight(worldPos) + oreLightAt(worldPos);

#ifdef IS_PARTICLE
    c.rgb = splash > 0.5 ? min(light, vec3(1.0)) * RAIN_BRIGHTNESS : c.rgb * light;
#else
    vec3 albedo = c.rgb;
    c.rgb *= light * shade;

#ifdef HELD_LIGHT
    // the glowing item itself (torch etc.) glows entirely, bright spots (flame) glow stronger
    vec4 glow = heldGlow;
#ifdef IS_HAND
    // which hand is drawn: in view space the right (main) hand has x > 0
    vec3 rel = (worldPos - eyePosition) * mat3(gbufferModelViewInverse);
    glow = rel.x > 0.0 ? heldHandInfo(heldItemId, heldBlockLightValue) : heldHandInfo(heldItemId2, heldBlockLightValue2);
#endif
    if (glow.w > 0.5) {
        float lum = dot(albedo, vec3(0.299, 0.587, 0.114));
        c.rgb = max(c.rgb, albedo * mix(vec3(1.0), glow.rgb, 0.35) * (0.85 + 0.9 * lum) * HELD_LIGHT_STRENGTH);
    }
#endif
#endif

    if (isEyeInWater == 0) {
        float fogAmt = getFogAmount(fogDist, FOG_FAR);
        c.rgb = mix(c.rgb, frameFog, fogAmt) + getFogGlow(fogAmt, fogDist, lmcoord.x, flick);
    } else if (isEyeInWater == 1) {
        c.rgb = underwaterFog(c.rgb, fogDist, sunAngle);
    }

    gl_FragData[0] = c;
#ifdef IS_PARTICLE
    // particles in front of water (smoke) are accumulated into colortex7 like rain: composite puts them back over the water murk
    gl_FragData[1] = vec4(c.rgb * c.a, c.a);
#endif
#ifdef IS_ENTITY
    // mask of glowing entities for composite: water murk does not dim them (colortex6)
    gl_FragData[1] = vec4(entityId == 1001 ? 1.0 : 0.0, 0.0, 0.0, 1.0);
#endif
}
