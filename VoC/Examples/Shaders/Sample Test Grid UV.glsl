#version 420

// original https://www.shadertoy.com/view/ts3fzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define GRID 8.
#define STRIPS 6.
#define SPEED 5.
#define ANTI 3.

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2. - resolution.xy) / resolution.y;
    vec2 ouv = uv;
    uv = fract(uv * GRID);
    ouv = floor(ouv * GRID) / GRID;

    float r = length(uv - .5) + .5;
    vec3 col = vec3(0.);

    float d = sin(STRIPS * atan(ouv.y, ouv.x) - SPEED * time);
    d = (d + 1.) * .5;

    float aw = ANTI * GRID / resolution.y * .5;
    vec3 stripColor = smoothstep(r - aw, r + aw, 1. - d) * vec3(1., .0, .0);
    vec3 restColor = smoothstep(r - aw, r + aw, d) * vec3(1.);

    col += mix(stripColor, restColor, d);
    
    glFragColor = vec4(pow(col, vec3(.454545)), 1.);
}
