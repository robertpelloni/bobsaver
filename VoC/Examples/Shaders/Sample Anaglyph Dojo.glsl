#version 420

// original https://www.shadertoy.com/view/wsV3Wm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Anaglyph Quick Sketch
// An example on how to render stereoscopic anaglyph image
// It will be the theme of https://2019.cookie.paris/
// And the content of the 3rd issue of https://fanzine.cookie.paris/
// Licensed under hippie love conspiracy

float random(vec2 p) { return fract(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

mat2 rot(float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }

float smoothmin (float a, float b, float r) { float h = clamp(.5+.5*(b-a)/r, 0., 1.); return mix(b, a, h)-r*h*(1.-h); }

vec3 look (vec3 eye, vec3 target, vec2 anchor, float fov) {
    vec3 forward = normalize(target-eye);
    vec3 right = normalize(cross(forward, vec3(0,1,0)));
    vec3 up = normalize(cross(right, forward));
    return normalize(forward * fov + right * anchor.x + up * anchor.y);
}

// Using code from
// Leon d
// Inigo Quilez
// Morgan McGuire

// Custom part

float rep(inout float p, float r)
{
    float hr = r/2.;
    p += hr;
    float id = floor(p * r);
    p = mod(p , r) - hr;
    return id;
}

#define PI 3.1415926
#define TAU (PI * 2.)
#define HPI (PI / 2.)

float bounce(float p)
{

    float b = .25;
    
    return .5 - cos(p * PI) * .5 + sin(p * PI) * p * b ;
}

float multiplexer(float channel,float nbChannel,float t)
{
    float ft = floor(t);
    float mt = t- ft;
    mt *= nbChannel;
    channel = clamp(mt - channel,0.,1.);
    channel = bounce(channel) ;
    return ft + channel;
}

#define time (time * .75)

float map(vec3 pos)
{
    float nbChannel = 12.;
    
    
    
    float ti = max(0.,time) ;
    float bpm = 121.;
    
    ti *= (bpm / 60.) * 2.;
    
    float ts = ti / nbChannel;

    float dir =  mod(floor(ts),2.) * 2. - 1.;
    
    float multtime = ti / nbChannel;
    
    float r1 = multiplexer(2.,nbChannel,multtime) * PI / 2. * dir;
    pos.xz *= rot(r1);
    
    float r2 = multiplexer(6.,nbChannel,multtime) * PI / 2. * dir;
    pos.yz *= rot(r2);
    
    float r3 = multiplexer(10.,nbChannel, multtime) * PI / 2. * dir;
    pos.xy *= rot(r3);
    
    float dec = 4.;
    pos.xyz += dec / 2.;
    
    
    
    pos.z += multiplexer(0. ,nbChannel,multtime) * dec * -dir;
    pos.x += multiplexer(4. ,nbChannel,multtime) * dec * -dir;
    pos.y += multiplexer(8.,nbChannel,multtime) * dec * -dir;
    
    
    
    rep(pos.x,dec);
    rep(pos.y,dec);
    rep(pos.z,dec);
    float r =max(max((abs(pos.x)), abs(pos.y)),abs(pos.z));
    r = 0.0;//texture(iChannel0,vec2(r *.25,.5)).r;
    
    r = (exp(r)) * .35 - .25;
    
    
    float grid = min(min(length(pos.xy),length(pos.yz)),length(pos.xz)) - r;
    
    return grid;
}

// End of custom part.

const float grain = .01;
const float divergence = 0.1;
const float fieldOfView = 1.5;

float raymarch ( vec3 eye, vec3 ray ) {
    float dither = random(ray.xy+fract(time));
    float total = dither;
    const int count = 30;
    for (int index = count; index > 0; --index) {
        float dist = map(eye+ray*total);
        dist *= 0.9+.1*dither;
        total += dist;
        if (dist < 0.001 * total)
            return float(index)/float(count);
    }
    return 0.;
}

void main(void)
{
    vec2 uv = 2.*(gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    vec3 eyeLeft = vec3(-divergence,0,5.);
    vec3 eyeRight = vec3(divergence,0,5.);
    vec3 rayLeft = look(eyeLeft, vec3(0), uv, fieldOfView);
    vec3 rayRight = look(eyeRight, vec3(0), uv, fieldOfView);
    float red = raymarch(eyeLeft, rayLeft);
    float cyan = raymarch(eyeRight, rayRight);
    glFragColor = vec4(red,vec2(cyan),1);
}
