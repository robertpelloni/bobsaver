#version 420

// original https://www.shadertoy.com/view/ls3cWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind and leon for teaching me! :)

#define ITER 80.
#define PI 3.141592
#define TAU 2.*PI

/////////////////// UTILITIES
mat2 rot (float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2 (c,s,-s,c);
}

vec2 moda (vec2 p, float per)
{
    float a = atan(p.y,p.x);
    float l = length(p);
    a = mod(a-per/2., per)-per/2.;
    return vec2(cos(a),sin(a))*l;
}

// iq's palette
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

/////////////////// PRIMARY SHAPES
float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

float sphe (vec3 p, float r)
{
    return length(p)-r;
}

float cylY (vec3 p, float r)
{
    return length(p.xz)-r;
}

/////////////////// PRIMITIVES
float prim1(vec3 p)
{
    p.yz *= rot(PI/2.);
    return max(-sphe(vec3(p.x,p.y,p.z*0.9),1.06),sdHexPrism (p, vec2 (1.,0.5)));
}

float prim2 (vec3 p)
{
    p.xz *= rot(time+p.y);
    p.xz = moda(p.xz, TAU/6.);
    p.x -= .6;

    return cylY(p,.1);
}

float gear1 (vec3 p, float per)
{

    p.y = mod(p.y-per/2.,per)-per/2.;
    p.xz *= rot(time);
    return prim1(p);
}

float gear2 (vec3 p, float per)
{
    p.y -= per/2.;
    p.y = mod(p.y-per/2.,per)-per/2.;
    p.xz *= rot(-time);
    return prim1(p);
}

float pattern (vec3 p)
{
   return min(gear2(p,4.),min(gear1(p, 4.),prim2(p)));  
}

//////////////////// Raymarching field
float SDF (vec3 p)
{
    float per = 2.;
    
    p.xy *= rot(time*0.3+(p.z*0.2));
    p.z = mod(p.z-per/2.,per)-per/2.;
    p.xy = moda(p.xy, TAU/4.);
    p.x -= 4.;
   return pattern(p);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;
    
    vec3 p = vec3 (0.001,0.001,time);
    vec3 dir = normalize(vec3 (uv*2.,1.));
    
    float shad = 0.;
    vec3 col = vec3 (0.);
    
    for (float i=0.; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.001)
        {
            shad = i/ITER;
            col = vec3(1.-shad)*palette(dir.z,
                          vec3 (0.,0.5,0.),
                          vec3 (0.,0.2,0.1),
                          vec3 (0.2),
                          vec3(time*0.3));;
            break;
        }

        p+=d*dir*0.7;
    }
    

    // Output to screen
    glFragColor = vec4(pow(col,vec3(0.45)),1.0);
}
