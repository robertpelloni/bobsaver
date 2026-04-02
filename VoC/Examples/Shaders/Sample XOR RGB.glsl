#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XtyyRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// XOR_RGB.glsl

// original XOR by Philemonic  https://www.shadertoy.com/view/XlGyRc

#define HASH 1
#define scale1 200.
#define scale2 888.
#define iterations 15

float hash(float n) 
{
    return fract(sin(n) * 43758.5453123); 
}

float mbrn(float n) 
{
    for (int i=0; i<iterations; i++) n=n*n-2.;  return n*.5; 
}

float xor(vec2 p) 
{
    p.x=abs(scale2 - mod(p.x,scale2*2.));
    p*=mat2(1.,1.,-1.,1.);
    float xor = float(int(p.x)^int(p.y));
    if (HASH == 1) return pow(mbrn(xor/scale2),3.);
    else           return pow(hash(xor),2.);
}

void main(void)
{
    vec2 uv = 1.+gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;                  
    uv.x += time*.05;
    uv.x += sin(time*.1)*2.;
    glFragColor = vec4(xor(uv*scale1),xor(uv*123.),xor(uv*99.),1.);
}
