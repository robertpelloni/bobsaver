#version 420

// original https://www.shadertoy.com/view/ldGSWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

vec4 blend(vec4 c1, vec4 c2) {
    return vec4(mix(c1.rgb, c2.rgb, c2.a), max(c1.a, c2.a)); 
}

vec4 sky(vec2 uv) {
    return vec4(mix(vec3(.3, .6, 1.), vec3(.1, .3, .7), uv.y), 1);
}

vec4 hill(vec2 uv) {
    return vec4(mix(vec3(.0, .5, .2), vec3(.4, .8, .4), smoothstep(-.2, .3, uv.x + uv.y / 3.)),
        smoothstep(uv.y, uv.y + .005, cos(uv.x * 4.) * .2));
}

vec4 dune(vec2 uv) {
    return vec4(
        mix(vec3(.7, .5, .2), vec3(.9, .8, .5), smoothstep(-.2, .3, uv.x + uv.y / 3.)),
        smoothstep(uv.y, uv.y + .01, cos(uv.x * 4.) * .2));
}

vec4 overlay(vec2 uv) {
    uv = abs(uv);
    return vec4(vec3(0), step(.85, uv.y) + (1. - smoothstep(uv.x + .57, uv.x + .575, 1. - pow(cos(uv.y * 2.), 4.) / 2.5)));
}

float dunemask(vec2 uv) {
    if (uv.y > 0.) return 1.;
    float w = .03;
    float h = smoothstep(uv.y + .85, uv.y + .855, cos(uv.x * 7.) / 10.);
    uv.x += cos(uv.y * 10. + time * 10.) / 100. * abs(uv.y);
    return max(smoothstep(-w, -w + .005, uv.x) - smoothstep(w - .005, w, uv.x), h);
}

vec4 rect(vec2 uv) {
    uv = abs(uv);
    return vec4(vec3(.5), uv.x < 1. && uv.y < 1.);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2. - 1.;
    uv.x *= resolution.x / resolution.y;
    
    glFragColor = sky(uv);
    
    glFragColor = blend(glFragColor, hill(uv - vec2(-.2, -.75)));
    glFragColor = blend(glFragColor, hill(uv - vec2(.3, -.7)));
    
    vec4 d = dune(uv * 2. + vec2(0, -.9));
    d = blend(d, dune(uv * 2. + vec2(-.6, -.7)));
    d = blend(d, dune(uv * 2. + vec2(.5, -.7)));
    
    glFragColor = blend(glFragColor, vec4(d.rgb, min(d.a, dunemask(uv))));
    
    glFragColor = blend(glFragColor, overlay(uv));
    
    uv = abs(uv);
    glFragColor = blend(glFragColor, rect(uv * vec2(2.1, 40) - vec2(0, 37)));
}
