#version 420

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

vec4 color_;
vec4 col;
vec2 st;
float duration = 3.0;

float easeOutQuart(float t)
{
  return 1.0 - (--t) * t * t * t;
}

void setColor(vec4 color)
{
  color_ = color;
}

float crystal(float a)
{
  return abs(cos(a*12.)*sin(a*3.))*.8+.1;
}

float gear(float a)
{
  return smoothstep(-.5,1., cos(a*10.))*0.2+0.5;
}

float sakura(float a)
{
  return abs(cos(a*2.5))*.5+.3;
}

float plot(float r, float pct){
  return  smoothstep( pct-0.05, pct, r) -
          smoothstep( pct, pct+0.05, r);
}

void main()
{
  st = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);

  float r = length(st);
  float a = atan(st.y,st.x) + time * 0.2; //回転させる

  float t = mod(time, duration);
  float f;
  if(t < 1.0)
  {
    f = crystal(a) * t + gear(a) * (1.0 - t);
  }
  else if(t >= 1.0 && t < 2.0)
  {
    f = sakura(a) * (t - 1.0) + crystal(a) * (2.0 - t);
  }
  else if(t >= 2.0)
  {
    f = gear(a) * (t - 2.0) + sakura(a) * (3.0 - t);
  }

  float pct = plot(r, f);
  setColor(vec4((st.x + 1.0)/2.0, (st.y + 1.0)/2.0, abs(sin(time)), 1.0));
  col = pct * color_;

  glFragColor = col;
}
