#version 420

// original https://www.shadertoy.com/view/WtKcDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define sabs(p) sqrt((p)*(p)+.8)
void sfold90(inout vec2 p)
{
    p=(p.x+p.y+vec2(1,-1)*sabs(p.x-p.y))*.5;
}

float Scale;

float map(vec3 p)
{
    p=mod(p-1.5,3.)-1.5;
    p=abs(p)-1.3;
    sfold90(p.xz);
    sfold90(p.xz);
    sfold90(p.xz);
    
    float s=1.;
    p-=vec3(.5,-.3,1.5);
    for(float i=0.;i++<7.;)
    {
        float r2=2.1/clamp(dot(p,p),.0,1.);
        p=abs(p)*r2;
        p-=vec3(.1,.5,7.);
        s*=r2;
    }
    Scale=log2(s);
    float a=3.;
    p-=clamp(p,-a,a);
    return length(p)/s-.005;
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 p,
          ro=vec3(0,0,time),
          w=normalize(vec3(.3*sin(time*.5),.5,1)),
          u=normalize(cross(w,vec3(cos(time*.1),sin(time*.1),0))),
          rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    float h=0.,d,i;
    for(i=1.;i<80.;i++)
    {
        p=ro+rd*h;
        d=map(p);
        if(d<.001)break;
        h+=d;
    }
    glFragColor.xyz=15.*vec3(sin(Scale*.7+p.xyx*.28)*.5+.5)/i;
}
