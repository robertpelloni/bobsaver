#version 420

// original https://www.shadertoy.com/view/DlGSR 

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float CROSS_SIZE = 0.47;
const vec3 CLR = vec3(0.000,0.227,0.761);
const float iterations = 12.;

//by iq
#define INTERPOLANT 0
vec3 hash( vec3 p ) // replace this by something better
{
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise(in vec3 p)
{
    vec3 i = floor( p );
    vec3 f = fract( p );

    #if INTERPOLANT==1
    // quintic interpolant
    vec3 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    #else
    // cubic interpolant
    vec3 u = f*f*(3.0-2.0*f);
    #endif    

    return mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                          dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                          dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                          dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                     mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                          dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
}

float sdCross(vec2 uv, vec2 center, float width)
{
    return min(max(abs(uv.x - center.x) - width, abs(uv.y - center.y) - CROSS_SIZE),
               max(abs(uv.x - center.x) - CROSS_SIZE, abs(uv.y - center.y) - width));
}

void main(void)
{
    vec2 aspect = resolution.xy/resolution.y;
    vec2 uv = gl_FragCoord.xy/resolution.xy * aspect;
    vec2 center = aspect * 0.5;
    
    vec3 resColor = CLR;
    for (float i = iterations; i >= 0.0; i--)
    {
        float scale = 1.0 + pow(i/iterations, 2.2) * 9.0;
        vec2 offset = vec2(noise(vec3(113.2, time * 2.0 + i * 0.1, 1.0)) * 0.2,
                           noise(vec3(17., 1.1, time * 1.1 + i * 0.1)) * 0.2); 
        float crss = sdCross(uv * scale, center * scale + offset * scale, CROSS_SIZE * 1./aspect.x * 0.75);
        float stencil = step(0.0, crss);
        resColor = mix(resColor, mix(vec3(1.0), CLR, pow(i/iterations, .5)), stencil);
        resColor *= max(0.8 + 0.2 * smoothstep(0., -0.05, crss), stencil);
        //resColor += 0.077 * stencil;
    }
    glFragColor = vec4(resColor, 1.0);
}