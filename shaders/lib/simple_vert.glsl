#include "/lib/sky.glsl"
#include "/lib/held_items.glsl"
#include "/lib/held_buf.glsl"
#include "/lib/frame_buf.glsl"

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

#if defined(IS_ENTITY) && defined(HELD_LIGHT)
uniform int currentRenderedItemId;

// A glowing item in an entity's hand, on the ground or in a frame submits its position to the buffer.
// Vertices of one item lie close together, so an already occupied nearby spot is skipped
void submitHeldLight(vec3 feet) {
    int id = currentRenderedItemId;
    if (heldItemInfo(id).w < 0.5 || length(feet) > 64.0) return;

    vec3 wp = feet + cameraPosition;
    uint n = min(heldBuf.accCount, uint(HELD_MAX));
    for (uint i = 0u; i < n; i++) {
        if (distance(heldBuf.acc[i].xyz, wp) < 1.0) {
            // a source is already nearby (e.g. a frame): the brighter of the two wins, otherwise the framed item is lost
            if (heldItemInfo(int(heldBuf.acc[i].w + 0.5)).w < heldItemInfo(id).w) heldBuf.acc[i] = vec4(wp, float(id));
            return;
        }
    }
    uint slot = atomicAdd(heldBuf.accCount, 1u);
    if (slot < uint(HELD_MAX)) heldBuf.acc[slot] = vec4(wp, float(id));
}
#endif

out vec2 texcoord;
out vec2 lmcoord;
out vec3 worldPos;
out vec4 glcolor;
out float fogDist;
out float shade;
flat out vec3 frameAmb; // per-frame sky values, see frame_buf.glsl
flat out vec3 frameFog;
flat out float frameDay;
flat out vec4 frameFlick;
flat out vec4 heldGlow; // glowing item being drawn right now (entities, on the ground): color + level

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = clamp(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) / 0.9375, 0.0, 1.0);
    glcolor  = gl_Color;

    // world-space normal -> top 1.0, sides 0.75, bottom 0.5
    vec3 n = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
    shade = 0.75 + 0.25 * n.y;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec3 feet = (gbufferModelViewInverse * viewPos).xyz;
    worldPos = feet + cameraPosition;
    heldGlow = vec4(0.0);
#if defined(IS_ENTITY) && defined(HELD_LIGHT)
    submitHeldLight(feet);
    heldGlow = heldItemInfo(currentRenderedItemId);
#endif
    gl_Position = gl_ProjectionMatrix * viewPos;
    fogDist = length(viewPos.xyz);

    frameAmb = frameBuf.amb.rgb;
    frameFog = frameBuf.fog.rgb;
    frameDay = frameBuf.amb.w;
    frameFlick = frameBuf.flick;
}
