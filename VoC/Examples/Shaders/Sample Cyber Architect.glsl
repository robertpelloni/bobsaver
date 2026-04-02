#version 420

// original https://neort.io/art/bqr6o4s3p9f48fkis8h0

uniform vec2 resolution;
uniform vec2 mouse;
uniform sampler2D backbuffer;
uniform float time;

out vec4 glFragColor;
float bpm = 124.;
float pi = 3.141592;

mat2 rot(float r){
  return mat2(cos(r),sin(r),-sin(r),cos(r));
}

vec2 pmod(vec2 p,float n){
  float np = pi*2./n;
  float r = atan(p.x,p.y)-np;
  r = mod(r,np)-0.5*np;
  return length(p)*vec2(cos(r),sin(r));
}

float box(vec3 p,vec3 s){
  vec3 q = abs(p);
  vec3 m = max(s-q,0.);
  return length(max(q-s,0.))-min(min(m.x,m.y),m.z);
}

float hati(vec3 p,float s){
  return dot(abs(p),normalize(vec3(1)))-s;
}

float ring(vec3 p,float r){
  return abs(length(vec2(length(p.xy)-r,abs(p.z))))-0.015;
}

float easeInSine(float x){
  return 1. - cos((x * pi) / 2.);
}

float dist(vec3 p){
  vec3 cp = p;
  cp.yz *= rot(0.5);
  float src = 999.;
  for(int i = 0;i<5;i++){
    float srd = ring(cp,5.*easeInSine(fract(time+float(i)*0.2)));
    cp.yz *= rot(0.5);
    src = min(srd,src);
  }

  vec3 sp = p;
  float d1 = hati(p,0.3);
  sp.xz *= rot(0.7);
  vec3 sp2 = sp;
  sp.yz *= rot(0.4);
  sp.xz *= rot(-time*0.5);
  sp.xz = pmod(sp.xz,12.);
  sp.x -= 1.2;
  sp.yz *= rot(0.75);
  float d2 = hati(sp,0.1);

  sp2.yz *= rot(-0.4);
  sp2.xz *= rot(time*0.5+0.3);
  sp2.xz = pmod(sp2.xz,12.);
  sp2.x -= 1.2;
  sp2.yz *= rot(0.75);
  float d3 = hati(sp2,0.1);
  float d = min(min(d1,d2),d3);
  d = min(src,d);
  return d;
}

float dist2(vec3 p){
  p.z += 7.*time;
  float d2 = box(p,vec3(3.,3.,9999.));
  float d3 = box(p,vec3(3.5,3.5,9999.));
  float k = 1.;
  vec3 id = floor(p*vec3(k));
  p.x += 0.5*sin(time+id.y);
  p = mod(p,k)-0.5*k;

  float d1 = box(p,vec3(.35));
  return min(max(d1,-d2),-d3);
}

vec3 getnormal(vec3 p){
  vec2 e = vec2(0.001,0.0);
  return normalize(vec3(
    dist(p+e.xyy)-dist(p-e.xyy),
    dist(p+e.yxy)-dist(p-e.yxy),
    dist(p+e.yyx)-dist(p-e.yyx)
    ));
}

void main(){vec2 r=resolution,p=(gl_FragCoord.xy*2.-r)/min(r.y,r.x);
  vec2 uv = gl_FragCoord.xy/resolution.xy;
  float f = pow(abs(sin(pi*time*bpm/60.)),4.);
  float cr = 1.8;
  float ktr = time*0.3;
  vec3 ro = vec3(cr*cos(ktr),-0.5*sin(time*0.3),cr*sin(ktr));
  vec3 ta = vec3(0.,0.,0.);
  vec3 cdir = normalize(ta-ro);
  vec3 side = cross(cdir,vec3(0.,1.,0.));
  vec3 up = cross(side,cdir);
  float fov = 1.;
  vec3 rd = normalize(p.x*side+p.y*up+cdir*fov);
  float d2,d,t= 0.;
  float ac = 0.;
  for(int i = 0;i<106;i++){
    d = dist(ro+rd*t);
    d2 = dist2(ro+rd*t);
    
    ac += exp(-1.*d);
    
    t+=min(d,d2);
    
    if(min(d,d2)<0.001) break;
  }
  
  vec3 col = vec3(0.);

  vec3 ld = normalize(vec3(1.,1.,1));

  vec3 normal = getnormal(ro+rd*t);
  float alp = 0.9;
  float diff = pow(alp*max(dot(normal,ld),0.)+(1.-alp),2.0);
  
  if(d2<0.001) col += 0.5*vec3(diff);
  if(d<0.001) col += 0.7*vec3(diff);
  col += 0.4*ac*(f*0.6+0.3)*vec3(0.1,0.4,0.9);
  vec2 ue = vec2(0.002,0.0);
  vec3 bcol1 =texture2D(backbuffer,uv+ue).xyz;
  vec3 bcol2 =texture2D(backbuffer,uv-ue).xyz;
  vec3 bcol3 =texture2D(backbuffer,uv+ue.yx).xyz;
  vec3 bcol4 =texture2D(backbuffer,uv-ue.yx).xyz;
  vec3 bcolf = max(max(bcol1,bcol2),max(bcol3,bcol4));
  float suv = 0.99;
  uv = (uv-0.5)*suv+0.5;
  float far = 10.;
  float near = 0.;
  col = mix(vec3(0),col,clamp((far-t)/(far-near),0.0,1.0));
  vec3 bcol =texture2D(backbuffer,uv).xyz;
  col = mix(col,bcolf,0.6);
  glFragColor=vec4(col,1);
}
