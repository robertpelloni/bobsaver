#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tsGfzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void lookAt(inout vec3 rd,vec3 ro,vec3 ta,vec3 up){
    vec3 w=normalize(ta-ro),u=normalize(cross(w,up));
    rd=rd.x*u+rd.y*cross(u,w)+rd.z*w;
}

void rot(inout vec3 p,vec3 a,float t){
    a=normalize(a);
    vec3 u=cross(a,p),v=cross(a,u);
    p=u*sin(t)+v*cos(t)+a*dot(a,p);   
}

void sFold45(inout vec2 p)
{
    float e=2e-2;
    vec2 v=normalize(vec2(1,-1));
    float g=dot(p,v);
    p-=(g-sqrt(g*g+e))*v;
}

float frame(vec3 p)
{
    rot(p,vec3(cos(time*.3),sin(time*.3),1),time*.3);
    p=abs(p)-1.;
#if 1
    sFold45(p.xz);
    sFold45(p.yz);
    sFold45(p.xy);
#else
    if(p.x<p.z)p.xz=p.zx;
    if(p.y<p.z)p.yz=p.zy;
    if(p.x<p.y)p.xy=p.yx;
#endif
    p.x=abs(p.x)-.2;
    p.y=abs(p.y)-.2;
    p.y=abs(p.y)-.1;
    p.y=abs(p.y)-.1;
     return length(vec2(length(p.xz)-1.,p.y))-.05;
}

float map(vec3 p)
{
    return min(p.y+6.,frame(p));
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
    for(int i=0;i<100;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<.001) return t;
        if (t>=far) return far;
    }
    return far;
}

float calcShadow(vec3 light, vec3 ld, float len)
{
    float depth=march(light,ld,0.,len);    
    return step(len-depth,.01);
}

vec3 doColor(vec3 p)
{
    return vec3(.3,.5,.8)+cos(p*.2)*.5+.5;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    vec3 ro = vec3(0,1,7);
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
        vec3 lightPos=ro+vec3(0,3,0);
        vec3 li=lightPos-p;
        float len=length(li);
        li/=len;
        float dif=clamp(dot(n,li),0.,1.);
        float sha=calcShadow(lightPos,-li,len);
        col*=max(sha*dif,.2);
        float rimd=pow(clamp(1.-dot(reflect(-li,n),-rd),0.,1.),2.5);
        float frn=rimd+2.2*(1.-rimd);
        col*=frn*.6;
        col*=max(.5+.5*n.y,.3);
        col*=exp2(-2.*pow(max(0.,1.-map(p+n*.8)/.8),2.));
        col+=vec3(.8,.6,.2)*pow(clamp(dot(reflect(rd,n),li),0.,1.),10.);
        col-=dot(.0005*p,p);
    }
    glFragColor.xyz=col;
}
