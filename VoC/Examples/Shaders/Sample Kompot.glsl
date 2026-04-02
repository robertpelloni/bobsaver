#version 420

// original https://www.shadertoy.com/view/tl2XWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14158
#define TAU PI*2.
#define t time*.13

float sphere (vec3 p, float r) { return length(p)-r; }
float cyl (vec2 p, float r) { return length(p)-r; }
float sdBox(vec3 p,vec3 b)
{ vec3 d=abs(p)-b; return length(max(d,0.)) +min(max(d.x,max(d.y,d.z)),0.);// remove this line for an only partially signed sdf
}
vec3 moda (vec2 p, float count) {
  float an = TAU/count;
  float a = atan(p.y,p.x)+an/2.;
  float c = floor(a/an);
  a = mod(a,an)-an/2.;
  c = mix(c, abs(c), step(count/2., abs(c)));
  return vec3(vec2(cos(a),sin(a))*length(p),c); 
}
mat2 rot (float a) { float c=cos(a),s=sin(a); return mat2(c,-s,s,c); }

float smin (float a, float b, float r) {
  float h = clamp(.5+.5*(b-a)/r, 0.,1.);
  return mix(b,a,h)-r*h*(1.-h);
}

float map (vec3 p);

vec3 normal (vec3 p){
  float e = 0.01;
  return normalize(vec3(map(p+vec3(e,0,0))-map(p-vec3(e,0,0)),
  map(p+vec3(0,e,0))-map(p-vec3(0,e,0)),
map(p+vec3(0,0,e))-map(p-vec3(0,0,e))));
}

float iso (vec3 p, float r) { return dot(p, normalize(sign(p)))-r; }

float map (vec3 p) {
  p.xy *= rot(t);
  p.yz *= rot(t*.5);
  p.xz *= rot(t*.3);
  p.xz *= rot(p.y*.3+t);

  float cyl2 = cyl(p.xz, .3+.8 * (.5+.5*sin(p.y*1.+t*10.)));
  float a = atan(p.y,p.x);
  float l = length(p.xy);
  float c = 1.;//   10
  p.x = mod(abs(l*.95-4.)+t*1., c)-c/2.;
  //p.y = cos(a)*10.;

  vec3 p1 = moda(p.xz, 8.);//      20
  float wave1 = sin(t*10.+p.y*0.5+p1.z);
  p1.x -= 2.+(.5+.5*wave1);
  p.xz = p1.xy;
  float celly = 3.;
  vec3 p2 = p1;
  p.y = mod(p.y+t*10.+p1.z,celly)-celly/2.;
  float sph1 = sphere(p, 0.2+.2*(.5+.5*sin(p.y+t*10.)));
  float cyl1 = cyl(p.xz, 0.2*wave1+.02);
  float box=sdBox(p-vec3(0,-wave1,0),vec3(2.*.125));
  float box1=sdBox(p-vec3(0,0,0),vec3(.3+.8*(.5+.5*sin(t*10.))));
  float scene=smin(cyl1,box,.3);
  scene=smin(scene,cyl2,.3);
    
  p.y = mod(p.y+t*10.,celly)-celly/2.;
  float iso1 = iso(p,0.2+.2*wave1);
  scene = smin(scene, iso1, .13);
  return scene;
}
void main(void)

{
  vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
  vec3 eye = vec3(uv, -5.), ray = (vec3(uv,.5)), pos = eye;
  int ri = 0;
  for (int i = 0; i < 50; ++i) {
    float dist = map(pos);
    if (dist < 0.01) {
      break;
    }
    pos += ray*dist;
    ri = i;
  }
  vec3 n = normal(pos);
  float ratio = float(ri)/50.;
  vec4 color = vec4(1.);
  color.rgb = n*.5+.5;
  color.rgb *= 1.- ratio;
  glFragColor = vec4(color.rgb,1.0);

}
