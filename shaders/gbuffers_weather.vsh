#version 430 compatibility
#include "/lib/sky.glsl"
#include "/lib/frame_buf.glsl"

uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 worldPos;
flat out vec3 frameAmb;
flat out float frameDay;
flat out vec4 frameFlick;

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord  = clamp(((gl_TextureMatrix[1] * gl_MultiTexCoord1).xy - 0.03125) / 0.9375, 0.0, 1.0);
    glcolor  = gl_Color;
    frameAmb = frameBuf.amb.rgb;
    frameDay = frameBuf.amb.w;
    frameFlick = frameBuf.flick;
    worldPos = (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz + cameraPosition;
    gl_Position = ftransform();
}