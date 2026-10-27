#version 430 compatibility

// block breaking cracks: vanilla blends them as 2 * src * dst, so no lighting and no tinting,
// otherwise warm light paints the cracks orange
uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0 */

void main() {
    vec4 c = texture(gtexture, texcoord) * glcolor;
    if (c.a < 0.1) discard;
    gl_FragData[0] = c;
}
