#include "/lib/sky.glsl"

layout(local_size_x = 1) in;
const ivec3 workGroups = ivec3(1, 1, 1);

uniform vec3 cameraPosition;
uniform float sunAngle;

#include "/lib/portal_buf.glsl"
#include "/lib/held_light.glsl"
#include "/lib/frame_buf.glsl"

#ifdef HELD_LIGHT
// Source for heldLight: info - color and level (w < 0.5 - no light), k - strength with flicker.
// Only a weak dependence on level: weak sources are still clearly visible
void heldSlot(int i, vec3 center, vec4 info, float k) {
    if (info.w < 0.5) {
        heldBuf.latPos[i] = vec4(0.0);
        heldBuf.latCol[i] = vec4(0.0);
        return;
    }
    heldBuf.latPos[i] = vec4(center, info.w * HELD_LIGHT_RADIUS * 1.25);
    heldBuf.latCol[i] = vec4(info.rgb * (k * (0.7 + 0.3 * info.w / 15.0)), 0.0);
}
#endif

void main() {
    // per-frame sky values for vertex shaders (frame_buf.glsl)
    frameBuf.amb = vec4(getAmbient(sunAngle), getDay(sunAngle));
    frameBuf.fog = vec4(getFogColor(sunAngle), 0.0);
    vec4 flick = getFlickerWave();
    frameBuf.flick = flick;

#ifdef PORTAL_LIGHT
    uint key = portalBuf.accKey;
    int pn = portalBuf.cnt;
    vec4 pos = vec4(0.0);
    if (key != 0xFFFFFFFFu) {
        if (pn > 0 && portalBuf.latPos.w > 0.5) {
            // center of the portal vertices around the previous point
            vec3 sum = vec3(portalBuf.sumX, portalBuf.sumY, portalBuf.sumZ);
            pos = vec4(portalBuf.latPos.xyz + sum / (PORTAL_FIX * float(pn)), 1.0);
        } else {
            // no previous point, or no portal near it: take the nearest block
            pos = vec4(portalKeyPos(key, cameraPosition), 1.0);
        }
    }
    portalBuf.latKey = key;
    portalBuf.latPos = pos;
    portalBuf.accKey = 0xFFFFFFFFu;
    portalBuf.sumX = 0;
    portalBuf.sumY = 0;
    portalBuf.sumZ = 0;
    portalBuf.cnt = 0;
#endif
#ifdef HELD_LIGHT
    // the player's hands: in view space to the right / below / in front of the eyes (main on the right, off-hand on the left),
    // they turn with the camera, so the light sits where the item is on screen
    mat3 toWorld = mat3(gbufferModelViewInverse);
    vec3 handMain = eyePosition + toWorld * vec3( 0.40, -0.40, -0.60);
    vec3 handOff  = eyePosition + toWorld * vec3(-0.40, -0.40, -0.60);
    heldSlot(0, handMain, heldHandInfo(heldItemId, heldBlockLightValue), 0.7 * heldFlicker(heldItemId, handMain, flick));
    heldSlot(1, handOff, heldHandInfo(heldItemId2, heldBlockLightValue2), 0.7 * heldFlicker(heldItemId2, handOff, flick));

    uint n = min(heldBuf.accCount, uint(HELD_MAX));
    heldBuf.latCount = n + 2u;
    for (uint i = 0u; i < uint(HELD_MAX); i++) {
        vec4 l = heldBuf.acc[i];
        int id = int(l.w + 0.5);
        if (i < n) heldSlot(int(i) + 2, l.xyz, heldItemInfo(id), 3.0 * heldFlicker(id, l.xyz, flick));
        else       heldSlot(int(i) + 2, vec3(0.0), vec4(0.0), 0.0);
        heldBuf.acc[i] = vec4(0.0);
    }
    heldBuf.accCount = 0u;
#endif
}
