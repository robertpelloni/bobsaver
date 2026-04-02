#version 420

//original https://neort.io/art/bqgps5s3p9fdlitdaqpg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.14159265359
#define TWO_PI 6.28318530718

float shape(vec2 p,float radius, float pt){

    float at = atan(p.x,p.y) + time * 0.2 + PI;
    float ar = TWO_PI/pt;
    float d = cos(floor(0.5 + at/ar) * ar - at) * length(p);
    float r = length(p) * radius;
    float a = atan(length(p)) + time * 5.0;
    return abs(tan(r + a - d));
}

float wave(float n) {
    return dot(cos(length(vec2(n))),2.0);
}

float shape_wave(vec2 st, float n){
    return shape(st, wave(n), n);
}

void main() {
    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(1.0);
    color -= shape_wave(st * 100.0, 8.0);
    color.b *= shape_wave(st * 5.0, 10.0);
    color.gb *= abs(st.y);
    color.b *= dot(st.x,st.y);

    glFragColor = vec4(color, 1.0);
}
