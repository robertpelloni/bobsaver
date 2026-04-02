#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void rotate(inout vec2 v,float angle);
vec2 rotateRe(vec2 v,float angle);
vec3 camera(vec2 v,vec3 pos);
void march(vec3 dir,vec3 pos);

#define BLACKBODY
#define FAR 10.0
#define NEAR 1.0
#define PI acos(-1.0)
#define PI2 (acos(-1.0)*2.0)
#define repeat(m,n) (mod(m,n*2.0)-n)
#define itime repeat(time,PI)

float minS=1.0;
float maxS=1.2;
float bounseSp=3.0;

float bounse;

void main() {
  glFragColor=vec4(0.0);
  vec2 uv = (gl_FragCoord.xy*2.0-resolution)/min(resolution.x,resolution.y);
  float k=exp(bounseSp*sin(itime*8.0))/exp(bounseSp);
  bounse=k*(maxS-minS)+minS;
//  vec3 pos =vec3(0.0,0.0,-5.0);
  vec3 pos= 5.0*vec3(sin(itime/2.0),0.0,cos(itime/2.0));
  rotate(pos.yx,itime);
  rotate(pos.yz,itime);

  vec3 dir = camera(uv,pos);

march(dir,pos);
glFragColor.a=1.;
}

void rotate(inout vec2 v,float angle){
  v=vec2(cos(angle)*v.x-sin(angle)*v.y,sin(angle)*v.x+cos(angle)*v.y);
}

vec2 rotateRe(vec2 v,float angle){
  return vec2(cos(angle)*v.x-sin(angle)*v.y,sin(angle)*v.x+cos(angle)*v.y);
}

vec3 camera(vec2 v,vec3 pos){
float fov =1.0;
vec3 forw =-normalize(pos);

vec3 right=normalize(vec3(rotateRe(forw.xz,asin(-1.0)),0.0).xzy);
vec3 up   =normalize(cross(forw,right));

return normalize(right*v.x+up*v.y+fov*forw);
}

float sphere(vec3 p){
return abs(length(p)-0.35);
}

float box(vec3 p){
  vec3 b= vec3(2.0)*bounse;
  return length(max(abs(p)-b,0.0));
}

float map(vec3 p){
float rep=.5*bounse;

float distBox=box(p);
float distSphere=sphere(repeat(p,rep));
//return (distBox>0.1)?distBox:max(sphere(mod(p,rep)-vec3(rep/2.0)),distBox);

//glFragColor+=(distBox<0.0001)?(vec4(0.007,.0005,0.001,0.000000000001)/pow(distSphere,2.0))*.05:vec4(0.0);
glFragColor+=(vec4(0.007,.0005,0.001,0.000000000001)/pow(distSphere,2.0))*.05;

//  return distBox;
  return max(distSphere,distBox);
}

void march(vec3 dir,vec3 pos){
vec2 dist=vec2(NEAR,0.0);
vec3 p   =vec3(0.0);

for(int i=0;i<64;i++){
  p=pos+dir*dist.x;
  dist.y=map(p);
  if(dist.y<0.01||dist.x>FAR){
    #ifdef BLACKBODY
      vec4 shapeC=vec4(-17.0,-2.0,-2.0,1.0);
    #else
      vec4 shapeC=vec4(1.0);
    #endif
  vec4 farC  =vec4(0.0);
    glFragColor+=(dist.x<FAR)?shapeC:farC;
  break;
  }
  dist.x+=dist.y*0.6;
}
}
