#version 420

// original https://www.shadertoy.com/view/Ndy3DV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void wave(inout float x, inout float y, inout float z, float T, int octaves)
{
    float R=8.;
    float S=.03;
    float W=-.05;
    #define RRRRS R*=.72;S*=1.27;W*=1.21;
    for(int s=0;s<octaves;s++)
    {
        float da=1.8+sin(T*0.021)*0.1+.41*sin(float(s)*.71+T*0.02);
        float dx=cos(da);
        float dy=sin(da);
        float t=-dot(vec2(x-320.,y-240.),vec2(dx,dy));
        float sa=sin(T*W+t*S)*R;
        float ca=cos(T*W+t*S)*R;

        x-=ca*dx*2.;
        y-=ca*dy*2.;
        z-=sa;
        RRRRS
    }
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy*vec2(640.,480.);
    float z=0.;
    wave(uv.x, uv.y, z, time*20., 17);
    z=z+22.;
    z*=0.018;
    vec3 col = vec3(.3+z*1.2,.2+z*.9,.1+z*.6);
    glFragColor = vec4(col,1.0);
}
