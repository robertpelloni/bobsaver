#version 420

// original https://www.shadertoy.com/view/ldcyDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Thanks to wsmind and leon for teaching me :)

#define PI 3.141592
#define TAU 2.*PI
#define ITER 60

mat2 rot (float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2 (c,s,-s,c);
}

// iq's palette http://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d)
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec2 moda (vec2 p, float per)
{
    float angle = atan(p.y, p.x);
    float l = length(p);
    angle = mod(angle-per/2.,per)-per/2.;
    return vec2(cos(angle),sin(angle))*l;
}

float cylZ (vec3 p, float r)
{
    return length(p.xy)-r;
}

float map (vec3 p)
{

    p.xy *= rot(-p.z);
    p.xy = moda(p.xy, TAU/5.);
    p.x -= 0.5;
    return cylZ(p,.3); 
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;
    
    float shad = 1.;
    vec3 p = vec3(0.001,0.001,-time*0.3);
    vec3 dir = normalize(vec3(uv,1.));
    
    for (int i = 0; i<ITER; i++)
    {
        float d = map(p);
        if (d<0.001)
        {
            shad = float(i)/float(ITER);
            break;
        }
        p+=dir*d;
        
    }
    vec3 pal = palette(p.z,
                      vec3(0.0,0.5,0.5),
                      vec3(0.5),
                      vec3(5.),
                      vec3(0.,0.1, time*0.2));
    // Time varying pixel color
    vec3 col = vec3(1.-shad)*pal*2.;

    // Output to screen
    glFragColor = vec4(pow(col, vec3(0.45)),1.0);
}
