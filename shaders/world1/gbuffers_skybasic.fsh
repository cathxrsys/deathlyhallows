#version 330 compatibility

#define END
#include "/lib/sky.glsl"

uniform float viewWidth;
uniform float viewHeight;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

flat in float skyMul;
flat in vec3 skyTint;
flat in vec3 skyTw;
flat in float skyFlash;

/* RENDERTARGETS: 0 */

void main() {
    vec4 p = gbufferProjectionInverse * vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight) * 2.0 - 1.0, 1.0, 1.0);
    vec3 dir = mat3(gbufferModelViewInverse) * normalize(p.xyz / p.w);

    float h = clamp(dir.y, 0.0, 1.0);
    gl_FragData[0] = vec4(getSkyColor(h, skyMul, skyTint, skyTw, skyFlash) + dither8(gl_FragCoord.xy), 1.0);
}