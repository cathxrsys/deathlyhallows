#version 330 compatibility

// enchantment glint: the vanilla texture with vertex color, no lighting and no fog
// (otherwise without its own file Iris sends the glint to gbuffers_textured, where it is discarded like rain splashes)
uniform sampler2D gtexture;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0 */

void main() {
    gl_FragData[0] = texture(gtexture, texcoord) * glcolor;
}
