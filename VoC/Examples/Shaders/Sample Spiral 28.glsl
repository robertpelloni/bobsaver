#version 420

// original https://www.shadertoy.com/view/3lGXDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float n21 (vec2 p) {
    return fract(sin(p.x*124.43 + p.y*5432.)*44433.);
}

vec3 getColorByIndex(float id) {
    float n = n21(vec2(id));
    vec3 color = vec3(sin(n+time), fract(n*10.23), fract(n*453.223));
    return color;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= .5;
    uv.x *= resolution.x / resolution.y;

    float circles = 8.;
    float swirl = 2.;

    float a = atan(uv.x, uv.y) / 6.28 + .5;

    float len = length(uv);

    float d = len + time*0.1 + a/circles * swirl;

    float nd = d * circles;

    float id = floor(nd);
    float df = fract(nd);

    vec3 color = getColorByIndex(id);
    vec3 color1 = getColorByIndex(id + swirl);

    color = mix(color, color1, 1. - a);

    glFragColor = vec4(color, 1.);

}
