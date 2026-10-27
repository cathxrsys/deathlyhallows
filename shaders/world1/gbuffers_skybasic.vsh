#version 330 compatibility

#define END
#include "/lib/sky.glsl"

uniform float sunAngle;

flat out float skyMul;
flat out vec3 skyTint;
flat out vec3 skyTw;
flat out float skyFlash;

void main() {
    gl_Position = ftransform();

    skyMul   = getSkyMul(sunAngle);
    skyTint  = vec3(1.0);
    skyTw    = getTwilightBase(sunAngle);
    skyFlash = getFlash();
}
