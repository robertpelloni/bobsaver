#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wsGfWw

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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

#define hash(p)fract(sin(p*12345.5))

vec3 randVec(float s)
{
    vec2 n=hash(vec2(s,s+215.3))*TAU;
    return vec3(cos(n.y)*cos(n.x),sin(n.y),cos(n.y)*sin(n.x));
}

// https://shadertoy.com/view/ltf3W2
#define sabs(p,k)sqrt((p)*(p)+k)

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
    sfold(p,v,k);
}

float map(vec3 p){
    rot(p,vec3(cos(time*.07),sin(time*.02),sin(time*.05)*.5),time*.5);
    float k=.02;
    float itr=8.;
    float t=time*.08;
    vec3 axis=randVec(hash(floor(t)*23.45+123.4+date.y));
    for(float i=0.;i<itr;i++)
    {
        p=abs(p)-1.;
        sfold45(p.xz,k);
        sfold45(p.yz,k);
        sfold45(p.xy,k);
        rot(p,axis,fract(t)*TAU);
        p*=2.;
      }
      return length(p.xy)/exp2(itr)-.01;
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
    return cos(vec3(7,6,4)+p*.5)*.5+.5;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    vec3 ro = vec3(0,0,6);
    vec3 rd = normalize(vec3(uv,2));
    vec3 ta =vec3(0);
    lookAt(rd,ro,ta,vec3(0,1,0));    
    vec3 col= vec3(0,0,.05);
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
    col*=1.5;
    glFragColor.xyz=col;
}
