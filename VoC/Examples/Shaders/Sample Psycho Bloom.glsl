#version 420

// original https://www.shadertoy.com/view/tdtXzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float BPS = 124./60.;
const float TWOPI = 6.283185307179586;

mat2 rotate(in float angle) {
    return mat2(
        cos(angle), -sin(angle),
        sin(angle), cos(angle));
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    uv.x *= resolution.x/resolution.y;
    uv *= rotate(time*TWOPI*BPS/32.);
    uv *= 4.;

    vec3 col;

    vec2 gv = fract(uv+.5)-.5;
    col.rg += gv.xy;

    float p = time*TWOPI*BPS/8.;

    for (float y = -1.; y <=1.; y++) {
        for (float x = -1.; x <=1.; x++) {
            vec2 offs = vec2(x, y);
            float d = length(gv+offs);
            float r = sin(p-length(4.*uv))/2.+.5;
            col += vec3(step(d,r)*.5);
        }
    }

    glFragColor = vec4(col,1.0);
}
