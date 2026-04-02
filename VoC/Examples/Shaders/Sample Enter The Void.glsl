#version 420

// original https://www.shadertoy.com/view/ldGcDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind, leon, lsdlive, XT95 and lamogui for teaching me :) <3

#define STEPS 60.
#define PI 3.141592

vec2 moda (vec2 p, float per)
{
   float a = atan(p.y,p.x);
    float l = length(p);
    a = mod(a-per/2.,per)-per/2.;
    return vec2(cos(a),sin(a))*l;
}

mat2 rot (float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

void mo(inout vec2 p, vec2 d) 
{
    p.y = abs(p.y) - d.x;
    p.x = abs(p.x) - d.y;
    if (p.y > p.x) p.xy = p.yx;
}

vec3 palette (float t, vec3 a, vec3 b, vec3 c, vec3 d)
{
    return a+b*cos(2.*PI*(c*t+d));
}

float cyl (vec2 p, float r)
{
    return length(p)-r;
}

float sphe (vec3 p, float r)
{
    return length(p)-r;    
}

float petal(vec3 p)
{
    p.xy *= rot(PI);
    p.x += sin(p.y/1.7)*1.8;
      p.y += 2.;
    return cyl(p.xz,p.y*0.1+0.5);
}

float flower(vec3 p)
{
    p.xz *= rot(PI*2.);
    p.xz = moda(p.xz, (2.*PI)/8.);
    p.x -= 3.;
    return petal(p);
}

float pistil(vec3 p)
{
    float r = 1.3;
    float per = r+5.;
    float c = cyl(p.xz,r/4.+p.y*0.04);
    p.y -= tan(time);
    p.y = mod(p.y - per/2.,per)-per/2.;
    return smin(sphe(p,r*0.8),c, 0.8);
}

float gate (vec3 p, float mdl)
{
    mo(p.xy,vec2(mdl));
    mo(p.xz, vec2(mdl/2.));
    return min(flower(p),pistil(p));
}

float fractal (vec3 p, int IM)
{
    float g = gate(p,10.);
    for (int i=0; i<IM; i++)
    {        
        p = abs(p);
        p -= 25.;
        p.xy *= rot(PI/4.);      
        p.xz *= rot(PI/8.);       
        g = min(g,gate(p,10.));
    }
    return g;
}

float sdf (vec3 p, int i)
{
    return fractal(p, i);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;
    
    float sin_per = 15.;
    vec3 p = vec3 (0.001,0.001,-cos((time)/9.)*sin_per+sin_per);
    vec3 dir = normalize(vec3(uv,1.));
    float shad = 0.;
    float d = 0.;
    
    for (float i=0.;i<STEPS;i++)
    {
        d = sdf(p, int(i));
        if (d<0.01)
        {
            shad = i/STEPS;
            break;
        }
        p+=d*dir;
    }
    vec3 pal = palette(length(uv),
                      vec3(0.5),
                      vec3(0.5),
                      vec3(0.5,0.5,1.),
                      vec3(0.3,0.9,0.8)
                      );
    
    // Time varying pixel color
    vec3 col = vec3(shad*2.5)*pal;

    // Output to screen
    glFragColor = vec4(col,1.0);
}
