#version 420

// thank to @iquilezles -> http://www.iquilezles.org/www/index.htm
// thank to @uint9 -> http://9bitscience.blogspot.fr/2013/07/raymarching-distance-fields_14.html

#define PI 3.141592653589
#define PI2 6.2831853071795

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Raymarching
const float rayEpsilon = 0.0001;
const float rayMin = 0.1;
const float rayMax = 100000.0;
const int rayCount = 64;

// Camera
vec3 eye = vec3(0.0, 0.0, -2.0);
vec3 front = vec3(0.0, 0.0, 1.0);
vec3 right = vec3(1.0, 0.0, 0.0);
vec3 up = vec3(0.0, 1.0, 0.0);

// Axis
vec3 axisX = vec3(1.0, 0.0, 0.0);
vec3 axisY = vec3(0.0, 1.0, 0.0);
vec3 axisZ = vec3(0.0, 0.0, 1.0);

// Colors
vec3 sphereColor = vec3(0, 0.5, 0.0);
vec3 skyColor = vec3(0.0, 0.0, 0.0);
vec3 shadowColor = vec3(0.0, 0.0, 0.5);
vec3 fogColor  = vec3(0.5,0.0,0.0);

// Animation
float sphereRadius = 0.8;

// @iquilezles
float sphere ( vec3 p, float s ) 
{ 
    return length(p)-s; 
}

// hash based 3d value noise
// function taken from https://www.shadertoy.com/view/XslGRr
// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// ported from GLSL to HLSL
float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

// @iquilezles
float noise( vec3 x )
{
    // The noise function returns a value in the range -1.0f -> 1.0f
    vec3 p = floor(x);
    vec3 f = fract(x);
    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+0.0), hash(n+1.0),f.x),
                   mix( hash(n+57.0), hash(n+58.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

// @iquilezles
float plane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

// @iquilezles
vec3 applyFog( in vec3  rgb,       // original color of the pixel
               in float dist ) // camera to point distance
{
    float fogAmount = exp( -dist * 100.0);
    return mix( rgb, fogColor, fogAmount );
} 

// @uint9
vec3 rotateY(vec3 v, float t)
{
    float cost = cos(t); float sint = sin(t);
    return vec3(v.x * cost + v.z * sint, v.y, -v.x * sint + v.z * cost);
}

// @uint9
vec3 rotateX(vec3 v, float t)
{
    float cost = cos(t); float sint = sin(t);
    return vec3(v.x, v.y * cost - v.z * sint, v.y * sint + v.z * cost);
}

// http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-iii-folding-space/
float Scale = 1.0;
float Offset = 0.0;
const int Iterations = 8;
float Bailout = 2.0;
float Power = 2.0;
float DE(vec3 pos) {
    vec3 z = pos;
    float dr = 1.0;
    float r = 0.0;
    Power = 1.0 + 8.0 * (0.5 + 0.5 * cos(time * 0.1));
    
    for (int i = 0; i < Iterations ; i++) {
        r = length(z);
        if (r>Bailout) break;
        
        // convert to polar coordinates
        float theta = acos(z.z/r);
        float phi = atan(z.y,z.x);
        dr =  pow( r, Power-1.0)*Power*dr + 1.0;
        
        // scale and rotate the point
        float zr = pow( r,Power);
        theta = theta*Power;
        phi = phi*Power;
        
        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z+=pos;
    }
    return 0.5*log(r)*r/dr;
}
vec3 puzzle (vec3 p)
{    
    p -= 0.5 * noise(4.0 * p + time);
    //p -= 0.5 * noise(p * 10.0) * 0.1;
    return p;
}

vec3 fluid (vec3 p)
{    
    p -= 0.1 * noise(p * 2.0 + time);
    p -= 0.5 * noise(p * 10.0) * 0.1;
    return p;
}

float scene (vec3 p)
{
    return DE(p);
    float sph = sphere(  p, sphereRadius +  0.1 * noise(distance(vec3(mouse.x, 0.0, mouse.y), p) * 10.0 * (p + vec3(mouse.x, 0.0, mouse.y))));
    float pla = plane( fluid(p), vec4(0.0, 1.0, 0.0, 5.0));
    return min(sph, pla);
}

// http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-ii-lighting-and-coloring/
vec3 getNormal ( vec3 p )
{
    return normalize(vec3(scene(p+axisX)-scene(p-axisX), scene(p+axisY)-scene(p-axisY), scene(p+axisZ)-scene(p-axisZ)));
}
void main( void )
{
    vec2 uv = gl_FragCoord.xy * 2.0 / resolution.xy - 1.0;
    uv.x *= resolution.x / resolution.y;
    
    vec3 ray = normalize(front + right * uv.x + up * uv.y);
    
    vec3 color = skyColor;
    
    // Raymarching
    float t = 0.0;
    for (int r = 0; r < rayCount; ++r)
    {
        //eye.z = -1.5 * mouse.x;
        
        // Ray Position
        vec3 p = eye + ray * t;
        
        p = rotateY(p, mouse.x * PI2);
        p = rotateX(p, mouse.y * PI2);
        
        // Distance to Sphere
        float d = DE(p);
        
        // Distance min or max reached
        if (d < rayEpsilon || t > rayMax)
        {
            //p = fluid(p);
            // Color from normal
            color = normalize(p) * 0.5 + 0.5;//getNormal(p) * 0.5 + 0.5;
            // Shadow from ray count
            color = mix(color, shadowColor, float(r) / float(rayCount));
            // Sky color from distance
            //color = mix(color, skyColor, smoothstep(rayMin, rayMax, t));
            break;
        }
        
        //color = applyFog(color, d);
        
        // Distance field step
        t += d;
    }
    
    
    
    glFragColor = vec4( color, 1.0 );

}
