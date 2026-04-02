#version 420

// original https://www.shadertoy.com/view/tts3Dj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// demonstration of Worley (Voronoi) noise on the sphere

// sphere rendering forked from https://www.shadertoy.com/view/MssGRl by asalga

// some constants

#define PI 3.14159265359
#define GA 2.39996322973 // golden angle, (3 - sqrt(5)) * PI

// range of the display

#define SCALE 8.0

// utility function

#define cis(a) vec2( cos(a), sin(a) )

// angle between two vectors, Kahan's formula; https://people.eecs.berkeley.edu/~wkahan/MathH110/Cross.pdf

float vectorAngle(vec3 p1, vec3 p2)
{
      vec3 np1 = normalize(p1), np2 = normalize(p2);

      return 2.0 * atan(length(np1 - np2), length(np1 + np2));
}

// number of points in sphere
#define NPTS 50

// return the two closest distances for Worley noise

vec2 sphworley(vec3 p)
{
    vec2 dl = vec2(4.0);
    
    for (int m = 0; m < NPTS; m++)
    {
        // generate feature points within the cell, using phyllotactic sampling
        float mf = float(m + 1), mr = mf/float(NPTS);
        float rr = 2.0 * sqrt((1.0 - mr) * mr);
        vec3 tp = vec3(rr * cos(mf * GA), rr * sin(mf * GA), 1.0 - 2.0 * mr);
        
        float c = vectorAngle(p, tp);
                
        float m1 = min(c, dl.x); // ranked distances
        dl = vec2(min(m1, dl.y), max(m1, min(max(c, dl.x), dl.y)));
    }
        
    return dl;
}

// rescaling functions

float rescale(float x, vec2 range)
{
      float a = range.x, b = range.y;
      return (x - a)/(b - a);
}

float rescale(float x, vec2 r1, vec2 r2)
{
      return mix(r2.x, r2.y, (x - r1.x)/(r1.y - r1.x));
}

// modified MATLAB bone colormap

vec3 bone( float t )
{
     return 0.875 * t + 0.125 * clamp(vec3(4.0, 3.0, 3.0) * t - vec3(3.0, 1.0, 0.0), 0.0, 1.0);
}

// modified MATLAB hot colormap

vec3 hot( float t )
{
     return clamp(vec3(3.0, 3.0, 4.0) * t - vec3(0.0, 1.0, 3.0), 0.0, 1.0);
}

// sphere normal

vec3 getNormal(in vec2 c, in float r, in vec2 point)
{
    return mix(vec3(0.0, 0.0, 1.0), normalize(vec3(point - c, 0.0)), length(point - c)/r);
}

void main(void)
{
    vec2 aspect = resolution.xy / resolution.y;
    vec2 uv = ( gl_FragCoord.xy / resolution.y ) - 0.5 * aspect;
    uv *= SCALE;
    float r = 3.0; // sphere radius
    
    if( length(uv) < r)
    {
        vec3 sphereNormal = vec3(getNormal(vec2(0.0), r, uv));
        vec3 dirLight = normalize(vec3(0.0, 0.0, 1.0));
        
        vec3 col = normalize(vec3(1.0)) * dot(sphereNormal, dirLight);

        float del = 0.1 * PI * time;
        vec2 v = sphereNormal.xy;
        
        vec2 w = sphworley(vec3(vec2(v.x, sqrt(1.0 - dot(v, v))) * mat2(cos(del), -sin(del), sin(del), cos(del)), v.y));

        vec3 c1 = bone(rescale((2.0 * w.y * w.x)/(w.y + w.x) - w.x, vec2(0.0, 0.0625 * PI)));
        vec3 c2 = hot(rescale(length(w.xy)/(w.y + w.x) - w.x, vec2(0.0, 0.6 * PI)));
        
        glFragColor = vec4(0.15 + 2.2 * col * mix(c2, c1, 0.5 + 0.5 * cos(0.2 * time)), 1.0);

    } else {

        glFragColor = vec4(0.16, 0.14, 0.13, 1.0);

    }
}
