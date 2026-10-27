#ifdef HELD_LIGHT
const int HELD_MAX = 16;
const int HELD_SLOTS = HELD_MAX + 2; // + the player's two hands
// Glowing items held by other entities, lying on the ground and in item frames.
// acc* is written this frame (entity vertex shader, position + item id),
// lat* are ready-made sources for fragment shaders (prepare.csh moves acc -> lat of the previous frame
// and adds the player's hands in slots 0 and 1): color, strength and flicker are computed once per frame.
layout(std430, binding = 1) buffer HeldBuf {
    uint accCount;
    uint latCount;
    uint pad0;
    uint pad1;
    vec4 acc[16];
    vec4 latPos[18]; // xyz - position, w - radius (0 = no source)
    vec4 latCol[18]; // rgb - color * strength * flicker
} heldBuf;
#endif
