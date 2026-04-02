#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Xlyczc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.shadertoy.com/view/XlcyD8

#define scale1 200.
#define scale2 700.
#define iterations 60

float mbrn(float n) {
    for (int i=0; i<iterations; i++) {
        n=n*n-2.;
    }
    return n*.5;
}

float ormbrn(vec2 p) {
    p*=mat2(1.,1.,-1.,1.);
    float or = float(int(p.x)|int(p.y));
    float c = mod(or-time*scale1*.1,scale1)/scale1;
    return mbrn(or/scale2)*c;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy-.5;
    vec2 p = uv*(.7+sin(time*.15)*0.3);
    p.x *= resolution.x/resolution.y;
    p.x+=3.5+sin(time*.01)*2.;
    p+=time*.02;
    float c = ormbrn(p*scale1)*(1.-length(pow(abs(uv*2.),vec2(20.))));
    glFragColor = vec4(c,c*c,c*c*c,1.);
}
