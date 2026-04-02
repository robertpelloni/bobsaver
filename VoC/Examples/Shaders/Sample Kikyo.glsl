#version 420

// original https://neort.io/art/c3lam3c3p9f8s59bglcg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define PI 3.14159265
#define PI2 PI*2.0

vec2 rotate(vec2 p, float a){
    return mat2(cos(a),sin(a),-sin(a),cos(a)) * p;
}

vec2 pmod(vec2 p, float n){
    float a = atan(p.y,p.x) + PI/n;
    float r = PI2/n;
    a = floor(a/r) * r;
    return rotate(p,-a);
}

float opSmoothSub(float d1, float d2, float k){
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float sdVesica(vec2 p, float r, float d)
{
    p = abs(p);
    float b = sqrt(r*r-d*d);
    return ((p.y-b)*d>p.x*b) ? length(p-vec2(0.0,b))
                             : length(p-vec2(-d,0.0))-r;
}

float sdLine( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdFlowerPetal(vec2 p, float r){
    float v = sdVesica(p,0.5,0.36);
    vec2 p0 = p - vec2(0.43,0.61);
    float sr0 = length(p0) - .5;
    vec2 p1 = p - vec2(-0.43,0.61);
    float sr1 = length(p1) - .5;
    float sr = min(sr0,sr1);
    v = opSmoothSub(sr,v,0.02);
    float c = length(p) - 0.15;
    return p.y > 0.0 ? v : 0.0;
}

float sdKikyo(vec2 p){
    p = rotate(p,-PI/10.0);
    p = pmod(p,5.);
    p = rotate(p,PI/2.0);
    float s =sdFlowerPetal(p, 0.25);
    float l = abs(sdLine(p,vec2(0.0),vec2(0.0,0.1))) - 0.02;
    s = max(s,-l);
    s = max(s,0.04 -length(p));
    return s;
}

float hash(vec2 uv){
    return fract(45464.5315 * sin(dot(uv,vec2(12.5453,75.431))));
}

float square(float x){
    return sin(x) > 0. ? 1. : -1.;
}

float flow(vec2 uv){
    float c = 0.0;
    float c1 = sin(dot(uv, vec2(0.4,1.)) + time);
    float c0 = sin(dot(uv,vec2(1,0) * 0.3) + time) * 2.0;
    float c2 = sin(dot(uv, vec2(0.1,0.4)) + time * 0.4 + c0 + c1);
    c = square(dot(uv, vec2(0,3.)) + time * 0.2 + c0 + c1 + c2);
    return c * 0.5 + 0.5;
}

vec3 flower(vec2 uv, float s, float t, vec2 seed){
    vec2 uv0 = uv * s;
    vec2 fuv = fract(uv0) - 0.5;
    vec2 iuv = floor(uv0);
    float h0 = hash(iuv + seed) - 0.5;
    float h1 = hash(iuv.y + seed + 100.);
    vec2 uv1 = uv0;
    uv1.x += time * h1 * 0.6;
    vec2 fuv1 = fract(uv1) - 0.5;
    vec2 iuv1 = floor(uv1);
    float h2 = hash(iuv1 + seed) - 0.5;
    fuv1 = rotate(fuv1, fract(h2 * 30.0) * PI + time * h2);
    float f = flow(uv);
    fuv1.y += sin(time) * 0.1;
    float fl = sdKikyo(fuv1);
    fl = 1.0 - smoothstep(0.0,0.01,fl);
    fl *= h2 > t ? 1.: 0.;
    return vec3(fl);
}

vec3 mainColor(vec2 uv){
    float f = flow(uv);
    
    vec3 s = flower(uv, 1.0, 0.45, vec2(0.0));
    vec3 s1 = flower(uv,0.5, 0.4,vec2(1.,53.));
    vec3 s2 = flower(uv,0.75, 0.45,vec2(6.,9.));
    vec3 s3 = flower(uv,0.25, 0.45, vec2(28.,51.));
    
    s1 -= s;
    s1 = clamp(s1,0.0,1.0);
    s2 -= s + s1;
    s2 = clamp(s2,0.0,1.0);
    
    s3 -= s + s1+ s2;
    s3 =clamp(s3,0.,1.);
    
    
    
    vec3 bg = mix(vec3(0.9,0.9,1.0),vec3(1.0),f);
    
    bg -= s + s1 + s2 + s3;
    bg = clamp(bg,0.,1.);
    
    s *= vec3(0.6,0.87,0.94);
    s1 *= vec3(0.7,0.6,0.9);
    s2 *= vec3(0.3,0.7,0.95);
    s3 *= vec3(0.7,0.93,1.0);
    
    bg *= vec3(0.9,0.9,1.0);
    
    s += s1 + s2 + s3;
    
    s += bg;
    return s;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    uv *= 5.0;
    
    vec3 c = mainColor(uv);
    
    glFragColor = vec4(c, 1.0);
}
