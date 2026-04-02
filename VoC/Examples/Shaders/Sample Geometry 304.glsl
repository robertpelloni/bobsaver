#version 420

// original https://www.shadertoy.com/view/Dd23DV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265

vec3  rot(vec3 p,vec3 a,float t)
{
    a=normalize(a);
    return mix(a*dot(p,a),p,cos(t))+sin(t)*cross(p,a);
}

#define sabs(x) sqrt(x*x+5e-4)

// https://www.shadertoy.com/view/MsKGzw
vec3 foldVec(float t){
    vec3 n=vec3(-.5,-cos(PI/t),0);
    n.z=sqrt(1.-dot(n,n));         // normalize
    return n;
}

vec3 fold(vec3 p, float t)
{
    vec3 n=foldVec(t);
    for(float i=0.; i<t; i++){
        p.xy=sabs(p.xy);
        float g=dot(p,n);
        p-=(g-sabs(g))*n;
    }
    return p;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float map(vec3 p)
{
    p=rot(p,vec3(cos(time*.3),sin(time*.5),.5*sin(time*.2)),time*.7);
    float s=1.,e;
    p = fold(p,5.);
    p.z-=.3;
    e=1.5;
      p*=e;
      s*=e;
    p = fold(p,3.);
    p.z-=1.;
      e=1.6;
      p*=e;
      s*=e;
    p = fold(p,4.);
    p.z-=1.;
    p=rot(p,vec3(1,0,0),-PI/2.*(sin(time)*.5+.5));
    vec3 a=vec3(.1,.4,.1);
    return (sdBox(p,a)-.05)/s;
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
    return vec3(.7,.5,.3)+cos(p*2.)*.5+.5;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    vec3 ro = vec3(0,0,-5);
    vec3 rd = normalize(vec3(uv,3));
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
        float dif=clamp(dot(n,li),0.1,1.);
        col*=max(dif,0.);
        float rimd=pow(clamp(1.-dot(reflect(-li,n),-rd),0.,1.),2.5);
        float frn=rimd+2.2*(1.-rimd);
        col*=frn*.8;
        col*=max(.5+.5*n.y,.1);
        col*=exp2(-2.*pow(max(0.,1.-map(p+n*.8)/.8),2.));
        col+=vec3(.8,.6,.2)*pow(clamp(dot(reflect(rd,n),li),0.,1.),10.);
    }
    col=pow(col,vec3(1./2.2));
    glFragColor.xyz=col;
}
