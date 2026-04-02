#version 420

// original https://www.shadertoy.com/view/wstGR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI  3.141592654
#define TAU (2.0*PI)

vec2 toPolar(vec2 p)
{
  return vec2(length(p), atan(p.y, p.x));
}

vec2 toRect(vec2 p)
{
  return p.x*vec2(cos(p.y), sin(p.y));
}

vec2 mod2(inout vec2 p, vec2 size) 
{
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

void rot(inout vec2 p, float a)
{
  float c = cos(a);
  float s = sin(a);
  
  p = vec2(c*p.x + s*p.y, -s*p.x + c*p.y);
}

float circle(vec2 p, float r)
{
  return length(p) - r;
}

float box(vec2 p, vec2 s)
{
  p = abs(p);
  return max(p.x - s.x, p.y - s.y);
}

float df(vec2 p)
{
  vec2 pp = toPolar(p);
  float a = TAU/64.0;
  float np = pp.y/a;
  pp.y = mod(pp.y, a);
  float m2 = mod(np, 2.0);
  if (m2 > 1.0)
  {
    pp.y = a - pp.y;
  }
  pp.y += time/40.0;
  p = toRect(pp);
  p = abs(p);
  p -= vec2(0.5);
  
  float d = 10000.0;
  
  for (int i = 0; i < 4; ++i)
  {
    mod2(p, vec2(1.0));
      
    float sb = box(p, vec2(0.35));
    float cb = circle(p + vec2(0.2), 0.25);
    
    float dd = max(sb, -cb);
    d = min(dd, d);
    
    p *= 1.5 + 1.0*(0.5 + 0.5*sin(0.5*time));
    rot(p, 1.0);
  }

  
  return d;
}

vec3 postProcess(in vec3 col, in vec2 uv) 
{
  float r = length(uv);
  float a = atan(uv.y, uv.x);
  col = clamp(col, 0.0, 1.0);   
  col=pow(col,mix(vec3(0.5, 0.75, 1.5), vec3(0.45), r)); 
  col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
  col=mix(col, vec3(dot(col, vec3(0.33))), -0.4);  // satuation
  col*=sqrt(1.0 - sin(-time + (50.0 - 25.0*sqrt(r))*r))*(1.0 - sin(0.5*r));
  col = clamp(col, 0.0, 1.0);
  float ff = pow(1.0-0.75*sin(20.0*(0.5*a + r + -0.1*time)), 0.75);
  col = pow(col, vec3(ff*0.9, 0.8*ff, 0.7*ff));
  col *= 0.5*sqrt(max(4.0 - r*r, 0.0));
  return clamp(col, 0.0, 1.0);
}

vec2 toSmith(vec2 p) 
{
  // z = (p + 1)/(-p + 1)
  // (x,y) = ((1+x)*(1-x)-y*y,2y)/((1-x)*(1-x) + y*y)
  float d = (1.0 - p.x)*(1.0 - p.x) + p.y*p.y;
  float x = (1.0 + p.x)*(1.0 - p.x) - p.y*p.y;
  float y = 2.0*p.y;
  return vec2(x,y)/d;
}

vec2 fromSmith(vec2 p) 
{
  // z = (p - 1)/(p + 1)
  // (x,y) = ((x+1)*(x-1)+y*y,2y)/((x+1)*(x+1) + y*y)
  float d = (p.x + 1.0)*(p.x + 1.0) + p.y*p.y;
  float x = (p.x + 1.0)*(p.x - 1.0) + p.y*p.y;
  float y = 2.0*p.y;
  return vec2(x,y)/d;
}

vec2 distort(vec2 uv)
{
  float time = 0.1*time;
  vec2 suv = toSmith(uv);
  suv += 1.0*vec2(cos(time), sin(sqrt(2.0)*time));
//  suv *= vec2(1.5 + 1.0*sin(sqrt(2.0)*time), 1.5 + 1.0*sin(time));
  uv = fromSmith(suv);
  mod2(uv, vec2(2.0+sin(time)));
  return uv;
}

void main(void)
{
  float time = 0.1*time;
  vec2 uv = gl_FragCoord.xy/resolution.xy - vec2(0.5);
  uv.x *= resolution.x/resolution.y;
  uv *=8.0;
  rot(uv, time);
  //uv *= 0.2 + 1.1 - 1.1*cos(0.1*time);

  vec2 nuv = distort(uv);
  vec2 nuv2 = distort(uv + vec2(0.00005));

  float nl = length(nuv - nuv2);
  float nf = 1.0 - smoothstep(0.0, 0.001, nl);

  uv = nuv;
  
  float d = df(uv);

  vec3 col = vec3(0.0);
 
  const float r = 0.065;

  float nd = d / r;
  float md = mod(d, r);
  
  if (abs(md) < 0.0125)
  {
    col = (d > 0.0 ? vec3(0.25, 0.65, 0.25) : vec3(0.65, 0.25, 0.65) )/abs(nd);
  }

  if (abs(d) < 0.0125)
  {
    col = vec3(1.0);
  }

  col += 1.0 - pow(nf, 5.0);
  
  col = postProcess(col, uv);;
  
  col += 1.0 - pow(nf, 1.0);

  glFragColor = vec4(col, 1.0);
    
}
