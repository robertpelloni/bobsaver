#version 420

// original https://neort.io/art/bpmbquc3p9fbkbq83v60

uniform float time;
uniform vec2 resolution;
uniform sampler2D texture;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float volume = 0.2*pow(abs(sin(time*6.)),2.0);
  mat2 rot(float r){
    return mat2(cos(r),sin(r),-sin(r),cos(r));
  }

  vec2 pmod(vec2 p,float n){
    float np = acos(-1.)*2.0/n;
    float r = atan(p.x,p.y)-0.5*np;
    r = mod(r,np)-0.5*np;
    return length(p)*vec2(cos(r),sin(r));
  }

  float cylin(vec3 p,float r,float h){
  return length(vec2(length(p.xz)-r,max(abs(p.y)-h,0.0)));
  }

float dist(vec3 p){
  //p.z += time*2.0;
  p.zy *= rot(1.57*step(0.,sin(time)));
  p.xy *= rot(1.57*step(0.,cos(time)));
  if(fract(time)<0.5){
  for(int i = 0;i<4;i++){
    p = abs(p)-0.3;
    p.xy *= rot(0.3+mod(time,4.0));
      p.xz *= rot(0.3+mod(time,12.0));
  }
}
  float k = 1.0;
  p.y += time;
  p.y += 0.5;
  p.xz *= rot(p.y+time*8.);
  p.xz = pmod(p.xz,3.+floor(mod(time*10.,10.)));
  p.x -= 0.4;
  return cylin(p,0.002+volume*0.2,99999.);
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
  vec2 uv2 = uv;
  uv = (uv-0.5)*2.0;
  uv.y *= resolution.y/resolution.x;
  vec2 p = uv;
  vec3 ro = vec3(0.0,0.0,1.0);
  p *= rot(floor(time*2.));
  vec3 rd = normalize(vec3(p,0.0)-ro);
  float d=0.0;
  float t = 0.0;
  float ac = 0.0;
  for(int i = 0;i<66;i++){
    d = dist(ro+rd*t);
    d = max(d,0.001);
    ac += exp(-39.0*d);
    t +=d;
  }

vec3 col = 0.013*volume*27.*vec3(ac);
float s = 0.9;
uv2 - s*(uv2-0.5)+0.5;
  vec3 bcol = texture2D(backbuffer,uv2).xyz;
  col = mix(col,bcol,0.5);
  glFragColor = vec4(col,1.0);
}
