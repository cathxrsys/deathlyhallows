#include "/lib/sky.glsl"

// Mob eyes (enderman, spiders etc.): glow on their own regardless of lighting, like ores

uniform sampler2D gtexture;
uniform float far;
uniform int isEyeInWater;
uniform float sunAngle;

in vec2 texcoord;
in vec4 glcolor;
in float fogDist;
flat in vec3 frameFog;

/* RENDERTARGETS: 0 */

void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if (c.a < 0.1) discard;

#ifdef MOB_EYES
    // the farther the eyes, the dimmer: up close texture x (1 + MOB_EYES_GLOW), at MOB_EYES_FADE_DIST x MOB_EYES_FAR_GLOW
    // (below 1 - darker than the texture itself)
    c.rgb *= mix(1.0 + MOB_EYES_GLOW, MOB_EYES_FAR_GLOW, smoothstep(4.0, float(MOB_EYES_FADE_DIST), fogDist));
#endif

    if (isEyeInWater == 0) {
        c.rgb = mix(c.rgb, frameFog, getFogAmount(fogDist, far));
    } else if (isEyeInWater == 1) {
        c.rgb = underwaterFog(c.rgb, fogDist, sunAngle);
    }

    gl_FragData[0] = c;
}
