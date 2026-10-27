#version 330 compatibility

#include "/lib/sky.glsl"

// Looking into water from above: the thicker the water layer between the surface and what lies behind it,
// the denser the murk; at depth the bottom is no longer visible. Thickness = depth difference with and without water.

uniform sampler2D colortex0;
uniform sampler2D colortex4; // water mask from gbuffers_terrain
uniform sampler2D colortex5; // water surface color
uniform sampler2D colortex6; // glowing entity mask from gbuffers_entities
uniform sampler2D colortex7; // rain/snow from gbuffers_weather (color * alpha, coverage)
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjectionInverse;
uniform float sunAngle;
uniform float far;
uniform int isEyeInWater;

in vec2 texcoord;

/* RENDERTARGETS: 0 */

float viewDist(vec2 uv, float depth) {
    vec4 p = gbufferProjectionInverse * vec4(uv * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    return length(p.xyz / p.w);
}

void main() {
    vec3 col = texture(colortex0, texcoord).rgb;

    vec4 waterInfo = texture(colortex4, texcoord);
    float mask = waterInfo.r;

    if (isEyeInWater == 0 && mask > 0.5) {
        float d0 = texture(depthtex0, texcoord).r;
        float d1 = texture(depthtex1, texcoord).r;
        float thickness = d1 >= 1.0 ? 64.0 : min(viewDist(texcoord, d1) - viewDist(texcoord, d0), 64.0);
        float murk = 1.0 - exp(-max(thickness, 0.0) * UNDERWATER_DENSITY);
        // near the horizon regular fog already covers the water (gbuffers_terrain): dim the murk by the same factor
        float horizon = 1.0 - getFogAmount(viewDist(texcoord, d0), far);
        murk *= horizon;
        // glowing entities (glow squid) are visible through water: murk and the surface pattern are weaker on them but do not vanish
        float glow = texture(colortex6, texcoord).r;
        glow *= 0.6 * (1.0 - murk); // the glow eats a share of the murk, less so the thicker the water: a far squid gets murky like everything else
        murk *= 1.0 - glow;
        // murk does not glow by itself: in a dark cave (waterInfo.g ~ 0) it is black, not gray
        col = mix(col, getWaterMurk(sunAngle) * waterInfo.g, murk);
        // murk eats the surface pattern: bring back some of the water's own color
        vec3 surface = texture(colortex5, texcoord).rgb;
        float pattern = WATER_PATTERN * horizon * (1.0 - glow);
        col = mix(col, surface, pattern);
        // rain over a river hangs in front of the water, but murk and pattern ate it together with the pixel:
        // restore exactly the share they covered (otherwise drops near a torch above water look dark)
        vec4 rain = texture(colortex7, texcoord);
        float lost = 1.0 - (1.0 - murk) * (1.0 - pattern);
        col = col * (1.0 - rain.a * lost) + rain.rgb * lost;
    }

    gl_FragData[0] = vec4(col, 1.0);
}
