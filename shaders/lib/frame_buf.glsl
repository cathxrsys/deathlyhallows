// Per-frame sky values shared by all vertices: prepare.csh computes them once per frame,
// vertex shaders only read them (instead of evaluating getAmbient / getFogColor / getDay per vertex)
layout(std430, binding = 3) buffer FrameBuf {
    vec4 amb; // rgb = getAmbient, w = getDay
    vec4 fog; // rgb = getFogColor
    vec4 flick; // getFlickerWave: the time part of the fire flicker
} frameBuf;
