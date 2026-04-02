#version 420

// original https://www.shadertoy.com/view/wt3GDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot2d(float a )
{
  float c = cos(a);
  float s = sin(a);
  return mat2(c, -s, s, c);
}

float map(vec3  p)
{
  p.xy = p.xy * rot2d(p.z * 0.2);
  return cos(p.x) + 
  sin(p.y + 1.0) + 
  cos(p.z) + 
  (.05 + 0.42 * 
  sin(time)) * 
  cos(p.y + 
  p.z * 
  2.0) + 
  0.1 * 
  cos(p.y);
}

vec3 grad(vec3 p)
{
  vec2 eps = vec2(0.001, 0.0);
  return normalize(vec3(map(p + eps.xyy) - map(p - eps.xyy),
                   map(p + eps.yxy) - map(p - eps.yxy),
                   map(p + eps.yyx) - map(p - eps.yyx)));
}

vec3 rm(vec3 ro, vec3 rd, out float st)
{
    vec3 p = ro;
  for (float i = 0.; i < 64.; ++i)
  {
    float d = map(p);
    if (abs(d) < 0.001)
    {
      st = i;
      break;
    }
    p += d * rd * 0.8;
  }
return p;
}

vec3 shade(vec3 p, vec3 ro, float st, vec3 n)
{
  vec3 color = exp(-distance(p, ro)* 0.1) * (n * 1.1 + 0.5) * pow((float(st) / 4.0), 0.5);
  color = mix(vec3(0.1, 0.7, 1.0), color, exp(-distance(p, ro)* 0.1));
  return color;
}

void main(void)
{
  vec2 uv=vec2(gl_FragCoord.x/resolution.x,gl_FragCoord.y/resolution.y);
  uv-=.5;
  uv/=vec2(resolution.y/resolution.x,1);
  vec3 ro = vec3(0.0, 0.0, (time*.1) * 8.0);
  vec3 rd = normalize(vec3(uv, 0.7 - length(uv)));
  rd.xy *= rot2d((time*.1));
  float st = 0.0;
  vec3 p = rm(ro, rd, st);
  vec3 n = grad(p);
  vec3 color = shade(p, ro, st, n);
  vec3 rd2 = reflect(rd, n);
  vec3 ro2 = p + 0.1 * rd2;
  vec3 p2 = rm(ro2, rd2, st);
  vec3 n2 =  grad(p2);
  vec3 color2 =  shade(p2, ro, st, n2);
  color = mix(color, color2, 0.65);
  glFragColor = vec4(color, 1.0);
}
