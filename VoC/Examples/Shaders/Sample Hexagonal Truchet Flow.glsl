#version 420

// original https://www.shadertoy.com/view/ltVBDw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Hexagonal Truchet Flow" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
float HexEdgeDist (vec2 p);
vec2 Rot2D (vec2 q, float a);
float Hashfv2 (vec2 p);

float tCur;
const float pi = 3.14159, sqrt3 = 1.73205;

vec3 ShowScene (vec2 p)
{
  vec3 col, w;
  vec2 cId, pc;
  vec2 q;
  float dir, a, d;
  cId = PixToHex (p);
  pc = HexToPix (cId);
  dir = 2. * step (Hashfv2 (cId), 0.5) - 1.;
  w.xy = pc + vec2 (0., - dir);
  w.z = dot (w.xy - p, w.xy - p);
  q = pc + vec2 (sqrt3/2., 0.5 * dir);
  d = dot (q - p, q - p);
  if (d < w.z) w = vec3 (q, d);
  q = pc + vec2 (- sqrt3/2., 0.5 * dir);
  d = dot (q - p, q - p);
  if (d < w.z) w = vec3 (q, d);
  w.z = abs (sqrt (w.z) - 0.5);
  d = HexEdgeDist (p - pc);
  col = vec3 (0.5, 0.5, 1.) * mix (1., 0.7 + 0.3 * smoothstep (0.2, 0.8, d),
     smoothstep (0.02, 0.03, d));
  if (w.z < 0.25) {
    col = vec3 (1., 1., 0.) * (1. - 0.5 * smoothstep (0.1, 0.25, w.z));
    w.xy = Rot2D (w.xy - p, 0.5 * dir * tCur);
    a = mod (3. * atan (dir * w.y, - w.x) / pi, 1.) - 0.5;
    for (float s = 0.01; s >= 0.; s -= 0.01) {
      d = 1.;
      if (abs (a) - 0.15 < s) d = min (d, smoothstep (0., 0.005,
         w.z - 0.045 * (1. - a / 0.15) - 0.5 * s));
      if (abs (a + 0.3) - 0.15 < s) d = min (d, smoothstep (0., 0.005, w.z - 0.02 - s));
      if (abs (mod (2. * a + 0.5, 1.) - 0.5) - 0.4 < s)
         d = min (d, smoothstep (0., 0.005, abs (w.z - 0.135) - 0.01 - s));
      col = mix (vec3 (1. - 70. * s, 0., 0.), col, d);
    }
  }
  return col;
}

#define AA  1

void main(void)
{
  vec3 col;
  vec2 canvas, uv;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  uv += 6. * vec2 (cos (0.01 * tCur), sin (0.01 * tCur));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) col += (1. / naa) * ShowScene (8. * (uv + step (1.5, naa) *
     Rot2D (vec2 (0.71 / canvas.y, 0.), 0.5 * pi * (a + 0.5))));
  glFragColor = vec4 (clamp (col, 0., 1.), 1.);
}

vec2 PixToHex (vec2 p)
{
  vec3 c, r, dr;
  c.xz = vec2 ((1./sqrt3) * p.x - (1./3.) * p.y, (2./3.) * p.y);
  c.y = - c.x - c.z;
  r = floor (c + 0.5);
  dr = abs (r - c);
  r -= step (dr.yzx, dr) * step (dr.zxy, dr) * dot (r, vec3 (1.));
  return r.xz;
}

vec2 HexToPix (vec2 h)
{
  return vec2 (sqrt3 * (h.x + 0.5 * h.y), 1.5 * h.y);
}

float HexEdgeDist (vec2 p)
{
  p = abs (p);
  return (sqrt3/2.) - p.x + 0.5 * min (p.x - sqrt3 * p.y, 0.);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
}
