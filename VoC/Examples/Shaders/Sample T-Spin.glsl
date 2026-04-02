#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/ssyGRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28318530718
#define MINSCALE 0.01
#define SHAPECOUNT 8u

// returns vec2(mask, distanceFromCenter)
vec2 tshape(vec2 uv, float size, float angle) {
    vec2 uvRot = vec2(
        uv.x * sin(angle * TAU) + uv.y * cos(angle * TAU),
        uv.x * cos(angle * TAU) - uv.y * sin(angle * TAU)
    ) / size;
    
    float rectHriz = 1. - max(abs(uvRot.x) * 3., abs(uvRot.y));
    float rectVert = 1. - max(max(-uvRot.x, uvRot.x * 3.), abs(uvRot.y) * 3.);
    float value = max(rectHriz, rectVert);
    float mask = step(0.0, value);
    return vec2(mask, mask * (0.5 - value) * 2.);
}

float timeAdj(float time){
    return 0.25 * (smoothstep(0.0, 0.2, fract(4. * time)) + floor(4. * time));
}
vec3 hex(int hexcode){
    return vec3(
        (hexcode >> 16) & 255,
        (hexcode >> 8) & 255,
        hexcode & 255
    ) / 255.;
}
vec3 tcolor(vec2 md, float layer, float time) {
    vec3 color0Base  = hex(0x4a089a);
    vec3 color0Light = hex(0x7d3ecd);
    vec3 color1Base  = hex(0x9a2cC3);
    vec3 color1Light = hex(0xfc69f8);
    
    float mixFactor = step(fract(layer * -5.6), 0.3);
    
    vec3 colorBase  = mix(color0Base , color1Base , mixFactor);
    vec3 colorLight = mix(color0Light, color1Light, mixFactor);
    
    return mix(
        colorBase, colorLight, 1. + 0.5 * sin(TAU * fract(md.y + 2. * time))
    );
}

float fold(float x) {
    return abs(2. * fract(x) - 1.);
}

float grid(vec2 uv, float scale) {
    return max(fold(uv.x * scale), fold(uv.y * scale));
}

void main(void)
{
    float time = fract(time / 4.);
    // Scales coords so that the diagonals are all dist 1 from center
    float scale = length(resolution.xy);
    vec2 uv = (gl_FragCoord.xy / scale
    - (resolution.xy / scale / 2.)) * 2.;
    
    float dist = length(uv);
    
    vec2 t = vec2(0);
    uint i = 0u;
    float tScale = exp2(time) * MINSCALE;
    for (; i < SHAPECOUNT; i++) {
        t = tshape(
            uv,
            float(1u << i) * tScale,
            timeAdj(time + float(i) * -0.01)
        );
        if (t.x > 0.) {
            break;
        }
    }
    // Time varying pixel color
    vec3 col = tcolor(t, float(i) + time, time);
    float gridV = step(0.9, grid(uv, 12.0 * exp2(fract(time))));
    gridV = mix(gridV, step(0.9, grid(uv, 6.0 * exp2(fract(time)))), fract(time));
    col -= 0.1 * gridV;

    // Output to screen
    glFragColor = vec4(col, 1.0);
}
