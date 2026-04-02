#version 420

// original https://neort.io/art/bpabe2c3p9f4nmb8amp0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float pi = acos(-1.);

mat2 rot(float a)
{
  float c =cos(a), s = sin(a);
  return mat2(c,s,-s,c);
}

float box(vec3 p, vec3 r)
{
  p = abs(p) -r;
  return max(max(p.x,p.y),p.z);
}

vec3 rep(vec3 p, float r)
{
  return mod(p,r)- 0.5*r;
}

float ifsbox(vec3 p)
{
  for(int i=0;i<3;i++)
  {
    p = abs(p)-2.;
  }
  return box(rep(p,9.),vec3(1.,4.,3.));
}

vec3 hsv(float h, float s, float v)
{
  return ((clamp(abs(fract(h+vec3(0.,2.,1.)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;
}

float map(vec3 p)
{
    p.xy *= rot(pi * 0.5);
  float d = ifsbox(p-vec3(0.,0.,-time*40.));

  return d;
}

void main()
{
  vec2 p = (gl_FragCoord.xy*2.-resolution) / min(resolution.x, resolution.y);

  vec3 cameraPos = vec3(0., 0., -20.);
  vec3 rayDir = normalize(vec3(p, 1.));

  vec3 col = vec3(1.);

  float depth = 0.;
  float acc =0.;

  for(int i =0; i <100; i++)
  {
    vec3 rayPos = cameraPos + rayDir*depth;
    float dest = map(rayPos);

    dest = max(abs(dest),0.1);

    float a = exp(-dest*9.);

    if(mod(rayPos.z - time*100., 90.)< 30.)
    {
      a *= 8.;
    }

    acc += a;

    depth += dest;
    
  }
  col = hsv(fract(time*0.2), 0.6, acc*0.01);

  glFragColor = vec4(col,1.);
}
