#version 420

// original https://www.shadertoy.com/view/3l3GRN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define T time
#define PI 3.141593
#define E 0.001
#define R resolution
#define MD 100.
#define GS 10.

mat2 rot(float a){ float ca = cos(a); float sa = sin(a); return mat2(ca,sa,-sa,ca);}
float cylSDF(vec3 p, float r){return length(p.yz)-r;}

float kifs(vec3 p)
{
  for(int i = 0; i < 10; ++i)
  {    
    float t1 = T;
    
    p.xy *=rot(t1*0.2);
    p.yz *= rot(t1*.07);
 
    p = abs(p);
    p-= vec3(.1,.2,.1);
  }
  
  float g = 1.0;
  p.x = mod(p.x-g*.5,g)-g*.5;
  
  return cylSDF(p, .05);
}

float sceneSDF(vec3 p)
{
  return kifs(p); 
}

float raycast(in vec3 p,in vec3 dir,out float att)
{
  float d = 0.;
  for(int i= 0; i <= 256; ++i)
  {
   d = sceneSDF(p);
   if(d <= E) break;
   if(d > MD) break;
   p += dir * d;
   att+= .1/(abs(d)+.1);
  }

  return d;
}

void main(void)
{
  vec2 uv = (2.*gl_FragCoord.xy-R.xy)/R.y;
  vec4 color = vec4(0);
  
  vec3 eye = vec3(0,0,-3.8);
  
  vec3 dir = normalize(vec3(uv,1));
  dir.xy *= rot(T*.2);
  
  float att = 0.;
  
  float d = raycast(eye, dir, att);
  
  color.rgb += att*.06 * vec3(.05,.03,.95);
  color.rgb = pow(color.rgb, vec3(0.4545));
  color *= 1.1-length(uv/GS); 
  
  glFragColor = color;
}
