#include "/lib/sky.glsl"
#include "/lib/portal_buf.glsl"
#include "/lib/ore_buf.glsl"
#include "/lib/frame_buf.glsl"

in vec4 mc_Entity;
in vec2 mc_midTexCoord;
in vec4 at_midBlock; // vertex to block center, in 1/64 block (Iris)

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float thunderStrength;
uniform int frameCounter;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out float fogDist;
out vec3 worldPos;
out vec3 worldNormal;
out vec3 tintColor; // glcolor.rgb raised to a time-of-day dependent power
flat out vec3 frameAmb; // per-frame sky values, see frame_buf.glsl
flat out vec3 frameFog;
flat out float frameDay;
flat out vec4 frameFlick;
flat out int matId;

#ifdef SWAY
// blend 0 = calm, 1 = storm: faster and gustier.
// Waves are blended instead of speeding up time, otherwise the phase jumps when rain starts.
float swayWave(float t, float phase, float blend) {
    float calm = sin(t + phase);
    if (blend <= 0.0) return calm; // calm: no gusts needed
    float sp   = 1.0 + 1.5 * STORM_SWAY;
    float gust = sin(t * sp + phase) + 0.4 * sin(t * sp * 2.3 + phase * 1.7);
    return mix(calm, gust, blend);
}
#endif

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = clamp(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) / 0.9375, 0.0, 1.0);
    glcolor  = gl_Color;
    matId    = int(mc_Entity.x + 0.5);

    frameAmb = frameBuf.amb.rgb;
    frameFog = frameBuf.fog.rgb;
    frameDay = frameBuf.amb.w;
    frameFlick = frameBuf.flick;
    // by day boost the contrast of block faces and corners (vanilla AO) to avoid a flat look
    tintColor = pow(gl_Color.rgb, vec3(1.0 + 0.5 * DAY_GLOOM * frameDay));

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec3 feet = (gbufferModelViewInverse * viewPos).xyz;
    worldPos = feet + cameraPosition;
    worldNormal = mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);

#ifdef PORTAL_LIGHT
    // the portal submits its block center (the one nearest to the camera wins) and its vertices to the buffer
    if (matId == 10022) {
        vec3 mid = feet + at_midBlock.xyz / 64.0;
        float d = length(mid);
        if (d < 48.0) atomicMin(portalBuf.accKey, portalKey(d, ivec3(floor(mid + cameraPosition))));
        // portal center: average the vertices around the previous light point
        if (portalBuf.latPos.w > 0.5) {
            vec3 off = worldPos - portalBuf.latPos.xyz;
            if (length(off) < PORTAL_CLUSTER) {
                ivec3 q = ivec3(round(off * PORTAL_FIX));
                atomicAdd(portalBuf.sumX, q.x);
                atomicAdd(portalBuf.sumY, q.y);
                atomicAdd(portalBuf.sumZ, q.z);
                atomicAdd(portalBuf.cnt, 1);
            }
        }
    }
#endif

#ifdef ORE_LIGHT
    // ore light grid (lib/ore_buf.glsl): full cubes mark themselves as obstacles,
    // an exposed ore face marks the air in front of it as a light source
    {
        ivec3 base = oreBase(cameraPosition);
        uint stamp = uint(frameCounter) + 1u;
        ivec3 block = ivec3(floor(worldPos + at_midBlock.xyz / 64.0));
        if (oreInReach(block, cameraPosition)) {
            // for a full cube every vertex offset to the block center is 0.5 (not for slabs, plants, torches, rails and water)
            vec3 mid = abs(at_midBlock.xyz);
            if (matId != 10030 && all(greaterThan(mid, vec3(31.5))) && all(lessThan(mid, vec3(32.5))) && oreInGrid(block, base)) {
                oreBuf.occ[oreCell(block)] = stamp;
            }
            int ore = oreType(matId);
            if (ore >= 0) {
                vec3 n = worldNormal;
                vec3 an = abs(n);
                ivec3 dir = an.x >= an.y && an.x >= an.z ? ivec3(sign(n.x), 0, 0)
                          : an.y >= an.z               ? ivec3(0, sign(n.y), 0)
                          :                              ivec3(0, 0, sign(n.z));
                ivec3 front = block + dir;
                if (oreInGrid(front, base)) oreBuf.emit[oreCell(front)] = (stamp << 4) | uint(ore);
            }
        }
    }
#endif

#ifdef SWAY
    float isLeaves = float(matId == 10001);
    // top vertex of the quad: regular plants sway only with it,
    // for two-block plants the lower half sways by 0.5 and the upper from 0.5 to 1.0 (no seam gap)
    float isTopVert = float(gl_MultiTexCoord0.t < mc_midTexCoord.t);
    float isPlant   = float(matId == 10002) * isTopVert
                    + float(matId == 10003) * isTopVert * 0.5
                    + float(matId == 10004) * (0.5 + 0.5 * isTopVert);

    float storm = rainStrength + thunderStrength * 0.5; // 0 .. 1.5
    float blend = clamp(storm, 0.0, 1.0);

    float amount = (isLeaves * 0.05 + isPlant * 0.08) * SWAY_STRENGTH;
    amount *= 1.0 + storm * 1.2 * STORM_SWAY;

    if (amount > 0.0) {
        float t = frameTimeCounter * 0.8 * SWAY_SPEED;
        float phase = worldPos.x * 0.35 + worldPos.z * 0.25;
        feet.x += swayWave(t, phase, blend) * amount;
        feet.z += swayWave(t * 0.8, phase * 1.3 + 1.5708, blend) * amount * 0.7;
        // the shifted leaf faces are coplanar with the faces of neighbouring logs (z-fighting): inflate the cube slightly,
        // so the leaf always lies above the log face instead of flickering through it
        feet -= at_midBlock.xyz / 64.0 * (isLeaves * 0.04);
    }
#endif

    viewPos = gbufferModelView * vec4(feet, 1.0);
    gl_Position = gl_ProjectionMatrix * viewPos;
    fogDist = length(viewPos.xyz);
}
