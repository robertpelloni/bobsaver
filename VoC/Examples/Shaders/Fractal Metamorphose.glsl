#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3dyBzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void rot(inout vec3 p,vec3 a,float t){
    a=normalize(a);
    vec3 u=cross(a,p),v=cross(a,u);
    p=u*sin(t)+v*cos(t)+a*dot(a,p);   
}

float scale;
float map(vec3 p){
     rot(p,vec3(cos(time*.07),sin(time*.06),sin(time*.05)*.5),time*.5+1.2*sin(time*.8));
    p.x-=10.;
    float s=2.;
    p=abs(p);
    for(int j=0;j++<8;){
        p=-sign(p)*(abs(abs(abs(p)-2.)-1.)-1.);
        float l=(-2.13+.3*sin(time*.7+.5*sin(time*.5)))
            /max(.43+.38*sin(time*.9+.3*sin(time*.8)),dot(p,p));
        s*=l;
        p*=l;
        p-=.55+.01*sin(time*1.2+.5*sin(time*.5));
    }
    scale=s;
    return dot(p,normalize(vec3(1,2,3)))/s;
}

vec3 calcNormal(vec3 p)
{
  vec3 n=vec3(0);
  for(int i=0; i<4; i++){
    vec3 e=.001*(vec3(9>>i&1,i>>1&1,i&1)*2.-1.);
    n+=e*map(p+e);
  }
  return normalize(n);
}

float march(vec3 ro, vec3 rd, float near, float far)
{
    float t=near,d;
    for(int i=0;i<90;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<.001) return t;
        if (t>=far) return far;
    }
    return far;
}

vec3 doColor(vec3 p)
{
    return cos(vec3(3,2,8)+log(scale*.003)+time*1.5)*.5+.5;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    vec3 ro = vec3(0,0,120);
    vec3 rd = normalize(vec3(uv,-2));
    vec3 col= min(vec3(.8),.8*vec3(.03,.02,.01)/length(uv*.4));
    const float maxd=150.;
    float t=march(ro,rd,30.,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=doColor(p); 
        vec3 n=calcNormal(p);      
        vec3 lightPos=ro+vec3(2,5,2);
        vec3 li=normalize(lightPos-p);
        float dif=clamp(dot(n,li),0.,1.);
        col*=max(dif,.2);
        float rimd=pow(clamp(1.-dot(reflect(-li,n),-rd),0.,1.),2.5);
        float frn=rimd+2.2*(1.-rimd);
        col*=frn*.4;
        col*=max(.5+.5*n.y,.3);
        col*=exp2(-2.*pow(max(0.,1.-map(p+n*.8)/.8),2.));
        col+=vec3(12,6,5)*pow(clamp(dot(reflect(rd,n),li),0.,1.),10.);
    }
    col*=1.5;
    glFragColor.xyz=col;
}
