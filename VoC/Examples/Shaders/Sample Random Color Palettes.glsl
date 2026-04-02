#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;

float hashX(float n) { return fract(tan(n)*1.1); }

float noise2(in vec2 x)
{
  vec2 p = floor(x);
  vec2 f = fract(x); 
  float n = p.x + p.y*12.0;
  return mix(mix(hashX(n),     hashX(n+1.), f.x)
            ,mix(hashX(n+7.0), hashX(n+18.0), f.x), f.y);
}

#define OCTAVES 3
#define CHART true

// fractional brownian motion
float fbm(vec2 p, float f)
{
  float a = 0.0;
  float w = 1.0;
  float wc = 0.0;
  p *= f;
  for(int i=0; i<OCTAVES; i++)
  {
    a += noise2(p) * w;    
    w *= 0.5;
    wc += w;
    p = p * 2.0;
  }
  return a / wc;
}

float ris(float v)
{
  return (fbm(vec2(v, .0), 5.) * 2.0 - 1.0) * 0.1;
}

vec3 randomPaletteColor(vec2 pos)
{
  vec3 h = vec3(ris(pos.x*0.511)
           ,ris(pos.x*0.5111+15.75)
           ,ris(pos.x*0.51111+2.3317));
  float fit = 1.0;
  if (CHART) 
  { 
    float dist = pos.y+ris(pos.x);
    dist /= length(vec2(dFdx(dist), dFdy(dist)));
    fit = smoothstep(0.3, 0.7, sqrt(abs(dist)*.3));    
  }
  vec3 v = (1.0 - vec3(fit) * sqrt(3.*abs(h)));
  return v*v;
}

void main( void ) 
{
  vec2 pos = surfacePos*vec2(3.,1.0) + vec2(mod(time,10000.),0.);
  vec3 color = randomPaletteColor(pos);
  glFragColor = vec4( color, 1.0 );
}
