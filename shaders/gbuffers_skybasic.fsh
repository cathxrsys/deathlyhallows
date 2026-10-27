#version 330 compatibility

#include "/lib/sky.glsl"
#include "/lib/bolt.glsl"
#ifdef CLOUDS
#include "/lib/clouds.glsl"
#endif

uniform float viewWidth;
uniform float sunAngle;
uniform int isEyeInWater;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

flat in float skyMul;
flat in vec3 skyTint;
flat in vec3 skyTw;
flat in float skyFlash;
#ifdef LIGHTNING_BOLT
flat in vec4 boltA;
flat in vec4 boltB;
#endif

/* RENDERTARGETS: 0 */

void main() {
    vec4 p = gbufferProjectionInverse * vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
    vec3 dir = mat3(gbufferModelViewInverse) * normalize(p.xyz / p.w);

    float h = clamp(dir.y, 0.0, 1.0);
    vec3 col = getSkyColor(h, skyMul, skyTint, skyTw, skyFlash);
#ifdef CLOUDS
    if (dir.y > 0.0) col = applyClouds(col, dir, skyMul, skyTint, skyTw, skyFlash);
#endif
#ifdef LIGHTNING_BOLT
    if (boltOn > 0.5 && dir.y > -0.05) {
        vec2 bolt = getBolt(dir, boltA, boltB);
        col += LIGHTNING_COLOR * (bolt.x * 2.5 + bolt.y) * min(skyFlash, 1.5);
    }
#endif
    if (isEyeInWater == 1) col = getUnderwaterFog(sunAngle);
    gl_FragData[0] = vec4(col + dither8(gl_FragCoord.xy), 1.0);
}