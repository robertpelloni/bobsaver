#version 420

// original https://www.shadertoy.com/view/WttcWH

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
    vec3 u=cross(p,a),v=cross(a,u);
    p=u*sin(t)+v*cos(t)+a*dot(a,p);   
}

void rot(inout vec2 p,float t){
    p=p*cos(t)+vec2(-p.y,p.x)*sin(t);
}

#define hash(p)fract(sin(p*12345.5))

vec3 randVec(float s)
{
    vec2 n=hash(vec2(s,s+215.3));
    return vec3(cos(n.y)*cos(n.x),sin(n.y),cos(n.y)*sin(n.x));
}

vec3 randCurve(float t,float n)
{
    vec3 p = vec3(0);
    for (int i=0; i<3; i++){
        p+=randVec(n+=365.)*sin((t*=1.3)+sin(t*.6)*.5);      
    }
    return p;
}

#define sabs(p) sqrt((p)*(p)+1e-5)
#define smin(a,b) (a+b-sabs(a-b))*.5
#define smax(a,b) (a+b+sabs(a-b))*.5

float dodec(vec3 p,float r){
    float G=sqrt(5.)*.5+.5;
    vec3 n=normalize(vec3(G,1,0));
    float d=0.;
    p=sabs(p);
    d=smax(d,dot(p,n));
    d=smax(d,dot(p,n.yzx));
    d=smax(d,dot(p,n.zxy));
    return d-r;
}

float icosa(vec3 p,float r){
    float G=sqrt(5.)*.5+.5;
    vec3 n=normalize(vec3(G,1./G,0));
    float d=0.;
    p=sabs(p);
    d=smax(d,dot(p,n));
    d=smax(d,dot(p,n.yzx));
    d=smax(d,dot(p,n.zxy));
    d=smax(d,dot(p,normalize(vec3(1))));
    return d-r;
}

float stones(vec3 p)
{
    p.z-=time*1.5;
    p.y-=time;
    rot(p.xz,.3);
    float c=2.;
    vec3 e=floor(p/c);
    e = sin(1.0*(2.5*e+3.0*e.yzx+1.345)); 
    p-=e*.6;
    p=mod(p,c)-c*.5;
    rot(p,hash(e+166.887)-.5,time*1.5); 
    if(hash(dot(e,vec3(.234,.24,98))+16776.887)<.5)
    {
        return min(.5,icosa(p,.12));    
    }else{
        return min(.5,dodec(p,.12));    
    }
}

float gate(vec3 p){
     p.z-=time;
    float c=13.;
    float e=floor(p.z/(.5*c));
    p.z=mod(p.z,c)-.5*c;\
    c=13.;
    p.xy=mod(p.xy-.5*c,c)-.5*c;
    rot(p,randVec(e*1.233),.2*(hash(e+123.456)*2.-1.));
    vec3 q=p;
    p=abs(p)-3.8;
    if(p.x<p.y)p.xy=p.yx;
    if(p.y<p.z)p.yz=p.zy;
    if(p.z<p.x)p.zx=p.xz;
     
    float s=2.5;
    p=sabs(p);
    vec3  off = p*1.36;
    for (float i=0.; i<4.; i++){
        p=1.-abs(abs(p-2.)-1.); 
        float r=-4.*clamp(1.7*max(.75/dot(p,p),.47),.0,2.5);
        s*=r;
        p*=r;
        p+=off+normalize(vec3(2,7,15))*(6.-.5*i);
     }
    s=abs(s);
    float a=16.;
    p-=clamp(p,-a,a);
    
    q=abs(q)-vec3(3.6);
    if(q.x<q.y)q.xy=q.yx;
    if(q.y<q.z)q.yz=q.zy;
    if(q.z<q.x)q.zx=q.xz;
      float de=max(max(abs(q.y),abs(q.z))-1.8,length(p)/s);
    return min(.8,de);
}

float map(vec3 p){
    return min(stones(p),gate(p));
}

