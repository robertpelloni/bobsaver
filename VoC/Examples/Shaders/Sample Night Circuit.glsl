#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tdyBR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU atan(1.)*8.

void lookAt(inout vec3 rd,vec3 ro,vec3 ta,vec3 up){
    vec3 w=normalize(ta-ro),u=normalize(cross(w,up));
    rd=rd.x*u+rd.y*cross(u,w)+rd.z*w;
}

void pointAt(inout vec3 p, vec3 dir, vec3 up){
    vec3 u=normalize(cross(dir,up));
    p=vec3(dot(p,u),dot(p,cross(u,dir)),dot(p,dir));
}

void rot(inout vec3 p,vec3 a,float t){
    a=normalize(a);
    vec3 u=cross(a,p),v=cross(a,u);
    p=u*sin(t)+v*cos(t)+a*dot(a,p);   
}

void rot(inout vec2 p,float t){
    p=p*sin(t)+vec2(-p.y,p.x)*cos(t);
}

void pSFold(inout vec2 p,float n){
    float h=floor(log2(n)),a=TAU*exp2(h)/n;
    for(float i=0.;i<h+2.;i++)    {
         vec2 v=vec2(-cos(a),sin(a));
        float g=dot(p,v);
         p-=(g-sqrt(g*g+2e-3))*v;
         a*=.5;
    }
}

#define seed 2576.
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

vec3 orbit(float t,float n)
{
    vec3 p = randCurve(-t*1.5+time,seed)*5.;
    vec3 off = randVec(n)*(t+.05)*.6;
    float time=time+hash(n)*5.;
    return p+off*sin(time+.5*sin(.5*time));
}

float g1=0.,g2=0.,g3=0.;

float stella(vec3 p, float s)
{
    p=abs(p);
    if(p.x<p.z)p.xz=p.zx;
    if(p.y<p.z)p.yz=p.zy;
    return dot(p,normalize(vec3(1,1,-1)))-s;
}

float stellas(vec3 p)
{
    p.y-=-time;
    float c=2.;
    vec3 e=floor(p/c);
    e = sin(11.0*(2.5*e+3.0*e.yzx+1.345)); 
    p-=e*.5;
    p=mod(p,c)-c*.5;
    rot(p,hash(e+166.887)-.5,time*1.5); 
    return min(.8,stella(p,.08));
}

float structure(vec3 p)
{
    float d=1e3,d0;
    for(int i=0;i<12;i++){
        vec3 q=p,w=normalize(vec3(sqrt(5.)*.5+.5,1,0)); 
        w.xy*=vec2(i>>1&1,i&1)*2.-1.;
        w=vec3[](w,w.yzx,w.zxy)[i%3];
        pointAt(q,w,-sign(w.x+w.y+w.z)*sign(w)*w.zxy);
        
        d0=length(q-vec3(0,0,clamp(q.z,2.,8.)))-.4+q.z*.05;
        d=min(d,d0);
        g2+=0.1/(0.1+d0*d0); // Distance glow by balkhan
        
        float c=.8;
        float e=floor(q.z/c-c*.5);
        q.z-=c*clamp(round(q.z/c),3.,9.);
        
        q.z-=clamp(q.z,-.05,.05);
        pSFold(q.xy,5.);
        q.y-=1.4-e*.2+sin(time*10.+e+float(i))*.05;
        q.x-=clamp(q.x,-2.,2.);
        q.y-=clamp(q.y,-0.,.2);
        
        d0=length(q)*.7-.05;
        d=min(d,d0);
        if(e==2.+floor(mod(time*5.,7.)))
            g1+=0.1/(0.1+d0*d0);
    }
    return d;
}

float rabbit(vec3 p)
{
    p-=randCurve(time,seed)*5.;
    rot(p,vec3(1),time);
    float d=stella(p,.2);
    g3+=0.1/(0.1+d*d);
    return d;
}

float map(vec3 p){
    return min(min(stellas(p),structure(p)),rabbit(p));
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

vec3 doColor(vec3 p)
{
    if(stellas(p)<.001)return vec3(.7,.7,1);
    return vec3(1);
}

vec3 hue(float h)
{
    return cos((vec3(0,2,-2)/3.+h)*TAU)*.5+.5;
}

vec3 cLine(vec3 ro, vec3 rd, vec3 a, vec3 b)
{
    vec3 ab =normalize(b-a),ao = a-ro;
    float d0 = dot(rd, ab), d1 = dot(rd, ao), d2 = dot(ab, ao);
    float t = (d0*d1-d2)/(1.-d0*d0)/length(b-a);
    t= clamp(t,0.,1.);
    vec3 p = a+(b-a)*t-ro;
    return vec3(length(cross(p, rd)), dot(p,rd),t);
}

void main(void)
{
    vec2 p = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 col=vec3(.0,.0,.05);
    vec3 ro = vec3(1, 0, int[](7,10,12,15)[int(abs(4.*sin(time*.3+3.*sin(time*.2))))&3]);
    rot(ro,vec3(1),time*.2);
    vec3 ta = vec3(2,1,2);
    vec3 rd = normalize(vec3(p, 2.0));
    lookAt(rd,ro,ta,vec3(0,1,0));       
    float z=0.,d,i,ITR=50.0;
     for(i=0.; i<ITR; i++){
        z+=d=map(ro+rd*z);
        if(d < 0.001||z > 30.0) break;
      }
    if(d<.001)
      {
        vec3 p = ro+rd*z;
        vec3 nor = calcNormal(p);
        vec3 li = normalize(vec3(1,1,-1));
        col = doColor(p);
        col *= pow(1.-i/ITR,2.); 
         col *= clamp(dot(nor,li),.3,1.);
        col *= max(.5+.5*nor.y,0.2);
        col += vec3(0.8,0.1,0.)*pow(clamp(dot(reflect(normalize(p-ro),nor),normalize(vec3(-1,-1,-1))),0.,1.),30.);
        col += vec3(0.1,0.2,0.5)*pow(clamp(dot(reflect(normalize(p-ro),nor),normalize(vec3(1,1,-1))),0.,1.),30.);
        col=mix(vec3(0),col,exp(-z*z*.00001));
    }
    col+=vec3(0.9,0.1,0.)*g1*0.05;
    col+=vec3(0.,0.3,.7)*g2*0.08;
    col+=vec3(0.5,0.3,.1)*g3*0.15;
 
    vec3 de;
    ITR=40.;
    for(float i=0.; i<1.;i+=1./7.)
    {
        de = vec3(1e9);
        float off=hash(i*234.6+256.);
        for(float j=0.;j<1.;j+=1./ITR)
        {
            float t=j+off*0.5;
            vec3 c = cLine(ro, rd, orbit(t,off), orbit(t+1.0/ITR,off));
            if (de.x*de.x*de.y>c.x*c.x*c.y)
            {
                   de=c;
                   de.z = j + c.z/ITR;
            }
        }
        float s = pow(max(0.0,0.6-de.z),2.0)*0.1;
        if(de.y>0.&&z>de.y)
            col+=mix(vec3(1),hue(i),0.8)*(1.0-de.z*0.9)*smoothstep(s+0.17,s,de.x)*0.7;
    }
    col=pow(col,vec3(.8+.3*sin(time*.5+3.*sin(time*.3))));
    glFragColor.xyz = col;
}
