#version 420

// original https://www.shadertoy.com/view/ws3cD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define sat(a) clamp(a,0.,1.)

mat2 r2d(float a){float cosa = cos(a);float sina = sin(a);return mat2(cosa,sina,-sina,cosa);}

float cir(vec2 p, float r)
{
  return length(p)-r;
}

vec3 rdr(vec2 uv)
{
  uv*=r2d(.1*time+length(uv)*.5);
  vec3 col;

  float l = abs(sin(uv.y*30.+20.*sin(.5*time+uv.x*5.*length(uv*.2))))-2.3*(.1+.2*sin((uv.x+uv.y)*5.+time));

  col = mix(col,vec3(1.),1.-sat(l));
  return col;
}

vec3 rdr2(vec2 uv)
{
  float dist = (sin(-time*5.+(uv.x+uv.y)*5.)*.5+1.)*0.08;

  vec2 dir = normalize(vec2(1.));
  vec3 col;
  col.r = rdr(uv+dir*dist).r;
  col.g = rdr(uv).g;
  col.b = rdr(uv-dir*dist).b;
  return col;
}

void main(void) {
  vec2 uv =( gl_FragCoord.xy-0.5*resolution.xy) / resolution.xx;
  uv*=3.5;

  vec3 col = rdr2(uv);
  glFragColor = vec4(col, 1.0);
}
