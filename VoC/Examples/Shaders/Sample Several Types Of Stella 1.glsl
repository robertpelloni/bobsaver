#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WsyfWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI atan(1.)*4.
#define TAU atan(1.)*8.

void lookAt(inout vec3 rd,vec3 ro,vec3 ta,vec3 up){
    vec3 w=normalize(ta-ro),u=normalize(cross(w,up));
    rd=rd.x*u+rd.y*cross(u,w)+rd.z*w;
}

void rot(inout vec3 p,vec3 a,float t){
    a=normalize(a);
    vec3 u=cross(a,p),v=cross(a,u);
    p=u*sin(t)+v*cos(t)+a*dot(a,p);   
}

// https://shadertoy.com/view/ltf3W2
#define sabs(p,k)sqrt(p*p+k)

// https://www.shadertoy.com/view/MsKGzw
// smoothing type
void sfold(inout vec3 p, float n, float k) 
{
    float c=cos(PI/n),s=sqrt(.75-c*c);
    vec3 v=vec3(-.5,-c,s);
    for(int i=0;i<5;i++)
    {
        p.xy=sabs(p.xy,k);
        float g=dot(p,v);
        p-=(g-sabs(g,k))*v;
    }
}

// https://www.shadertoy.com/view/WdfcWr
void sfold(inout vec2 p,float n, float k)
{
    float h=floor(log2(n)),a=TAU*exp2(h)/n;
    for(float i=0.;i<h+2.;i++)    {
         vec2 v=vec2(-cos(a),sin(a));
        float g=dot(p,v);
         p-=(g-sabs(g,k))*v;
         a*=.5;
    }
}

// p-=2.*min(0.,dot(p,v))*v;
// smooth type
void sfold(inout vec2 p, vec2 v, float k)
{
    float g=dot(p,v);
    p-=(g-sabs(g,k))*v;
}

// if(p.x<p.y)p.xy=p.yx;
// smooth type
void sfold45(inout vec2 p, float k)
{
    vec2 v=normalize(vec2(1,-1));
    float g=dot(p,v);
    p-=(g-sabs(g,k))*v;
}

float de0(vec3 p)
{
    float k=1e-3;
    p.z = sabs(p.z,k);
    sfold(p.xy,5.,k);
    vec3 v = normalize(vec3(2,1,3));
    return dot(p,v)-.6;
}

float de1(vec3 p)
{
    float k=5e-3;
    p=sabs(p,k);
    sfold45(p.xz,k);
    sfold45(p.yz,k);
    vec3 v = normalize(vec3(1,1,-1));
    return dot(p,v)-.7;
}

float de2(vec3 p)
{
    float k=5e-4;
    float n = 4.;
    sfold(p,n,k);
    vec3 v = normalize(vec3(1));
    return dot(p,v)-1.;
}

float de3(vec3 p)
{
    float k=5e-4;
    float n = 5.;
    sfold(p,n,k);
    vec3 v = normalize(vec3(0,1,1));
    return dot(p,v)-1.;
}

float de4(vec3 p)
{
    float k=5e-4;
    float n = 5.;
    sfold(p,n,k);
    vec3 v = normalize(vec3(1));
    return dot(p,v)-1.;
}

float de5(vec3 p)
{
    float k=3e-3;
    p=sabs(p,k);
    sfold45(p.xz,k);
    sfold45(p.yz,k);
    sfold45(p.xy,k);
    vec3 v = normalize(vec3(1,0,1));
    return dot(p,v)-1.;
}

float de6(vec3 p)
{
    float k=1e-3;
    p=sabs(p,k);
    sfold45(p.xz,k);
    sfold45(p.yz,k);
    sfold45(p.xy,k);
    vec3 v = normalize(vec3(2,3,1));
    return dot(p,v)-.9;
}

float de7(vec3 p)
{
    float k=3e-3;
    p=sabs(p,k);
    sfold45(p.xz,k);
    sfold45(p.yz,k);
    sfold45(p.xy,k);
    vec3 v = normalize(vec3(1,2,-1));
    return dot(p,v)-.9;
}

float map(in vec3 p)
{
    rot(p,vec3(cos(time*.3),sin(time*.3),1),time*.5);
    switch(int(mod(time,8.))) {
    case 0: return de0(p); break;
    case 1: return de1(p); break;
    case 2: return de2(p); break;
    case 3: return de3(p); break;
    case 4: return de4(p); break;
    case 5: return de5(p); break;
    case 6: return de6(p); break;
    case 7: return de7(p); break;
    }
    return 1.;
}

vec3 calcNormal(vec3 p)
{
  vec3 n=vec3(0);
  for(int i=0; i<4; i++){
    vec3 e=.001*(vec3(9>>i&1, i>>1&1, i&1)*2.-1.);
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
    return vec3(.3,.5,.8)+cos(p)*.5+.5;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    vec3 ro = vec3(0,0,5);
    vec3 rd = normalize(vec3(uv,2));
    vec3 ta =vec3(0);
    lookAt(rd,ro,ta,vec3(0,1,0));    
    vec3 col= vec3(0);
    const float maxd=50.;
    float t=march(ro,rd,0.,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=doColor(p); 
        vec3 n=calcNormal(p);      
        vec3 lightPos=ro+vec3(2,5,2);
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
        col+=vec3(.8,.6,.2)*pow(clamp(dot(reflect(rd,n),li),0.,1.),10.);
    }
    glFragColor.xyz=col;
}
