#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XtKyzW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.shadertoy.com/view/XlcyD8

#define scale 100.

float hash(float n){
    return fract(sin(n) * 43758.5453123);
}

float xor(vec2 p) {
    p*=mat2(1.,1.,-1.,1.);
    
    float xor = float(int(p.x)^int(p.y));
    return pow(hash(xor),2.);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;                  
    uv.x += time*.1;
    uv.y += sin(time*.02)*5.;
    glFragColor = vec4(xor(uv*scale));
}
