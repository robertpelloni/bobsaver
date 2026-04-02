#version 420

// original https://www.shadertoy.com/view/tssczf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a), sin(a), -sin(a), cos(a))
#define hsv(h,s,v) ((clamp(abs(fract(h+vec3(0,2,1)/3.0)*6.0-3.0)-1.0,0.0,1.0)-1.0)*s+1.0)*v
#define opRepLim(p,s,l) p-s*clamp(round(p/s),-l,l);

vec2 billboardUv(vec3 ro,vec3 rd, vec3 a)
{
    a-=ro;
    vec3 g= cross(a, rd);
    vec3 up=normalize(cross(a,cross(a,vec3(0,1,0))));
    return vec2(dot(g,up),dot(g,cross(normalize(a),up)));
}

vec2 pmod(vec2 p, float r)
{
    float a=mod(atan(p.y,p.x),6.2831/r)-0.5*6.2831/r;
    return length(p)*vec2(sin(a), cos(a));
}

float map(vec3 p)
{   
    p.x-=sin(p.z*1.5+time*0.3)*0.05;
    p.y-=cos(p.z*1.5+time*0.3)*0.05;
    p.z-=time*3.0;
    float c=2.0;
    p.z=mod(p.z,c)-c*0.5;
    float de=1e9;
    p.xy=pmod(p.xy,6.0);
    p.y-=0.2+sin(time*0.5+sin(time*0.2)*0.8)*0.5;
    p.y=opRepLim(p.y,1.5,3.0);
    for(int i=0;i<3;i++)
    {
        p.xy=abs(p.xy)-0.5;
        p.xz=abs(p.xz)-0.3;
        p.xy*=rot(1.2+sin(time*0.3)*0.5);
        p.xz*=rot(0.8+sin(time*0.6));
    }
    p.xy*=rot(time*0.2+sin(time*0.5)*0.8);
    p.xz*=rot(time*0.3+sin(time*1.5)*1.8);
    p = abs(p)-vec3(0.3);
    if (p.x<p.z) p.xz = p.zx;
    if (p.y<p.z) p.yz = p.zy;
    p.z=max(0.0,p.z);
    return min(de,length(p)-0.0035);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy)/resolution.y;
    float len=length(uv)*0.05;
    vec3 ro=vec3(0,0,3);
    vec3 w=normalize(-ro);
    vec3 u=normalize(cross(w,vec3(0,1,0)));
    vec3 v=cross(w,u);
    vec3 rd=mat3(u,v,w)*normalize(vec3(uv,2));
    vec3 col = vec3(0);
    
    float depth = 5.0;
    float near = 1.0;
    float itr = 600.0;
    float pitch = (depth-near)/itr;
    for(float i=0.0; i<itr; i++)
    {
        depth-=pitch;
        vec3 p=ro+w*depth;
        vec2 uv=billboardUv(ro,rd,p);
        p+=u*uv.x+v*uv.y; 
        float de=map(p);
        if (de<0.001)
        {
            col=vec3(exp(-(depth-near)*0.7));
          }
        else
        {    
            col+=hsv(time*0.3+len,15.0*len,0.012)*exp(-de*4.5)*exp(-depth*depth*0.25);
        }
    }
    
    col=clamp(col,0.0,1.0);
    col=pow(col,vec3(2.5));
    glFragColor = vec4(col,1.0);
}
