#version 420

// original https://www.shadertoy.com/view/NdV3Dw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Geometry by Tater
//-------------------------------------------------------------
#define pi 3.1415926535
#define STEPS 500.0
#define MDIST 200.0
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define pmod(p,x) (mod(p,x)-0.5*(x))
float h21(vec2 a){
    return fract(sin(dot(a,vec2(453.2734,255.4363)))*994.3434);
}
vec3 rdg;
float box(vec3 p, vec3 b){
    vec3 d= abs(p)-b;
    return max(d.x,max(d.y,d.z));
}
float t; vec3 glw;

vec2 mp(vec3 p)
{  
  vec3 po = p;
    vec2 a = vec2(1);
    vec2 b = vec2(2);
    float t =time;
    p.x+=t;
    
    float m = 2.;
    
    vec2 id3 = floor(p.xz/m)+0.5;
    p.x+=id3.y;
    vec2 id2 = floor(p.xz/m)+0.5;
    float hash =h21(mod(id2,100.0));
    p.y+=(hash-0.5);
    id2*=rot(-pi/6.0);
    p.y+=sin(id2.x+t)*0.7;
    p.y+=sin(id2.x*0.6+t)*0.4;
    p.y+=sin(id2.x*0.3+t)*0.2;
    id2*=rot(pi/6.0)*0.3;
    p.y+=sin(id2.y+t)*0.7;
    po = p;
    float dc = 0.;
    {
        vec3 p2=p/vec3(m);
        vec3 id = floor(p2);
        vec3 dir = sign(rdg)*.5;
        vec3 q = fract(p2)-.5;
        vec3 rc = (dir-q)/rdg;
        rc*=m;
        dc = min(rc.x,min(rc.y,rc.z))+0.01;
    }
    p.xz = pmod(p.xz,m);
    t+=hash*200.;
    float spd = .025;
    t*=spd;
    float lscl = m;
    float le = -mod(t * lscl,lscl); 
    float tscl = 650.; 
    float te = tscl - mod(t * tscl,tscl); 
    float scl = 0.; 
    float id = 0.;
    float npy = 0.;
    bool mid = false;
        if(p.y > le && p.y < te){ 
            npy = mod(p.y-le,tscl);
            scl = mix(tscl,lscl,min(fract(t)*2.0,1.0));
            mid = true;
            id = floor(t);
        }
        if(p.y<le){ 
            npy = mod(p.y-le,lscl);
            id = floor((p.y-le)/lscl)+floor(t);
            scl = lscl;
        }
        if(p.y>te){ 
            npy = mod(p.y-te,tscl);           
            id = floor((p.y-te)/tscl)+floor(t)+1.0; 
            scl = tscl;
        }
        npy-=scl*0.5;
        p.y = npy;
    
    a.x = length(p)-m*0.98*0.5;
    b.x = length(p)-0.15*m;
    b.x = max(-po.z-16.,b.x);
    glw+=((0.01/(0.01+b.x*b.x))/35.)*m;
    
    a.x = max(-po.z-16.,a.x);
    a.x = min(a.x,dc);
    
    if(mid)a.x = min(a.x,max(-(-po.y+le),0.1));
    a.y = id+100.;
    return a;
}

//Lighting and vfx by me!
//--------------------------------------------------
vec2 tr(vec3 ro, vec3 rd, float f)
{
  vec2 d = vec2(0);
  for(int i = 0; i < 128; i++)
  {
    vec3 p=ro+rd*d.x;
    vec2 s=mp(p);s.x*=f;
    d.x+=s.x;d.y=s.y;
    if(d.x>64.||s.x<0.001)break;
  }
  if(d.x>64.)d.y=0.;return d;
}

vec3 nm(vec3 p)
{
  vec2 e = vec2(0.001,0); return normalize(mp(p).x-vec3(mp(p-e.xyy).x,mp(p-e.yxy).x,mp(p-e.yyx).x));
}

vec4 px(vec4 h, vec3 rd, vec3 ro, vec3 n,vec4 bg)
{
  if(h.a==0.)return bg; 
  h.a=mod(h.a,3.)+1.;
  vec4 a=h.a==1.?vec4(0.600,0.204,0.996,0.2):h.a==2.?vec4(0.000,0.431,1.000,0.3):vec4(0.761,0.239,1.000,0.4); 
  float d=dot(n,-rd);
  float dd=max(d,0.); 
  float f=clamp(pow(1.-d,4.),0.,1.);
  float s=(pow(abs(dot(reflect(rd,n),-rd)),40.)*10.);
  if(h.a>1.)s*=0.05;
  vec4 col = vec4(mix(a.rgb*dd+s,bg.rgb,f),a.a); 
  col.rgb = pow(col.rgb,vec3(0.6));;
  col.rgb = mix(col.rgb,bg.rgb,clamp(length(h.xyz-ro*0.5)/50.,0.,1.));
  return col;
}

void main(void)
{
  t=time;
  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  uv -= 0.5; uv /= vec2(resolution.y / resolution.x, 1.); 
  float ts=1.,io=1.15;
  vec3 ro = vec3(1,10,-25);
  vec3 lk = vec3(1.01,2,0);
  vec3 f = normalize(lk-ro);
  vec3 r = normalize(cross(vec3(0,1,0),f));
  vec3 rd = normalize(f*0.95+uv.x*r+uv.y*cross(f,r));
  vec4 bg = vec4(mix(vec3(0.102,0.239,0.557),vec3(0.678,0.565,0.996),max(rd.y+0.6,0.)),1.);
  rdg=rd;vec3 rog=ro;
  vec3 oro=ro,ord=rd,cp,cn,rc,cc;
  for(int i=0;i<3;i++)
  {
    vec2 fh=tr(oro,ord,1.);
    cp=oro+ord*fh.x;cn=nm(cp);
    vec4 c=px(vec4(cp,fh.y),ord,oro,cn,bg);
    if(fh.y==0.||c.a==1.) {cc=mix(cc,c.rgb,ts); break;}
    ro=cp-cn*0.01;rd=refract(ord,cn,1./io);
    vec2 bh=tr(ro,rd,-1.);
    cp=ro+rd*bh.x;cn=nm(cp);
    oro=cp+cn*0.01;ord=refract(rd,-cn,io);
    if(dot(ord,ord)==0.)ord=reflect(rd,-cn);
    cc=mix(cc,c.rgb,ts);ts-=c.a;
    if(ts<=0.)break;
  }
  cc = mix(cc+glw,bg.rgb,clamp(length(oro-rog*0.5)/60.,0.,1.));
  glFragColor=vec4(cc,1.);
}
//-------------------------------------------------------------------------
