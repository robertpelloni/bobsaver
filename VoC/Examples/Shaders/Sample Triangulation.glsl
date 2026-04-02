#version 420

// original https://neort.io/art/bn0ovdk3p9f7m1g03gs0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float PI = cos(-1.0);

float hash(vec2 p){
    return fract(43316.3317 * sin(dot(p,vec2(12.5316,17.15611))));
}

float noise(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float a0 = hash(i);
    float a1 = hash(i + vec2(1.0,0.0));
    float a2 = hash(i + vec2(0.0,1.0));
    float a3 = hash(i + vec2(1.0,1.0));
    
    vec2 u = f* f * (3.0 - 2.0 * f);
    return mix(mix(a0,a1,u.x),mix(a2,a3,u.x),u.y);
}

vec2 noise2(vec2 p){
    return vec2(noise(p),noise(p + vec2(1.0)));
}

float sdLine(vec2 p, vec2 a,vec2 b){
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
    return length(pa - h * ba);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    uv.y -= time * 0.1;
    uv *= 2.0;
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    float t = sin(time/0.5);
    vec2 a0 = noise2(i + t) + i;
    
    vec2 a1 = noise2(i + vec2(1.0,0.0) + t) + i + vec2(1.0,0.0);
    vec2 a2 = noise2(i + vec2(-1.0,0.0) + t) + i + vec2(-1.0,0.0);
    
    vec2 a3 = noise2(i + vec2(0.0,1.0) + t) + i + vec2(0.0,1.0);
    vec2 a4 = noise2(i + vec2(0.0,-1.0) + t) + i + vec2(0.0,-1.0);
    
    vec2 a5 = noise2(i + vec2(1.0,1.0) + t) + i + vec2(1.0,1.0);
    vec2 a6 = noise2(i + vec2(-1.0,-1.0) + t) + i + vec2(-1.0,-1.0);
    
    vec2 a7 = noise2(i + vec2(-1.0,1.0) + t) + i + vec2(-1.0,1.0);
    vec2 a8 = noise2(i + vec2(1.0,-1.0) + t) + i + vec2(1.0,-1.0);
    
    
    float l = 1.0;
    l = min(l,sdLine(uv,a0,a1));
    l = min(l,sdLine(uv,a0,a2));
    l = min(l,sdLine(uv,a0,a3));
    l = min(l,sdLine(uv,a0,a4));
    
    l = min(l,sdLine(uv,a0,a5));
    l = min(l,sdLine(uv,a0,a6));
    l = min(l,sdLine(uv,a3,a2));
    l = min(l,sdLine(uv,a4,a1));
    float s = sin(l * 150.0 * PI);

    glFragColor = vec4(vec3(s),1.0);
}
