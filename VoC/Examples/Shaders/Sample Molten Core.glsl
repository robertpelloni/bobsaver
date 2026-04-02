#version 420

// original https://www.shadertoy.com/view/ld2BRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 f=glFragColor;
    f-=f;
    vec2 u=gl_FragCoord.xy/resolution.y*-4.+10.,t=vec2(3,1)*.0003*time+9.;
    float w=.04;
    for(int i=0;i<20;++i)
    {
        u=u*sin(t.x)+cos(t.y)*vec2(-u.y,u.x);
        u*=1.2+f.xy*.06;
        w*=.96;
        f+=w*(abs(sin(u.x))+abs(cos(u.y)));
    }
    f.x=sin(f.x*4.);
    f*=f;
    f*=f;
    glFragColor=f;
}
