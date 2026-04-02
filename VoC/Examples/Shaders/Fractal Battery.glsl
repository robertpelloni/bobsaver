#version 420

// original https://www.shadertoy.com/view/3tlfDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Scale;

float map(vec3 p)
{
    float itr=10.,r=0.;
    if(fract(time*.3)>.7)
    {
        itr=3.+3.*step(0.,sin(3.*time+.5*sin(time*.7)));
        r=mix(.01,.002,step(5.,itr));
    }
    p=mod(p-1.5,3.)-1.5;
    p=abs(p)-1.3;
    if(p.x<p.z)p.xz=p.zx;
    if(p.y<p.z)p.yz=p.zy;
     if(p.x<p.y)p.xy=p.yx;
    float s=1.;
    p-=vec3(.5,-.3,1.5);
    for(float i=0.;i++<itr;)
    {
        float r2=2./clamp(dot(p,p),.1,1.);
        p=abs(p)*r2;
        p-=vec3(.7,.3,5.5);
        s*=r2;
    }
    Scale=log2(s);
    return mix(length(p),length(p.xy),step(0.,sin(2.*time+.3*sin(time*.5))))/s-r;
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
    glFragColor.xyz=12.*vec3(sin(Scale+p.yxx*.08)*.5+.5)/i;
}
