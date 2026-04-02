#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3ldyRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI atan(1.)*4.
#define TAU atan(1.)*8.

vec3 lookAt(vec3 rd,vec3 ro,vec3 ta,vec3 up){
    vec3 w=normalize(ta-ro),u=normalize(cross(w,up));
    return rd.x*u+rd.y*cross(u,w)+rd.z*w;
}

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))

vec3 ta;
float g1=0.;

#define sabs(x,k)sqrt((x)*(x)+k)
vec2 sFold90(vec2 p, float k)
{
    return (p.x+p.y+vec2(1,-1)*sabs(p.x-p.y,k))*.5;
}

float doragonSpine(vec3 p)
{
    p.z-=time*4.;
    float s=1.;
    float c=1.2;
    p.z=mod(p.z,c)-.5*c;
    for(float i=0.;i<3.;i++){
        p=abs(p)-.25;
        p.yz=sFold90(p.yz,1e-3);
        p.xz=sFold90(p.xz,1e-3);
        p.xy=sFold90(p.xy,1e-3);
        p-=vec3(3.3,-1.,.3);
        p.xy*=rot(.23);
        p.yz*=rot(-.05);
        p.z+=.6;
        float b=.06;
        p=b-abs(abs(p-2.*b)-b);
        p*=2.;
        s*=2.;
    }
    p/=s;
    float h=.6;
    p.x-=clamp(p.x,-h,h);
    return max(abs(length(p.xy)-.7)-.03,abs(p.z)-.007);
}

float stella(vec3 p)
{
    p-=ta+vec3(
        cos(time*.5+cos(time*.3)*.3),
        sin(time*.5+sin(time*.5)*.2),
        cos(time*.3+cos(time*.3)*.5)*.3
        );
    p.xy*=rot(time*1.);
    p.xz*=rot(time*1.);
    float k=1e-3;
    p=sabs(p,k);
    p.xz=sFold90(p.xz,k);
    p.yz=sFold90(p.yz,k);
    p.xy=sFold90(p.xy,k);
    vec3 v = normalize(vec3(2,3,1));
    return dot(p,v)-1.;
}

float map(vec3 p)
{
    float de=stella(p);
    g1+=.5/(.1+de*de); // Distance glow by balkhan    
    return min(de,doragonSpine(p));
}

vec3 calcNormal(vec3 p)
{
  vec3 n=vec3(0);
  for(int i=0; i<4; i++){
    vec3 e=.01*(vec3(9>>i&1, i>>1&1, i&1)*2.-1.);
    n+=e*map(p+e);
  }
  return normalize(n);
}

float march(vec3 ro, vec3 rd, float near, float far)
{
    float t=near,d;
    for(int i=0;i<70;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<.001) return t;
        if (t>=far) return far;
    }
    return far;
}

vec3 doColor(vec3 p)
{
    if(stella(p)<.001)return vec3(0);
    return vec3(.0,.2,.3);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    ta=vec3(cos(time*.5+1.3*cos(time*.3))*4.,sin(time*.3)*4.,0);
    vec3 ro=vec3(sin(time*.3)*4.,cos(time*.4+.5*cos(time*.3))*4.,2.5);
    vec3 rd=lookAt(normalize(vec3(uv,1)),ro,ta,vec3(0,1,0));
    vec3 col= vec3(.02,.02,.06);
    const float maxd=50.;
    float t=march(ro,rd,0.3,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=doColor(p); 
        vec3 n=calcNormal(p);      
        vec3 lightPos=ro+vec3(2,15,2);
        vec3 li=lightPos-p;
        float len=length(li);
        li/=len;
        float dif=clamp(dot(n,li),0.,1.);
        col*=max(dif,.2);
        float rimd=pow(clamp(1.-dot(reflect(-li,n),-rd),0.,1.),2.5);
        float frn=rimd+2.2*(1.-rimd);
        col*=frn*.6;
        col*=max(.5+.5*n.y,.3);
        col*=exp2(-2.*pow(max(0.,1.-map(p+n*.8)/.8),2.));
        col+=vec3(.7,.2,.1)*pow(clamp(dot(reflect(rd,n),li),0.,1.),10.);
        col=mix(vec3(0),col,exp(-t*t*.01));
        if(stella(p)<.001)g1*=.1;
    }
    g1*=.1;
    col+=vec3(.9,.3,0.)*smoothstep(0.,1.,g1);
    col+=vec3(.5,.4,0.)*smoothstep(.2,.9,g1*.1);
    glFragColor.xyz=col;
}
