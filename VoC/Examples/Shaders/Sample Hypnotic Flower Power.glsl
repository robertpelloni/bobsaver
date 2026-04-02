#version 420

// original https://www.shadertoy.com/view/MdtcRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine
// Color tricks inspired by IQ's article : http://www.iquilezles.org/www/articles/palettes/palettes.htm
// and by dlsym shader : https://www.shadertoy.com/view/lljfDd
// Thanks to wsmind and leon for teaching me :) 

#define PI 3.141592
#define TAU 2.*PI

mat2 rot (float angle)
{
    float c=cos(angle);
    float s=sin(angle);
    return mat2 (c,s,-s,c);
}

vec2 logmoda (vec2 p, float per)
{
    float angle = atan(p.y,p.x);

    float l = length(p);
    //magic line from dlsym shader
    float r = log(sqrt(p.x*p.x+p.y*p.y)); 
    angle = mod(angle-per/2.,per)-per/2.;
    return vec2(angle, r);
}

float cylY (vec3 p, float r)
{return length(p.xz)-r;}

float SDF (vec3 p)
{
    
    float per =2.2;
    p.xy *= rot(time*0.2);
    p.xy = logmoda(p.xy, TAU/6.);
    p.xy *= rot(time)*p.yz;
    p.z = mod(p.z-per/2.,per)-per/2.;

    return cylY(p,0.1);
}

//IQ's code from article : http://www.iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette(in float oscill, in vec3 a, in vec3 b, in vec3 c, in vec3 phase )
{
    return a + b*cos(TAU*(c*oscill+phase));
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 2.*(gl_FragCoord.xy/resolution.xy)-1.;
    uv.x *= resolution.x/resolution.y;
    
    vec3 p = vec3 (0.001,0.001, -4.);
    vec3 dir = normalize(vec3(uv,1.));
    
    float shad = 0.;
    
    for(int i=0; i<90; i++)
    {
        float d = SDF(p);
        if (d<0.001 || d>5.)
        {
            shad = float (i)*PI/60.;
            break;
        }
        p += d*dir*0.8;
    }
    
    // Time varying pixel color
    vec3 col = (1.-shad)/palette(p.z*0.01,
                                 vec3(0.5), 
                                 vec3(0.5),
                                 vec3(2.,1.,0.),
                                 vec3(0.50, 0.30, 0.8)
                                );

    // Output to screen
    glFragColor = vec4(pow(col,vec3(2.2)),1.0);
}
