// Distant Horizons LODs (dh_terrain / dh_water): no texture, the vertex color is the averaged block color.
// Iris supplies dhMaterialId (DH_BLOCK_*), the lightmap in gl_MultiTexCoord1 and the face normal
#include "/lib/sky.glsl"
#include "/lib/frame_buf.glsl"

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

out vec2 lmcoord;
out vec4 glcolor;
out float fogDist;
out float cullDist;
out vec3 worldPos;
out vec3 worldNormal;
flat out vec3 frameAmb;
flat out vec3 frameFog;
flat out float frameDay;
flat out vec4 frameFlick;
flat out int matId;

void main() {
    lmcoord = clamp((gl_MultiTexCoord1.xy - 0.03125) / 0.9375, 0.0, 1.0);
    matId   = dhMaterialId;

    frameAmb = frameBuf.amb.rgb;
    frameFog = frameBuf.fog.rgb;
    frameDay = frameBuf.amb.w;
    frameFlick = frameBuf.flick;

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec3 feet = (gbufferModelViewInverse * viewPos).xyz;
    worldPos = feet + cameraPosition;
    worldNormal = mat3(gbufferModelViewInverse) * normalize(gl_NormalMatrix * gl_Normal);
    fogDist  = length(viewPos.xyz);
    cullDist = length(feet.xz);

    // vanilla bakes face shading into the vertex color, LODs do not: same factors, otherwise far hills look flat
    vec3 an = abs(worldNormal);
    float shade = worldNormal.y > 0.5 ? 1.0 : worldNormal.y < -0.5 ? 0.5 : an.x > an.z ? 0.6 : 0.8;
#ifdef NETHER
    if (an.y > 0.5) shade = 0.9; // the Nether has constant ambient light: top and bottom faces both at 0.9
#endif
    glcolor = vec4(gl_Color.rgb * shade, gl_Color.a);

    gl_Position = gl_ProjectionMatrix * viewPos;
}
