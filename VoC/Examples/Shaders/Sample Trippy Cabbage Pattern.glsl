#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Wl3GRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.1415926535

// Hash functions by Dave_Hoskins
float hash12(vec2 p)
{
    uvec2 q = uvec2(ivec2(p)) * uvec2(1597334673U, 3812015801U);
    uint n = (q.x ^ q.y) * 1597334673U;
    return float(n) * (1.0 / float(0xffffffffU));
}

vec2 hash22(vec2 p)
{
    uvec2 q = uvec2(ivec2(p))*uvec2(1597334673U, 3812015801U);
    q = (q.x ^ q.y) * uvec2(1597334673U, 3812015801U);
    return -1. + 2. * vec2(q) * (1.0 / float(0xffffffffU));
}

// Value noise by iq
float valueNoise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( hash22( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                     dot( hash22( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( hash22( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                     dot( hash22( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

// Curl noise from http://petewerner.blogspot.com/2015/02/intro-to-curl-noise.html
vec2 curl(vec2 uv)
{
    vec2 eps = vec2(0., 1.);
    
    float n1, n2, a, b;
    n1 = valueNoise(uv + eps);
    n2 = valueNoise(uv - eps);
    a = (n1 - n2) / (2. * eps.y);
    
    n1 = valueNoise(uv + eps.yx);
    n2 = valueNoise(uv - eps.yx);
    b = (n1 - n2)/(2. * eps.y);
    
    return vec2(a, -b);
}

// rotate uv based on polar coords
vec2 swirl(vec2 uv, float tht){
    float t = atan(uv.y, uv.x) + tht;
    float d = length(uv);
    uv.x = cos(t) * d;
    uv.y = sin(t) * d;
    return uv;
}

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    float cabbage = 0., scale = 8., bandingScale = 5., t = time * .5;
    
    uv = swirl(uv, .4 * length(2. * uv) + sin(t * .2)); // slightly swirly rotate uv;
    uv *= scale;
    uv += curl(uv) * 2.; //add curl noise to uv for distortion
    cabbage += sin(uv.x + t);
    cabbage += sin((uv.y + t) * .5);
    cabbage += sin((uv.x * sin(t * .5) + uv.y * cos(t * .334)+ t) * .5); // rotating grid
    uv += scale * .5 * vec2(sin(t * .334), cos(t * .5));
    cabbage += sin(sqrt(dot(uv, uv) + 1.) + t);
    cabbage = .5 + .5 * sin(cabbage * bandingScale * PI); // concentric sinusoid

    vec3 col = vec3(0.);
    col += 2. * vec3(cos(PI * (cabbage + .5 * t)), sin(PI * (cabbage + 1.167 * t)),
                sin(PI * (cabbage + 1.834 * t)));

    glFragColor = vec4(col, 1.0);
}
