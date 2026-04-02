#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float pi = 3.14159265358979;
const float pi2 = pi * 2.0;

vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

mat2 rot(float a){
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

vec2 pmod(vec2 p, float r){
    float a = atan(p.x, p.y) + pi / r;
    float n = pi2 / r;
    a = floor(a / n) * n;
    return p * rot(-a);
}

float map(vec3 p){
    p = vec3(p.xy * rot(time) + vec2(time * 2.0, sin(time) * 2.0), p.z);
    p = mod(p, 3.0) - 3.0 * 0.5;
    return length(p) - 1.0;
}

void main( void ) {

    vec2 st = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 cameraPos = vec3(0.0, 0.0, -5.0);
    vec3 lightDir = vec3(0.0, -1.0, -1.0);
    vec3 lightCol = vec3(1.0, 1.0, 1.0);
    float screenZ = 2.5;
    vec3 ro = vec3(0.0, 0.0, time * 4.0);
    vec3 rd = normalize(vec3(st, 1.0));
    float ac = 0.0;
    float t = 0.0;
    float step = 0.0;
    vec3 p = ro;
    
    float depth = 0.0;
    vec3 col = vec3(0.0);
    
    for(int i=0;i<99;i++){
        float d = max(abs(map(p)), 0.01);
        if(abs(d) < 0.001){
            break;
        }
        t += d * 0.5;
        p = ro + rd * t;
        step = float(i);
        ac += exp(-d * 3.0);
    }
    
    glFragColor = vec4(hsv(p.z * 0.01 + time * 0.1, 1.0, 1.0) * vec3(0.01 * ac + 0.001 * step), 1.0);

}
