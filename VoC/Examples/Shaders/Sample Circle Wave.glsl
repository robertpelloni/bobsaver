#version 420

// original https://neort.io/art/bqen23c3p9fdlitda37g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718

float shape(vec2 p,float radius, float pt){

    float at = atan(p.x,p.y) + time * 0.5 + PI;
    float ar = TWO_PI/pt;
    float d = cos(floor(0.5 + at/ar) * ar - at) * length(p);

    float r = length(p) * radius;
    float a = atan(length(p)) + time * 2.0;
    return abs(tan(r + a - d));
}

float wave(float n) {
    float d = length(vec2(n));
    return dot(cos(d),2.0);
}

float shape_wave(vec2 st, float n){
    return shape(st * 0.5, wave(n), n);
}

void main() {
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    float sec = sin(time) + cos(time) + length(st);
    vec3 color = vec3(1.0);
    color -= shape_wave(st * 2.0, sec + 30.0);
    color -= shape_wave(st * 20.0, sec - 20.0);
    color.b *= st.y;
    color.rb *= -st.y;
    color *= vec3(0.8,0.5,0.5);

    glFragColor = vec4(color, 1.0);
}
