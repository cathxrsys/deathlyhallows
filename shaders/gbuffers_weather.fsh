#version 430 compatibility

#include "/lib/sky.glsl"
#include "/lib/held_light.glsl"

uniform sampler2D gtexture;

in vec2 texcoord;
in vec2 lmcoord;
in vec4 glcolor;
in vec3 worldPos;
flat in vec3 frameAmb;
flat in float frameDay;
flat in vec4 frameFlick;

/* RENDERTARGETS: 0,7 */

void main() {
    float a = pow(texture(gtexture, texcoord).a, 1.0 + RAIN_THINNESS * 3.0) * glcolor.a * RAIN_OPACITY;
    // lit flakes get at most 3x denser (1 + 2 * fire below): if it falls short of the threshold anyway,
    // discard the pixel right away without lighting (most pixels of the rain texture are transparent)
    if (a * 3.0 < 0.01) discard;

    // vanilla mixes bright light into snow ((3 * light + max) / 4), so lmcoord.x on snow is never below ~0.25:
    // 0.3..0.9 cuts off this background and keeps only real block light near a campfire, torch etc.
    float fire = smoothstep(0.3, 0.9, lmcoord.x);
    // dynamic light of held items (torch etc.), as on blocks
    vec3 held = heldLight(worldPos);
    fire = max(fire, clamp(max(held.r, max(held.g, held.b)) * 1.5, 0.0, 1.0));

    // lit flakes are denser: with the overall weather transparency they would otherwise get lost against lit ground
    a = clamp(a * (1.0 + 2.0 * fire), 0.0, 1.0);
    if (a < 0.01) discard;

    // color = light at this point: yellow near a campfire, almost black in the dark
    float flick = getFlicker(worldPos, frameFlick);
    vec3 light = getLight(lmcoord, frameAmb, frameDay, flick);
    // near a source flakes glow on their own rather than just reflect weak light (otherwise barely visible at night after min(.., 1))
    light += BLOCK_LIGHT * fire * fire * 0.8 * flick + held * 2.0;

    // a per-channel min(light, 1) would clip red and green to 1 and orange would drift to yellow-green:
    // on overexposure divide by the max channel to preserve the hue
    light /= max(max(light.r, max(light.g, light.b)), 1.0);

    // gray drops instead of white: they stay bright near a light source
    light *= mix(RAIN_BRIGHTNESS, 1.0, fire);

    gl_FragData[0] = vec4(light, a);
    // copy for composite: water murk covers the whole pixel, and composite puts rain over the river back on top of it
    gl_FragData[1] = vec4(light * a, a);
}
