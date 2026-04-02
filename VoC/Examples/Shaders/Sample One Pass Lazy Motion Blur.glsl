#version 420

// original https://www.shadertoy.com/view/tsGcD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rnd(float x){return fract(sin(x * 1100.082) * 13485.8372);}
mat2 rot(float a){float s=sin(a),c=cos(a);return mat2(c,-s,s,c);}
float sdTorus( vec3 p, vec2 t ){vec2 q = vec2(length(p.xz)-t.x,p.y);return length(q)-t.y;}

vec2 Rot2D (vec2 q, float a){return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);}
vec3 IcosSym (vec3 p)
{
  float dihedIcos = 0.5 * acos (sqrt (5.) / 3.);
  float a, w;
  w = 2. * 3.1415 / 3.;
  p.z = abs (p.z);
  p.yz = Rot2D (p.yz, - dihedIcos);
  p.x = - abs (p.x);
  for (int k = 0; k < 4; k ++) {
    p.zy = Rot2D (p.zy, - dihedIcos);
    p.y = - abs (p.y);
    p.zy = Rot2D (p.zy, dihedIcos);
    if (k < 3) p.xy = Rot2D (p.xy, - w);
  }
  p.z = - p.z;
  a = mod (atan (p.x, p.y) + 0.5 * w, w) - 0.5 * w;
  p.yx = vec2 (cos (a), sin (a)) * length (p.xy);
  p.x -= 2. * p.x * step (0., p.x);
  return p;
}

float mp(vec3 p) {
  p.z+=1.5;
  float scale = 1.;
  // THE MOTION BLUR HAPPENS HERE ↓
  float t = time-0.15*rnd(p.y*3.3+p.x*7.7);
  p.xy *=rot(floor(t)+smoothstep(0.,.4,fract(t)));
  p.xz *=rot(floor(t)+smoothstep(.5,.9,fract(t)));
  for(int i=0; i<1; i++){
    scale*=3.;
    p*=3.;
    p = IcosSym(p);
    p.z+=3.;
    p.y-=.7;
  }
  return sdTorus(p,vec2(.5,.2))/scale;
}

vec3 nor(vec3 p){
 vec2 e=vec2(0,.001);
 return normalize(vec3(
  mp(p+e.xxy)-mp(p-e.xxy),
  mp(p+e.xyx)-mp(p-e.xyx),
  mp(p+e.yxx)-mp(p-e.yxx)
  ));
}

void main(void) {
  float ii, d=0.,rm,i; vec3 p,n;
  float mx = max(resolution.x, resolution.y);
  vec2 uv = (2.*gl_FragCoord.xy-resolution.xy) / mx;
  for(float i=0.;i<90.;i++){
    ii = float(i);
    p=d*vec3(uv,.9);
    p.z-=3.5;
    rm=mp(p);
    if(rm<.001)break;
    d+=rm;
  }
  n=nor(p).bgr;
  vec3 col1 = vec3(63,232,130)/255.;
  vec3 col2 = vec3(0,71,255)/255.;
  vec3 col = mix(col1, col2, (n.x+n.y)/2.+.5);
  glFragColor = vec4(col*10./(ii*d*d),1.);
}
