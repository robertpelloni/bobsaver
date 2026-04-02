#version 420

// original https://www.shadertoy.com/view/ttj3zR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI acos(-1.0)
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec2 fold(vec2 p, int n)
{
    p.x=abs(p.x);
    vec2 v=vec2(0,1);
    for(int i=0;i<n;i++)
    {
        p-=2.0*min(0.0,dot(p,v))*v;
        v=normalize(vec2(v.x-1.0,v.y));
    }
    return p;    
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float map(vec3 p)
{
#if 1
    float A=5.566;
    float c=7.0;
    p=mod(p,c)-c*0.5;
    p.xz=fold(p.xz,5);
    for(int i=0;i<5;i++)
    {
        p.xy=abs(p.xy)-2.0;
        p.yz=abs(p.yz)-2.5;
        p.xy*=rot(A);
        p.yz*=rot(A*0.5);
        p=abs(p)-2.0;
    }
#endif

    vec2 s=vec2(0.05,0.02);
    float h=0.08;
    float de=1.0;
    vec3 q=p;
    q.xy=fold(q.xy,5);
    q.y-=2.;
    q.x-=clamp(q.x,-h,h);
    de=min(de,sdTorus(q,s));
    q=p;
    q.xy*=rot(PI/exp2(5.0));
    q.xy=fold(q.xy,5);
    q.y-=2.0;
    q.x-=clamp(q.x,-h,h);
    de=min(de,sdTorus(q.xzy,s));
    return de;
}

void main(void)
{
    vec2 uv=(gl_FragCoord.xy*2.0-resolution.xy)/resolution.y;
    vec3 ro=vec3(0,1,3);
    ro.xz*=rot(time*0.2);
    vec3 ta=vec3(1,sin(time*0.7),1);
    vec3 w=normalize(ta-ro);
    vec3 u=normalize(cross(w,vec3(0,1,0)));
    vec3 rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    vec3 col=vec3(0);
    vec3 p=ro;
    for(float i=1.0;i>0.0;i-=1.0/80.0)
    {
         float d=map(p);
        if(d<0.001)
        {
            col+=i*i;
            break;
        }
        p+=d*rd;
    }
    glFragColor = vec4(col,1.0);
}
