#version 420

// original https://neort.io/art/bqnulcc3p9f48fkir7dg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718

float shape(vec2 p,float ra){
    float at = atan(p.x,p.y);
    float ar = TWO_PI/2.0;
    float d = cos(floor(0.5 + at/ar) * ar - at) * length(p);
    float r = length(p)/ra;
    float a = atan(length(p)) - time * 5.0;
    return abs(tan(r + a - d));
}

mat2 rotate(float r) {
    float c = cos(r);
    float s = sin(r);
    return mat2( c, -s, s, c);
}

float shape_wave(vec2 st, float n){
    return shape(st, dot(cos(length(vec2(n))),0.5));
}

void main() {
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec2 st2 = st;
    st *= rotate(time * 0.2);
    st2 *= rotate(-time * 0.2);

    vec3 color = vec3(1.0);
    for(int i=0; i<8; ++i) {
      st = abs(st/dot(st,st)*2.0);
      st -= 0.9 - cos(time * 0.2) * 0.5;
    }
    for(int i=0; i<8; ++i) {
      st2 = abs(st2/dot(st2,st2));
      st2 -= 0.9 - cos(time * 0.5) * 0.5;
    }

    st *= rotate(time);
    color.r *= shape_wave(st, 2.0);
    color.g -= length(st)-0.5;
    color *= st2.xxy;

    glFragColor = vec4(color, 1.0);
}
