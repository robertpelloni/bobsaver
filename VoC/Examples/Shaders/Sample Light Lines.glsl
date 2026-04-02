#version 420

// original https://www.shadertoy.com/view/NsS3z1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Reference
// SDF for raymarching, gaz : https://neort.io/product/bvcrf5s3p9f7gigeevf0
// フラグメントシェーダノイズ(Fragment Shader Noise), wgld.org : https://wgld.org/d/glsl/g007.html

#define PI acos(-1.)
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define TAU atan(1.)*8.

#define resolution resolution.xy
#define time time

const int   oct  = 1;
const float per  = 0.8;

float interpolate(float a, float b, float x){
    float f = (1.0 - cos(x * PI)) * 0.5;
    return a * (1.0 - f) + b * f;
}

float rnd(vec2 p){
    return fract(sin(dot(p ,vec2(12.9898,78.233))) * 43758.5453);
}

float irnd(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec4 v = vec4(rnd(vec2(i.x,       i.y      )),
                  rnd(vec2(i.x + 1.0, i.y      )),
                  rnd(vec2(i.x,       i.y + 1.0)),
                  rnd(vec2(i.x + 1.0, i.y + 1.0)));
    return interpolate(interpolate(v.x, v.y, f.x), interpolate(v.z, v.w, f.x), f.y);
}

float noise(vec2 p){
    float t = 0.0;
    for(int i = 0; i < oct; i++){
        float freq = pow(2.0, float(i));
        float amp  = pow(per, float(oct - i));
        t += irnd(vec2(p.x / freq, p.y / freq)) * amp;
    }
    return t;
}

float snoise(vec2 p, vec2 q, vec2 r){
    return noise(vec2(p.x,       p.y      )) *        q.x  *        q.y  +
           noise(vec2(p.x,       p.y + r.y)) *        q.x  * (1.0 - q.y) +
           noise(vec2(p.x + r.x, p.y      )) * (1.0 - q.x) *        q.y  +
           noise(vec2(p.x + r.x, p.y + r.y)) * (1.0 - q.x) * (1.0 - q.y);
}

vec2 pmod(vec2 p, float n) {
    float a=mod(atan(p.y, p.x), TAU/n)-.5*TAU/n;
    return length(p)*vec2(sin(a),cos(a));
}

vec3 hsv(float h, float s, float v) { return ((clamp(abs(fract(h+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v; }

float t;
vec3 c;

float map(vec3 p) {
    vec3 p_ = p;
    p.xz *= rot(sin(time*-0.1)*PI*-2.0);
    float h = noise(vec2(length(p)+time*0.2, (abs(atan(p.x, p.y))+abs(atan(p.y, p.z))+abs(atan(p.z, p.x))) * 2. + -time*3.0)) * 2.;
    h = length(p)+h-time*0.2;
    vec3 c1 = hsv(-0.2+sin(time*.3)*0.05 + fract(h) * (0.4 + sin(time)*0.1), 1., 1.);
    c1 += -pow(0.27 / length(p), 3.2);
    c1 += pow(0.14 / length(p)+.2, 9.2);
    float t1 = 1. - pow(length(p)*1.4, 5.0);
    t1 *= 1.5;
    h = noise(vec2(length(p)+time*0.2, (abs(atan(p.x, p.y))+abs(atan(p.y, p.z))+abs(atan(p.z, p.x))) * 2. + time*3.0)) * 6.;
    h = length(p)+h-time*0.2;
    p = p_;
    p.xz *= rot(-sin(time*-0.1)*PI*-2.0);
    p.xy *= rot(cos(time*0.2)*PI*4.0);
    p.yz *= rot(time*2.0);
    vec3 c2 = hsv(0.15+sin(time*.3)*0.05 + fract(h) * (0.6 + sin(time)*0.1), 1., 1.);
    c2 += p*0.3;
    float d1 = -.5 + length(p);
    p.xy = pmod(p.xy, 7.+sin(time)*2.0);
    p.zy = pmod(abs(p.zy), 9.+sin(PI*0.4+time*1.4)*4.);
    p.y -= 1.5;
    p.y -= clamp(p.y, -.3, .6);
    c2 *= clamp(pow(.1 / length(p.xz), 1.1), 0., 3.);
    c2 += pow(.05 / length(p.xz), 1.2);
    c2 = max(vec3(0.), c2);
    float t2 = 1. - pow(length(p), 0.3)*1.0;
    t2 *= .8;
    t2 = max(0., t2);
    float d2 = -.2 + length(p);
    c = d1 < d2 ? c1 : c2;
    t = d1 < d2 ? t1 : t2;
    return min(d1, d2);
}

void main(void) {
    vec2 uv=(gl_FragCoord.xy-.5*resolution)/resolution.y;
    vec3 rd=normalize(vec3(uv,1));
    vec3 p=vec3(0,0,-5);
    float d=1.,i;
    for(;++i<99.&&d>.001;)p+=rd*(d=map(p));
    if(d<.001)glFragColor+=3./i;
    vec3 col;
    for(i=0.;++i<64.;) col += map(p) < 0.001 ? c*0.05*t : vec3(0.), p += rd*0.04;
    glFragColor=vec4(col,1.);
    glFragColor = min(glFragColor, 1.);
}

