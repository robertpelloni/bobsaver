#version 420

uniform vec2 resolution;
uniform vec2 mouse;
uniform float time;
uniform sampler2D backbuffer;

out vec4 glFragColor;
//19:35
float rand(vec2 p){
  return fract(sin(dot(p,vec2(12.9898,78.233)))*43578.543123);
}
float PI = acos(-1.);
float noise(vec2 st){
  vec2 i = floor(st);
  vec2 f = fract(st);
  
  float a = rand(i);
  float b = rand(i+vec2(1,0));
  float c = rand(i+vec2(0,1));
  float d = rand(i+vec2(1,1));
  
  vec2 u = f*f*(3.0-2.0*f);
  
  return mix(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.x*u.y;
}

float fbm(vec2 st){
  float v = 0.0;
  float a = 0.5;
  for(int i = 0;i<4;i++){
    v += a*noise(st);
    st *=2.0;
    a *= 0.5;
  }
  return v;
}
float cube(vec3 p,vec3 s){
  vec3 q = abs(p);
  vec3 m = max(s-q,0.0);
  return length(max(q-s,0.))-min(min(m.x,m.y),m.z);
}

mat2 rot(float r){
  return mat2(cos(r),sin(r),-sin(r),cos(r));
}

float cyl(vec3 p,float ln,float r){
  
  float s = max(length(p.xy)-r,0.);
  
  return length(vec2(max(abs(p.z)-ln,0.0),s))-min(max(ln-abs(p.z),0.),max(r-length(p.xy),0.));
  
}

float  calcZ(){
  float klt = mod(time*0.5,5.);
return 40.0*pow(sin(klt)*exp(-klt),1.);
}

float  calcsZ(){
  float klt = mod((time+0.7)*0.5,5.);
return 40.0*pow(sin(klt)*exp(-klt),1.);
}

vec4 dist(vec3 p){
  float k = 0.5;
  vec3 sp = p;
  
float d2 =999.;

p = sp;
float kt = 0.2*time;

p.xy += 1.*vec2(cos(kt),sin(kt));

p.xy *= rot(time*0.6+sin(time));

float ksz = calcZ();

p.z += ksz;

vec3 srp = p;

p.z -= 1.2;
float s6 = cyl(p,.4,0.1*(0.5-abs(p.z)));

p=srp;

p.x = abs(p.x)-1.;
p.xz *= rot(0.25*PI);
float d4 = cube(p,vec3(0.6,0.01,0.6));
p = srp;

p.z = abs(p.z)-1.;
float d5 = cube(p,vec3(4.0,100.,0.4));

d4 = max(d4,-d5);

p = srp;
p.xz *= rot(0.5*PI);
p.xy *= rot(-0.6);
p.zy *= rot(-0.5);
p.xz *= rot(2.05);

//d4 = min(d4,s6);

for(int i = 0;i<4;i++){
  vec3 ssp = p;
  p.xz *= rot(PI*0.25);

  d2 = cube(p,vec3(0.4,0.01,0.2));
  p = ssp;
  p.y += 0.05;
  p.xz *= rot(1.7);
  p.xy *= rot(PI*0.25); p.yz *= rot(PI*0.25);
  float d3 = cube(p,vec3(0.2,0.2,0.2)*0.6);
  d2 = min(d2,d3);
  p.x = abs(p.x)-0.07;
  p.z = abs(p.z)-0.2;
  p.y = abs(p.y)-0.2;
}

d2 = min(d4,d2);

  p = sp;

  p.z -= 5.*time;
  
  float d1 = p.y+3.+0.3*fbm(p.xz*4.)*noise(p.xz)+2.*noise(p.xz*0.5+100.);
  
  float d = length(p)-0.1;
  vec3 col = vec3(s6,d2,ksz);
  
  return vec4(col,min(d1,d2));
}

vec3 getNormal(vec3 p){
  vec2 e = vec2(0.001,0.0);
  return normalize(vec3(
    dist(p+e.xyy).w-dist(p-e.xyy).w,
    dist(p+e.yxy).w-dist(p-e.yxy).w,
    dist(p+e.yyx).w-dist(p-e.yyx).w
    
    ));
}

vec3 cloud(vec3 rd,vec3 col,float s){
  float acyz = length(rd.xz)/abs(rd.y);
  col = mix(col,vec3(0.3),fbm(time+s*vec2(rd.xz*2.*acyz)));
  col =  mix(col,vec3(0.1),fbm(time+s*vec2(rd.xz*4.*acyz)));
  col = mix(vec3(0.5),col,exp(-0.2*abs(acyz)));
  return col;
}

vec3 LightDir = normalize(vec3(0.0,-1.0,1.0));
vec3 getSky(vec3 rd){
  vec3 col = vec3(0.4,0.4,0.5);
  float sun = 0.004/(1.-dot(-rd,LightDir));
  col += clamp(sun,0.0,1.3);
  col = cloud(rd,col,1.0);
  return col;
}
void main(){vec2 r=resolution,p=(gl_FragCoord.xy*2.-r)/min(r.x,r.y);
vec2 uv = gl_FragCoord.xy/r;
float nt = fbm(p*10.3);

float krt = time*0.+0.5*PI;
float ra = 4.0;
float kss = 1.;
vec3 st = vec3(0);
float kf = max(calcsZ(),0.);
st = vec3(0,-2.-sin(time*0.7),-1)+0.3*vec3(fbm(vec2(time*kss)),fbm(vec2(time*kss+100.)),fbm(vec2(kss*time+1000.)));
if(mod(time,34.)>14.){
  st += vec3(0,sin(time*0.7)+4.,-calcZ());
  float kt= 0.2*time;
  st.xy += vec2(cos(kt),sin(kt));
  krt = time*0.2;
  ra = 1.;
}else{
  
}
vec3 ro =st+ vec3(cos(krt)*ra,0.5,ra*sin(krt));
vec3 ta = st+vec3(0,0,0);

vec3 cdir = normalize(ta-ro);
vec3 side = cross(cdir,vec3(0,1,0));
vec3 up = cross(side,cdir);
float fov = 1.;

vec3 rd = normalize(p.x*side+p.y*up+fov*cdir);

float d,t= 0.0;

vec4 tdr;

float thr = 0.001;

vec3 ac = vec3(0.);

for(int i =0;i<108;i++){
  tdr = dist(ro+rd*t);
  d = tdr.w;
  float sc = max(tdr.x,0.02);
  d = min(sc,d);
  t += d*0.7;
  ac += (1.0+3.0*max(tdr.z,-0.2))*exp(sc*-4.)*vec3(0.6,0.4,0.05)+0.15*exp(tdr.y*-1.)*vec3(0.3,0.4,0.6);
  if(thr>d||t>100.)break;
}
vec3 col = vec3(0.);
if(thr>d){
  vec3 normal = getNormal(ro+rd*t);
  
  float lm = max(dot(-LightDir,normal),0.);

  col = vec3(lm);
  
  col += ac*0.3;
  
  //col = cloud(-LightDir+0.*fbm((ro+rd*t).xz),col,100.);
  
  col = mix(vec3(getSky(normal+rd*0.01).y),col,exp((-0.3*fbm((ro+rd*t).xz-vec2(0,2.*time)))*t));
  col = mix(col,vec3(0.49),1.-clamp(exp(-0.05*(t-5.)),0.0,1.0));
  
}else{
  if(thr<d) col = getSky(rd);
}

col =mix(col,texture2D(backbuffer,uv).xyz,0.3+0.05*kf);

glFragColor=vec4(col,1);
  
}
