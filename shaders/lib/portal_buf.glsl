#ifdef PORTAL_LIGHT
// Portal light point: the center of all portal vertices near the previous point (does not jump between blocks).
// The nearest portal block (accKey) is only used to find the portal while there is no previous point.
// acc* is written this frame (terrain vertex shader),
// lat* is the previous frame's value, read by the fragment shader (prepare.csh moves acc -> lat).
// Key = distance to the camera (high 11 bits) | portal block & 127 per axis (low 21 bits):
// the position travels with the key in a single atomicMin, so there is no separate position write (and no race).
layout(std430, binding = 0) buffer PortalBuf {
    uint accKey;
    uint latKey;
    vec4 latPos;
    int sumX; // sum of vertex offsets from latPos in fixed point (PORTAL_FIX)
    int sumY;
    int sumZ;
    int cnt;
} portalBuf;

const float PORTAL_FIX = 256.0;
const float PORTAL_CLUSTER = 8.0; // vertices farther from the previous point are not part of the center

uint portalKey(float dist, ivec3 block) {
    ivec3 b = block & 127;
    return (uint(dist * 32.0) << 21) | uint(b.x | (b.y << 7) | (b.z << 14));
}

// Block from a key: the block nearest to the camera with the same coordinates & 127
vec3 portalKeyPos(uint key, vec3 camPos) {
    ivec3 b = ivec3(key, key >> 7, key >> 14) & 127;
    ivec3 c = ivec3(floor(camPos));
    ivec3 off = ((b - (c & 127) + 64) & 127) - 64;
    return vec3(c + off) + 0.5;
}
#endif
