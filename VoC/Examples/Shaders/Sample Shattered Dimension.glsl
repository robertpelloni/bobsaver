#version 420

// original https://www.shadertoy.com/view/Ws2Szz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Shattered dimention
// Inspired by the Riftborn intro from ES2
// https://www.youtube.com/watch?v=h8H8DedCW_I
//
// Disclamier: I work at Amplitude at the moment =)

#define time (time)

#define PI 3.14159
#define TAU (PI * 2.)

#define RID(p, r) (floor((p + r/2.) / r))
#define REP(p, r) (mod(p + r/2., r) - r/2.)

float hash( float n ) {
    return fract(sin(n)*43758.5453);
}

float noise( in vec3 x ) { // in [0,1]
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f*f*(3.-2.*f);

    float n = p.x + p.y*57. + 113.*p.z;

    float res = mix(mix(mix( hash(n+  0.), hash(n+  1.),f.x),
                        mix( hash(n+ 57.), hash(n+ 58.),f.x),f.y),
                    mix(mix( hash(n+113.), hash(n+114.),f.x),
                        mix( hash(n+170.), hash(n+171.),f.x),f.y),f.z);
    return res;
}

mat2 rot(float a)
{
  float ca = cos(a); float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float sdPlane(vec3 p, vec4 n)
{
  return dot(p,n.xyz) - n.w;
}

float solid(vec3 p, float s)
{
  float dist = -1000.;
  vec3 dir = vec3(0.,1.,0.);
  float h = 3.;
  float v = 6.;
  mat2 hr = rot(TAU / h);
  mat2 vr = rot(TAU / v);

  for(float j = 0.; j < v; ++j)
  {
    for(float i = 0.; i < h; ++i)
    {
      float ran = (hash(s + j * i)-.5) ;
      dist = max(dist,sdPlane(p, vec4(dir,1. + ran)));
      dir.xz *= hr;
    }

    dir.yz *= vr;
  }

  return dist;
}

float map(vec3 p)
{

  vec3 cp = p;

  vec3 pid = RID(p, 80.);
  p = REP(p, 80.);
  p.xy *= rot(pid.z * .5);
  p.zy *= rot(pid.x * .5);
  p.xz *= rot(pid.y * .5);

  p.z -= time;

  p.y += 2.;
  p.xy *= rot(p.z * .1);
  p.y -= 2.;

  p.xy *= rot(time * .05);

  float dist = 1000.;

  p *= 2.;
  float r = 6.;

  vec3 id = RID(p, r);
  p = REP(p , r);

  float nois = noise(id);
  float t = time * (nois + .2); ;

  p.xz *= rot(t);
  p.xy *= rot(t * .5);
  p.yz *= rot(t * .25);
  dist = solid(p, nois) *.25;

  dist = max(dist, length(id.xy) - 2.);

  return dist;
}

void ray(inout vec3 cp,vec3 rd, out float st, out float cd)
{
  for(st = 0.; st < 1.; st += 1./200.)
  {
    cd = map(cp);
    if(cd < .01)
      break;
    cp += rd * cd * .75;
  }
}  

vec3 normal(vec3 p)
{
  vec2 e = vec2(.05,.0);
  float d = map(p);
  return normalize(vec3(
    d - map(p + e.xyy),
    d - map(p + e.yxy),
    d - map(p + e.yyx)
  ));
}

vec3 lookAt(vec3 eye, vec3 tar, vec2 uv)
{
  vec3 fd = normalize(tar - eye);
  vec3 ri = cross(fd, vec3(0.,1.,0.));
  vec3 up = cross(ri,fd);
  return normalize(fd + ri * uv.x + up * uv.y);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / resolution.x, gl_FragCoord.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);

  vec3 eye = vec3(10.,10.,-20.);
  vec3 tar = vec3(0.);
  vec3 rd = lookAt(eye, tar, uv);
  vec3 cp = eye;
  float st,cd;
  ray(cp,rd,st,cd);

  float dist = length(eye - cp);

  glFragColor = mix(vec4(1.), vec4(.6,.6,.65,1.), pow((gl_FragCoord.x / resolution.x * .75 + .1), 1.2));
  if(cd < .01)
  {
    vec3 norm = normal(cp);
    vec3 ld = normalize(vec3(1.,-1.,1.));
    float li = dot(norm,ld);
    glFragColor = mix(
        glFragColor,
        mix(vec4(.75,.75,.74999,1.), vec4(.4,.4,.52,1.), li),
        exp(-distance(cp,eye) * .007));
  }
  
  glFragColor = pow(glFragColor, vec4(2.2));
}
