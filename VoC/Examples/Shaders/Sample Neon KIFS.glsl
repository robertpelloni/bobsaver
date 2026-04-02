#version 420

// original https://www.shadertoy.com/view/WttGR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution
#define T time
#define PI 3.14159265359
#define DtR PI/180.

float boxSDF(vec3 p, vec3 s, float r)
{
  p = abs(p);
  return max(max(p.x-s.x, p.y-s.y),p.z-s.z);
}

float sphereSDF(vec3 p, float r)
{
  return length(p)-r;
}

mat2 rot(float a)
{
  float ca = cos(a); float sa = sin(a);
  return mat2(ca, sa, -sa, ca);
}

float kifs(vec3 p)
{
  float d = 10000.;
  p.y-=2.;
  
 //d = boxSDF(p,vec3(1.,1.,1.),1.);
  
  p.y+=2.2;
  for(int i = 0; i < 5; ++i)
  {
    p-=.2;
    
    p.xy*=rot(T*.4);
    p.xz*=rot(T*.5);
    p-=.4;
    p=abs(p);
      d = min(d, boxSDF(p,vec3(.5,.5,.5),1.));    
  }
 
  return d;
}

float map(vec3 p)
{
  //p = mod(p-5.,10.)-5.;
  float s1 = kifs(p);
  
  return s1;
}

vec3 getNormal(vec3 p)
{
  vec2 e = vec2(0.001, 0);
  return normalize(vec3(map(p+e.xyy) - map(p-e.xyy),
                        map(p+e.yxy) - map(p-e.yxy),
                        map(p+e.yyx) - map(p-e.yyx))) * .5 + .5;
}

void main(void)
{  
  vec2 U = gl_FragCoord.xy;
  vec4 O = glFragColor;

  vec2 uv = (2.*U-R.xy)/R.y;
  vec3 t = vec3(0);
  
  float th = 45.*DtR;
  float ph = 1.;
  
  float r = 5.+sin(T*.5)*2.;
  vec3 p = vec3(r*sin(th)*cos(ph),r*cos(th)*sin(ph),r*cos(th));
  
  p.xz*=rot(-T*0.3);
  
  vec3 cz = normalize(t-p);
  vec3 cx = normalize(cross(cz, vec3(0,-1,0)));
  vec3 cy = normalize(cross(cz, cx));
  
  vec3 dir = normalize(vec3(uv.x*cx + uv.y*cy + cz));
  
  float d, att;
  for(int i = 0; i < 256; ++i)
  {
    d = map(p);
    if(d <.001) break;
    if(d > 1000.0)break;
    p+=d*dir;
    att+=0.2/(abs(d)+0.2);
  }
    
  // shade 
  vec3 n = getNormal(p);
  vec3 color = mix(vec3(0.), n, att*.06);
  
  if(d < 1000.)
  {
    color.rgb = n*n*vec3(.65,.52,0.61)-att*0.04;
  }
  
  color = pow(color, vec3(1.3));
  O.rgb = color;

  glFragColor = O;
}
