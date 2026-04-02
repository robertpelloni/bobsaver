#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XlGyRc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define scale1 100.
#define scale2 1000.
#define iterations 50

float mbrn(float n) {
    for (int i=0; i<iterations; i++) {
        n=n*n-2.;
    }
    return n*.5;
}

float xor(vec2 p) {
    p.x=abs(scale2 - mod(p.x,scale2*2.));
    p*=mat2(1.,1.,-1.,1.);
    float xor = float(int(p.x)^int(p.y));
    return pow(mbrn(xor/scale2),3.);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;           
    uv.x += time*.1;
    uv.y += sin(time*.02)*5.;
    glFragColor = vec4(xor(uv*scale1));
}
