#version 420

// original https://www.shadertoy.com/view/ts23RK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* LICENSE - There Ain't One

 * Shadertoy port of ssloy's tinykaboom
 *  see https://github.com/ssloy/tinykaboom
 * tinykaboom license:

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                   Version 2, December 2004
 
Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.
 
           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

 0. You just DO WHAT THE FUCK YOU WANT TO.

*/

const float sphereRadius = 1.5;
const float noiseAmplitude = 1.0;

#define M_PI 3.1415926535897932384626433832795028841971693993751058209749445923078164062
const float vFov = M_PI/3.0;

float lerp(in float f0, in float f1, float t)
{
    return f0 + (f1-f0)*max(0.0, min(1.0, t));   
}

vec3 lerp(in vec3 v0, in vec3 v1, float t)
{
    return v0 + (v1-v0)*max(0.0, min(1.0, t));   
}

// lol what
float hash(const float n)
{
    float x = sin(n)*43758.5453;
    return x-floor(x);
}

float noise(in vec3 x)
{
    vec3 p = floor(x);
    vec3 f = x - p;
    f = f * dot(f, vec3(3.0,3.0,3.0)-2.0*f);
    float n = dot(p, vec3(1.0, 57.0, 113.0));
    return lerp(lerp(
                   lerp(hash(n + 0.0), hash(n + 1.0), f.x),
                   lerp(hash(n + 57.0), hash(n + 58.0), f.x),
                   f.y
               ),
               lerp(
                   lerp(hash(n + 113.0), hash(n + 114.0), f.x),
                   lerp(hash(n + 170.0), hash(n + 171.0), f.x),
                   f.y                   
               ), 
               f.z);
}

vec3 rotate(in vec3 v)
{
    return vec3(dot(v, vec3( 0.0,  0.8,   0.6)),
                dot(v, vec3(-0.8,  0.36, -0.48)),
                dot(v, vec3(-0.6, -0.48,  0.64))
               );
}

// ssloy explicitly wishes to replace this function
float fractalBrownianMotion(in vec3 x)
{
    vec3 p = rotate(x);
    float f = 0.0;
    f += 0.5000*noise(p); p = p*2.32;
    f += 0.2500*noise(p); p = p*3.03;
    f += 0.1250*noise(p); p = p*2.61;
    f += 0.0625*noise(p);
    return f/0.9375;    
}

// Play with this for varying fire effects
vec3 paletteFire(in float d)
{
    const vec3 yellow = vec3(1.7, 1.3, 1.0); // Hot value
    const vec3 orange = vec3(1.0, 0.6, 0.0);
    const vec3 red = vec3(1.0, 0.0, 0.0);
    const vec3 darkgray = vec3(0.2, 0.2, 0.2);
    const vec3 gray = vec3(0.4, 0.4, 0.4);
    
    float x = max(0.0, min(1.0, d));
    if (x<.25f)
        return mix(gray, darkgray, x*4.f);
    else if (x<.5f)
        return mix(darkgray, red, x*4.f-1.f);
    else if (x<.75f)
        return mix(red, orange, x*4.f-2.f);
    return mix(orange, yellow, x*4.f-3.f);
}

float signedDistance(in vec3 p)
{
    float displacement = -fractalBrownianMotion(p*3.4 + vec3(0.1, 0.1, 0.1)*time)*noiseAmplitude;
    return length(p) - (sphereRadius + displacement) * (0.1 + 0.9*sin(mod(time*(2./M_PI), M_PI/2.)));
}

bool sphereTrace(in vec3 orig, in vec3 dir, out vec3 pos)
{
    if ( dot(orig, orig) - (dot(orig,dir)*dot(orig,dir)) > (sphereRadius*sphereRadius))
        return false;
        
    pos = orig;
    for(int i = 0; i < 128; i++)
    {
        float d = signedDistance(pos);
        if (d < 0.0) return true;
        pos = pos + dir*max(d*0.1, 0.01);
    }
    return false;
}

vec3 distanceFieldNormal(in vec3 pos)
{
    const float eps = 0.1;
    float d = signedDistance(pos);
    float nx = signedDistance(pos + vec3(eps, 0.0, 0.0)) - d;
    float ny = signedDistance(pos + vec3(0.0, eps, 0.0)) - d;
    float nz = signedDistance(pos + vec3(0.0, 0.0, eps)) - d;
    return normalize(vec3(nx, ny, nz));
}

void main(void)
{
    float dirX = (gl_FragCoord.x + 0.5) - resolution.x/2.0;
    float dirY = -(gl_FragCoord.y + 0.5) + resolution.y/2.0;
    float dirZ = -resolution.y/(2.0*tan(vFov/2.0));
    
    vec3 hit;
    if(sphereTrace(vec3(0.0,0.0,3.0), normalize(vec3(dirX, dirY, dirZ)), hit))
    {
        float noiseLevel = (sphereRadius - length(hit))/noiseAmplitude;
        vec3 lightDir = normalize((vec3(10.0, 10.0, 10.0) - hit));
        float lightIntensity = max(0.4, dot(lightDir,distanceFieldNormal(hit)));
        glFragColor = vec4(paletteFire(2.0*(-0.2+noiseLevel))*lightIntensity, 1.0);
    }
    else
        glFragColor = vec4(0.2, 0.7, 0.8, 1.0);

}
