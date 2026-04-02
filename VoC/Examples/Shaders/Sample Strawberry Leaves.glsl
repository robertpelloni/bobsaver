#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tffzl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a)mat2(cos(a),sin(a),-sin(a),cos(a))

float orbit;
float map(vec3 p)
{
    p.xz*=rot(time*.2);
      float s = 4.;
    for(int i = 0; i < 8; i++)
    {
        p=mod(p-1.,2.)-1.;
        float r2=(i%3==0)?1.5:1.2/dot(p,p);
        p*=r2;
        s*=r2;
    }
    orbit=log2(s*.05);
    vec3 q=p/s;
    q.xz=mod(q.xz-.002,.004)-.002;
    return min(length(q.yx)-.0003,length(q.yz)-.0003);
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
      vec3 ro=vec3(
        mix(.9,.3,sin(time*.2+.3*sin(time*.5))*.5+.5),
        mix(-.6,.6,cos(time*.1+.5*cos(time*.7))*.5+.5),
        0);
      vec3 w=normalize(-ro);
      vec3 u=normalize(cross(w,vec3(0,1,0)));
      vec3 rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    vec3 p;
    float h=0.,d,i;
    for(i=1.;i<120.;i++)
    {
        p=ro+rd*h;    
        d=map(p);
        if(d<.0001)break;
        h+=d;
    }
    glFragColor.xyz=25.*vec3(cos(vec3(.3,.8,.7)*orbit))/i;
}
