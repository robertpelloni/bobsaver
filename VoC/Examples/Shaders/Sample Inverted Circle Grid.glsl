#version 420

// original https://www.shadertoy.com/view/Msd3zH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.283185
#define A(a) if(a>.25)a=.5-a;
vec2 R;

vec2 rot(vec2 uv,float teta)
{
    vec2 t=vec2(cos(teta),sin(teta));
    return uv*mat2(t,-t.y,t.x);
}

vec3 image(vec2 uv,bool inv,out float d)
{
    uv.x*=R.x/R.y;
    d=length(uv);
    uv/=4.5*sin(time)+5.5;
    uv=rot(uv,mod(time,TAU));
    if(inv)
        uv*=pow(.4/length(uv),2.);
    uv=mod(abs(uv),.5);
    A(uv.x) A(uv.y)
    return vec3(sqrt(max(.0,1.-4.*length(uv))));
}

void main(void)
{
    R=resolution.xy;
    vec2 uv=2.*gl_FragCoord.xy/R-1.;
    float d;
    if (uv .x<.0)
        glFragColor.xyz=image(2.*uv+vec2(1,0),false,d);
    else
        glFragColor.xyz=image(uv-vec2(.5,0),true,d)*d;
}
