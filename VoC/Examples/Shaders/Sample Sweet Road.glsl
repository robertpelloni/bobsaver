#version 420

// original https://www.shadertoy.com/view/WllfzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Scale;
float map(vec3 p)
{
   float s=2.;
    for(int i = 0; i < 4
        ; i++) {
        p=mod(p-1.,2.)-1.;
        float r2=1.2/dot(p,p);
        p*=r2;
        s*=r2;
    }
    Scale=log2(s);
    p = abs(p)-0.8;
    if (p.x < p.z) p.xz = p.zx;
    if (p.y < p.z) p.yz = p.zy;
    if (p.x < p.y) p.xy = p.yx;
    return length(cross(p,normalize(vec3(0,.5,1))))/s-Scale*.0015;
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 p,
          ro=vec3(1.,1.,time),
          w=normalize(vec3(.1*sin(time*.5),.3,1)),
          u=normalize(cross(w,vec3(cos(-time*.16),sin(-time*.16),0))),
          rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    float h=0.,d,i;
    for(i=1.;i<100.;i++)
    {
        p=ro+rd*h;
        d=map(p);
        if(d<.0001)break;
        h+=d;
    }
    glFragColor.xyz=35.*vec3(vec3(.7,.9,.7)*cos(Scale*.3)+(cos(p.xyy)*.5+.5))/i;
}
