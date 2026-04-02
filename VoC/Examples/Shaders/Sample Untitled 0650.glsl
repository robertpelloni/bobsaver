#version 420

// original https://www.shadertoy.com/view/NsKGzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time mod(time,30.)
float PI = acos(-1.);

mat2 rot(float r){
    return mat2(cos(r),sin(r),-sin(r),cos(r));
  }

float box(vec3 p,vec3 s){
  vec3 q = abs(p);
  vec3 m = max(s-q,0.);
  return length(max(q-s,0.))-min(min(m.x,m.y),m.z);
  }
  
  vec2 pmod(vec2 p,float n){
    float np = 2.0*PI/n;
    float r = atan(p.x,p.y)-0.5*np;
    r = mod(r,np)-0.5*np;
    return length(p)*vec2(cos(r),sin(r));
    }
  
  
  vec3 modfunc(vec3 p,float ss){
    p.xz = pmod(p.xz,6.);
    p.x -= ss;
    return p;
    }

vec4 dist(vec3 p){
  if(time>24.&&time<30.) p.z += 6.,p.y += 20.*time;
  float kz = 30.;
  if(time>18.&&time<24.)p = modfunc(p,22.);
  if(time>24.&&time<30.)p = modfunc(p,22.),p.y = mod(p.y,kz)-0.5*kz;
 
  float slllt = time;
  if(time>24.&&time<30.)slllt = 23.9;
  float sct = floor(mod(slllt*0.5,3.))+clamp(mod(slllt*1.5,3.),0.0,1.0);
  if(time>24.&&time<30.)slllt =time;
  float ksst = slllt+0.1;
    
  float sca = floor(ksst*0.5)+clamp(mod(ksst*1.5,3.),0.0,1.0);
  float spt = 0.56+sct;
    float d = box(p+vec3(0.,-0.3,-1.),vec3(spt*4.));
  
  float dc = 0.1;
  for(int i = 0;i<1;i++){    
    p = sin(clamp(p,-spt*PI,spt*PI))-0.1;
    p.xz *= rot(0.3+sca);
    p.yz *= rot(0.4+sca);
    p.xy *= rot(sca);
    p = abs(p)+0.;
    }
    d = max(d,box(p-vec3(0.3,0.6,0.3),vec3(0.2,0.5,0.2)));
    
        
    p = sin(clamp(p,-spt*PI,spt*PI))-0.1;
    p.xz *= rot(0.3+sca);
    p.yz *= rot(0.4+sca);
    p.xy *= rot(sca);
    p = abs(p)+0.;
    vec3 sssp = p;
    
        p = sin(clamp(p,-spt*PI,spt*PI))-0.1;
    p.xz *= rot(0.3+sca);
    p.yz *= rot(0.4+sca);
    p.xy *= rot(sca);
    p = abs(p)+0.;
    
    vec3 sc = vec3(0.02)+0.04*sin(PI*clamp(mod(time*1.5,3.),0.0,1.0));
    sc += p.zxy*0.1+0.1*sssp;
    sc *= 0.5;
  vec3 col =sc;
  return vec4(col,d);
  }

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 p =uv- 0.5;
    p /= vec2(resolution.y / resolution.x, 1);
  float ra = 20.0;
  if(time<6.) {ra = 20.0;}
  else if(time<12.){ra = 10.0;}
  if(time>18.&&time<24.) ra = 40.;
  if(time>24.&&time<30.) ra = 1.3;
  float rh =5.5;
  if(time>12.&&time<18.)rh = 10.;
  if(time>18.&&time<24.)rh = 14.;
  if(time>24.&&time<30.)rh = 5.3;
  float kt = time*0.3;
  vec3 ro = vec3(ra*cos(kt),rh,ra*sin(kt));
  vec3 ta = vec3(0);
  
  
  
  vec3 cdir = normalize(ta-ro);
  vec3 side = cross(cdir,vec3(0,1,0));
  vec3 up = cross(side,cdir);
  float fov = 0.6;
  vec3 rd = normalize(side*p.x+up*p.y+fov*cdir);
  float d,t = 0.0;
  float esp = 0.00001;
  vec3 col = vec3(0.0);
  vec3 ac = vec3(0.0);
  for(int i = 0;i<127;i++){
    vec4 rsd = dist(ro+rd*t);
    d = rsd.w;
    t += d;
    if(d<esp) break;
    ac += exp(-3.0*d)*rsd.xyz;
    }
  
  col = 0.6*vec3(ac);
  
  col = pow(clamp(col,0.,1.),vec3(1.3));
    
  vec3 fincol =col;// vec3(p,0.);
  
   glFragColor = vec4(fincol,1.);
}

