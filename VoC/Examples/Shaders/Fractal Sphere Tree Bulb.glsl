#version 420

// original https://www.shadertoy.com/view/WtfyRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//TGlad's SphereTree fractal mod by eiffie of a mclarekin DE
#define rez resolution.xy
vec3 mcol=vec3(0.0);
#define dot2(a) dot(a,a)
float InvSc=.4,FF=0.95;
bool bOutChk=false;
// a mod of a mod of tglad's sphereTree distance estimation function from mclarekin then I simplified some 
float DE(vec3 p0) { 
  vec3 orbitTrap=vec3(1000);
  vec4 p=vec4(p0,1.);
  const float root3 = 1.732050807, root3d2 = 0.8660254, t = 0.53333334, M=2.15;  
  const vec2 t1 = vec2(root3d2, -0.5), t2 = vec2(-root3d2, -0.5);
  const mat2 mx=mat2(.8660254,.5,-.5,.8660254);//cos(sqrt(.75)) or pi/6
  p.z=abs(p.z)+0.1725;//more sphere than tree now
  for (int i = 0; i < 7; i++) {  
    if(bOutChk){vec3 pC = p.xyz-vec3(0,0,t); if (dot(pC, pC) > t*t) break;} // definitely outside 
    float invSC = InvSc / dot(p.xyz,p.xyz); 
    p *= invSC;
    p.z -= 1.0; 
    p.z *= -1.0;
    p *= root3;
    p.z=abs(p.z+.5)+.5;
    p.xy=mx*p.xy;//rotate
    // now modolu the space so we move to being in just the central hexagon, inner radius 0.5  
    vec2 p2=mod(vec2(dot(p.xy,-t1.yx),dot(p.xy,-t2.yx))*M/root3,1.0); 
    if (p2.x + p2.y > 1.0) p2=vec2(1.)-p2; 
    p.xy = p2.x*t1 - p2.y*t2;
    // fold the space to be in a kite 
    float l0 = dot2(p.xy), l1 = dot2(p.xy-t1), l2 = dot2(p.xy+t2); 
    if (l1 < min(l0,l2)) p.xy -= t1 * (2.0*dot(t1, p.xy) - 1.0); 
    else if (l2 < min(l0,l1)) p.xy -= t2 * (2.0 * dot(p.xy, t2) + 1.0); 
    p.z *= InvSc;
    orbitTrap = min(orbitTrap, abs(p.xyz)); 
  }
  if(mcol.x>0.)mcol+=vec3(1.0)+3.*(orbitTrap.zzx+orbitTrap.zyx);
  float d = (length(p.xyz-vec3(0,0,0.4)) - 0.4); // the 0.4 is slightly more averaging than 0.5 
  d = (sqrt(d + 1.0) - 1.) * 2.0; 
  return FF*d / p.w; 
} 

vec3 normal(vec3 p, float d){//from dr2
  vec2 e=vec2(d,-d);vec4 v=vec4(DE(p+e.xxx),DE(p+e.xyy),DE(p+e.yxy),DE(p+e.yyx));
  return normalize(2.*v.yzw+vec3(v.x-v.y-v.z-v.w));
}
vec3 sky(vec3 rd, vec3 L){
  float d=max(0.,0.4+0.6*dot(rd,L));
  return pow(vec3(d*d*d*d,d*d*0.5,d-pow(d*d,10.0)),vec3(.2));
}
float rnd=0.;
float rand(){rnd=fract((rnd+1.62340)*342.123);return rnd;}
void randomize(in vec2 p){rnd=fract(float(time)+sin(dot(p,vec2(13.34,117.71)))*4231.76);}

float ShadAO(in vec3 ro, in vec3 rd){
 float t=0.01*rand(),s=1.0,d,mn=0.01;
 for(int i=0;i<6;i++){
  d=max(DE(ro+rd*t)*1.5,mn);
  s=min(s,d/t+t*0.5);
  t+=d;
 }
 return s;
}
vec3 scene(vec3 ro, vec3 rd){
  float t=DE(ro)*rand(),d,od=1.,px=1.0/rez.y;
  vec4 edge=vec4(0,0,-1,-1);
  for(int i=0;i<199;i++){
    d=DE(ro+rd*t);
    if(d<px*t*t*.5 && d>od){if(edge.x<0.){edge=vec4(edge.yzw,t);break;}else {edge=vec4(edge.yzw,t);t+=px*t*t;}}
    t+=d;od=d;
    if(t>10.0)break;
  }
  if(d<px*t*t*.5)edge=vec4(edge.yzw,t);
  vec3 L=vec3(0,0,1);
  vec3 col=sky(rd,L);
  for(int i=0;i<4;i++){
    if(edge.w>0.){//valid distance, color back to front
      mcol=vec3(0.01);
      float d=DE(ro+rd*edge.w);
      if(d<0.)d*=2.;
      vec3 so=ro+rd*(edge.w+d);
      vec3 N=normal(so,px*edge.w);
      vec3 scol=mcol*0.2;
      float dif=0.5+0.5*dot(N,L);
      float vis=clamp(dot(N,-rd),0.05,1.0);
      float fr=pow(1.-vis,5.0);
      float shad=ShadAO(so,L);
      col=mix((scol*dif+fr*sky(reflect(rd,N),L))*shad,col,clamp(0.8*d/(px*edge.w*edge.w*.5),0.,1.));
    }
    edge=edge.wxyz;
  }
  return col;
}
mat3 lookat(vec3 fw){fw=normalize(fw);vec3 up=vec3(0,0,1);vec3 rt=normalize(cross(fw,up));
  return mat3(rt,cross(rt,fw),fw);
}
void main(void) {
  vec2 U=gl_FragCoord.xy;
  vec2 uv=vec2(U-0.5*rez)/rez.x;
  randomize(U);
  float t=time;
  vec3 ro=vec3(cos(t),sin(t*1.1),0.5+0.5*sin(t*.7));
  vec3 rd=lookat(-ro)*normalize(vec3(uv.xy,1.0));
  t=mod(t,60.);
  if(t<20.){InvSc=.5;FF=0.75;bOutChk=true;}
  else if(t<40.){InvSc=1.;FF=0.45;bOutChk=true;}
  glFragColor=vec4(scene(ro,rd),1.0);
}
