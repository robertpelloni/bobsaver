#version 420

// original https://neort.io/art/bqmm64k3p9f48fkiqu60

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718

float shape(vec2 p,float ra){
    float at = atan(p.x,p.y);
    float ar = TWO_PI/3.0;
    float d = cos(floor(0.5 + at/ar) * ar - at) * length(p);
    float r = length(p)/ra;
    float a = atan(length(p)) - time * 5.0;
    return abs(tan(r + a - d));
}

float shape_wave(vec2 st, float n){
    return shape(st, dot(cos(length(vec2(n))),0.5));
}

void main() {
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

    float t = mod(time, 3.0);
    vec3 color = vec3(1.0);
    for(int i=0; i<4; ++i) {
      st = abs(st/dot(st,st));
      st -= 0.9 - cos(time * 0.5) * 0.3;
    }
    color.rg *= shape_wave(st, 0.5);

    color -= fract(length(st)-0.5);
    color *= vec3(0.5,0.2,1.0);

    glFragColor = vec4(color, 1.0);
}
