#version 420

// original https://www.shadertoy.com/view/4d3yWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind and leon for teaching me!

#define ITER 100
#define PI 3.141592
#define TAU 2.*PI

mat2 rot (float angle)
{
     float c = cos(angle);
    float s = sin(angle);
    return mat2(c,s,-s,c);
}

vec2 moda (vec2 p, float per)
{
    float angle = atan(p.y,p.x);
    float l = length(p);
    angle = mod(angle-per/2.,per)-per/2.;
    return vec2 (cos(angle),sin(angle))*l;
}

float cyl (vec3 p, float r)
{
    return length(p.yz)-r;
}

float sphe (vec3 p, float r)
{
    return length(p)-r;
}

float box (vec3 p, vec3 c)
{
    return length(max(abs(p)-c,0.));
}

float Prim_Element (vec3 p)
{
    float per = 2.;
    float prim_cyl = cyl(p,1./p.x*1.5);
    p.x -= time;
    p.x = mod(p.x-per/2.,per)-per/2.;
    float prim_sphe = sphe(p,0.4);
    return min(prim_cyl, prim_sphe);
}

float tentacular_cross (vec3 p)
{
    p.x -= sin(-p.z+time);
    p.xz= moda(p.xz, TAU/6.);  
    return Prim_Element(p);
}

float tentacular_star (vec3 p)
{
    p.x = abs(p.x);
    p.yz *= rot(PI/2.);
    float one = tentacular_cross(p);
    p.xz *= rot(PI/2.);
    float two = tentacular_cross(p);
    return min(one, two);
}

float SDF (vec3 p)
{
    float per = 10.;
    //p.xy = mod(p.xy-per/2., per)-per/2.;
    return tentacular_star(p);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;
    
    vec3 p = vec3 (0.001,2.,-10);
    vec3 dir = normalize(vec3(uv, 1.));
    float shad = 1.;
    
    for (int i = 0; i<ITER; i++)
    {
        float d = SDF(p);
        if (d<0.001 || d>30.)
        {
            shad = float(i)/float(ITER);
            break;
        }
        p += d*dir;
    }
    
    // Time varying pixel color
    vec3 col = shad/vec3(length(p.z),0.5,0.7);

    // Output to screen
    glFragColor = vec4(col,1.0);
}
