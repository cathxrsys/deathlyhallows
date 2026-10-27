#version 330 compatibility

#include "/lib/sky.glsl"
#ifdef LIGHTNING_BOLT
#include "/lib/bolt.glsl"
#endif

uniform float sunAngle;

// per-frame sky values, see sky.glsl
flat out float skyMul;
flat out vec3 skyTint;
flat out vec3 skyTw;
flat out float skyFlash;
#ifdef LIGHTNING_BOLT
flat out vec4 boltA;
flat out vec4 boltB;
#endif

void main() {
    gl_Position = ftransform();

    skyMul   = getSkyMul(sunAngle);
    skyTint  = getTwilightTint(sunAngle);
    skyTw    = getTwilightBase(sunAngle);
    skyFlash = getFlash();
#ifdef LIGHTNING_BOLT
    boltA = vec4(0.0);
    boltB = vec4(0.0);
    if (boltOn > 0.5) getBoltParams(boltA, boltB);
#endif
}
