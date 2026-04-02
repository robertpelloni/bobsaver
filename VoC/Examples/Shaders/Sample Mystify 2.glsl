#version 420

// original https://www.shadertoy.com/view/Nlc3WH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float colors = 8.; // number of distinct colors
const float repeat = 4.; // number of lines per color
const float offset = 20.; // distance between lines
const float framerate = 15.; // emulated framerate
const float dx0 = .8; // trajectory
const float dx1 = .4; // trajectory
        
const vec2 d0 = vec2(dx0, sqrt(1. - dx0 * dx0)) * offset;
const vec2 d1 = vec2(dx1, sqrt(1. - dx1 * dx1)) * offset;

float line(vec2 p0, vec2 p1, vec2 coord) {
    float proj = clamp(dot(coord - p0, p1 - p0) / dot(p1 - p0, p1 - p0), 0., 1.);
    float dist = length(coord - mix(p0, p1, proj));
    return clamp(1.5 - dist, 0., 1.);
}

vec3 colorize(float time) {
    vec3 color = floor(time / repeat) / colors + vec3(0., .33, .67);
    return clamp(abs(mod(color, 1.) * 3. - 1.5) - .25, 0., 1.);
}

vec2 triangle(vec2 offset) {
    return abs(mod(offset, 2. * resolution.xy) - resolution.xy);
}

vec3 render(float time, vec2 coord) {
    vec2 p0 = triangle(d0 * time);
    vec2 p1 = triangle(d1 * time);
    return line(p0, p1, coord) * colorize(time);
}

void main(void) {
    float time = floor(time * framerate);
    vec3 color = vec3(0.);
    color = max(color, render(time + 0., gl_FragCoord.xy));
    color = max(color, render(time + 1., gl_FragCoord.xy));
    color = max(color, render(time + 2., gl_FragCoord.xy));
    color = max(color, render(time + 3., gl_FragCoord.xy));
    color = max(color, render(time + 4., gl_FragCoord.xy));
    color = max(color, render(time + 5., gl_FragCoord.xy));
    color = max(color, render(time + 6., gl_FragCoord.xy));
    color = max(color, render(time + 7., gl_FragCoord.xy));
    glFragColor = vec4(color, 1.);
}