vec3 calcNormal(vec3 pos){
  vec2 e = vec2(1,-1) * 0.005;
  return normalize(
    e.xyy*map(pos+e.xyy)+e.yyx*map(pos+e.yyx)+ 
    e.yxy*map(pos+e.yxy)+e.xxx*map(pos+e.xxx)
  );
}

float march(vec3 ro, vec3 rd, float near, float far)
{
    float t=near,d;
    for(int i=0;i<120;i++)
    {
        t+=d=map(ro+rd*t);
        if (d<.001) return t;
        if (t>=far) return far;
    }
    return far;
}

float calcShadow( vec3 light, vec3 ld, float len ) {
    float depth=march(light,ld,0.,len);    
    return step(len-depth, .01);
}

vec3 doColor(vec3 p)
{
    if(stones(p)<.001)return vec3(1.2,1.3,1.5);
    return vec3(1);
}

vec2 billboardUv(vec3 ro,vec3 rd, vec3 a)
{
    a-=ro;
    vec3 g= cross(a, rd);
    vec3 up=normalize(cross(a,cross(a,vec3(0,1,0))));
    return vec2(dot(g,up),dot(g,cross(up,normalize(a))));
}

void main(void)
{
    vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/resolution.y;
    vec3 ro=vec3(sin(time*.2+sin(time*.2)*.2),sin(time*.2+sin(time*.1)*.1),5.);
    vec3 ta=vec3(sin(time*.3+sin(time*.5)*.2),sin(time*.1+sin(time*.2)*.4),0);
    vec3 rd=normalize(vec3(uv,1));
    lookAt(rd,ro,ta,vec3(0,1,0));   
    vec3 col=vec3(.2,.3,.6);
    const float maxd=20.;
    float t=march(ro,rd,.3,maxd);
    if(t<maxd)
    {
        vec3 p=ro+rd*t;
        col=doColor(p);
        vec3 n=calcNormal(p);      
        vec3 lightPos=vec3(5,28,10)*.5;
        vec3 li=lightPos - p;
        float len=length( li );
        li/=len;
        float dif=clamp(dot(n, li),.5,1.);
        float sha=calcShadow(lightPos,-li,len);
        col*=max(sha*dif, 0.8);
        float rimd=pow(clamp(1.-dot(reflect(-li,n),-rd),0.,1.),2.5);
        float frn=rimd+2.2*(1.-rimd);
        col*=frn*.5;
        col*=max(.5+.5*n.y,.0);
        col*=exp2(-2.*pow(max(.0,1.-map(p+n*.3)/.3),2.));
        col+=1.*vec3(.9,.5,.1)*pow(clamp(dot(reflect(rd,n),li),0.,1.),20.);      
        col=mix(vec3(.2,.3,.6),col,exp(-t*t*.005));
    }
    
    for(float i=0.;i<10.;i++)
    {
        vec3 p=vec3(0,0,i*2.);
        float c=floor(p.z*20.);
        p.z+=time;
        p.z=mod(p.z,20.)-15.2;
        if(dot(rd,p-ro)<t)
        {
            uv=  billboardUv(ro,rd,p)*10.;
            float de=1.,seed=c+i+1234.567;
            int iSeed=int(c+i)+18;
            for(int j=0;j<4;j++)
            {
                vec2 off=(vec2(hash(seed+=123.23),hash(seed+=143.6))*2.-1.)*8.;
                //de=min(de,deChar(uv-off,iSeed+=8));
            }
            col = mix(col, vec3(1), smoothstep(.05,.0,de)*exp(-t*t*.003));
        }
    }
    
    for(float i=0.;i<5.;i++)
    {
        vec3 p=(vec3(
            hash((i+142.3)*523.12),
            hash((i+112.3)*256.12),
            hash((i+612.3)*778.12)
            )*2.-1.)*vec3(7,5,1);
        p+=randCurve(time*.5+hash(i*2256.1234)*1000.,(i+67.234)*345.99)*2.5;
        float L=length(cross(rd,p-ro));
        col = mix(col, vec3(.8+.2*sin(time*12.),.6,.4), exp(-L*L*3.));
    }
    
    glFragColor = vec4(col,1);
}
