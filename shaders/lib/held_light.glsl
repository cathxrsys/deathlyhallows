#include "/lib/held_items.glsl"
#include "/lib/held_buf.glsl"

uniform int heldItemId;
uniform int heldItemId2;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform vec3 eyePosition;
uniform mat4 gbufferModelViewInverse;

// Fire (torches, lanterns, campfires, lava bucket) flickers like block light; glowstone and froglights are steady.
// s = getFlickerWave
float heldFlicker(int id, vec3 p, vec4 s) {
    return (id == 20001 || id == 20002 || id == 20007) ? getFlicker(p, s) : 1.0;
}

// Item in the player's hand: color from the table, for unknown items (mods) the level comes from the game
vec4 heldHandInfo(int id, int level) {
    vec4 info = heldItemInfo(id);
    if (info.w < 0.5 && level > 0) info = vec4(1.00, 0.62, 0.30, float(level));
    return info;
}

// Dynamic light from glowing items: in hands of the player and other entities, on the ground.
// Sources with color, strength and flicker are prepared by prepare.csh (lib/prepare.glsl)
vec3 heldLight(vec3 worldPos) {
#ifdef HELD_LIGHT
    vec3 sum = vec3(0.0);
    int n = int(min(heldBuf.latCount, uint(HELD_SLOTS)));
    for (int i = 0; i < n; i++) {
        vec4 l = heldBuf.latPos[i];
        float d = distance(worldPos, l.xyz);
        if (d >= l.w) continue; // zero light beyond the radius (an empty slot has radius 0)
        float a = 1.0 - d / l.w;
        // slightly dimmed right at the source to avoid blowing out to white, but a nearby wall must still be lit
        float near = mix(0.65, 1.0, smoothstep(0.0, 1.5, d));
        // soft falloff (closer to linear)
        sum = max(sum, heldBuf.latCol[i].rgb * (a * (0.4 + 0.6 * a) * near));
    }
    return sum * HELD_LIGHT_STRENGTH;
#else
    return vec3(0.0);
#endif
}
