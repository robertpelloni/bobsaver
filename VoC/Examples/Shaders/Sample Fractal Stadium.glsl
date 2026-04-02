#version 420

// original https://www.shadertoy.com/view/wllBzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI acos(-1.0)
#define pmod(p,n)length(p)*sin(vec2(0.,PI*.5)+mod(atan(p.y,p.x),PI*2./n)-PI/n)
#define fold45(p)(p.y>p.x)?p.yx:p
#define rot(p,a)p*cos(a)+vec2(-p.y,p.x)*sin(a)

float orbit;
float map(vec3 p)
{
    float scale=3.;
    vec3 off=vec3(10,1.,.2);
    float s=2.,de;
    orbit=0.;
    for(int i=0;++i<9;)
    {
        p.xz=pmod(p.xz,5.);
        p.z-=.7;
        p.xz=abs(p.xz);
        p.xz=fold45(p.xz);
        p.z=1.-abs(p.z-1.);
        //p.z=abs(p.z-1.)-1;
        p.xy=fold45(p.xy);
        p-=off;
        p*=scale;
        p+=off;
        s*=scale;
        de=length(p)/s-.002;
        if(de<0.001)break;
        orbit++;
    }
    return de;
}
void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 p;
      vec3 ro=vec3(0,5,-1.+12.*fract(time*.1));
      vec3 w=normalize(vec3(0,.1,-1));
      vec3 u=normalize(cross(w,vec3(0,1,0)));
      vec3 rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    float h=0.,d,i;
    for(i=1.;i<100.;i++)
    {
        p=ro+rd*h;
        p.xz=rot(p.xz,time*.2);
        d=map(p);
        if(d<.0001||h>50.)break;
        h+=d;
    }
    glFragColor.xyz=25.*vec3(cos(vec3(.2,.8,.7)*orbit)+(cos(p.xyy)*.5+.5))/i;
}
