#version 420

// original https://www.shadertoy.com/view/7dcSRX

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Swirling Balls" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Balls arranged in multiple rotating shells with 60-fold symmetry
// (see "Pentakis Dodecahedron" and "Pentakis Reflections");
// only one ball drawn per shell, the (maximal) 60x factor is free.

float PrSphDf (vec3 p, float r);
float Maxv3 (vec3 p);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
vec3 HsvToRgb (vec3 c);
float Fbm2 (vec2 p);

vec3 ltDir;
float tCur, dstFar;
int idObj;
const float pi = 3.1415927;

#if 0
#define VAR_ZERO min (frames, 0)
#else
#define VAR_ZERO 0
#endif

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

vec3 DodecSym (vec3 p)
{
  vec2 csD;
  csD = sin (0.5 * atan (2.) + vec2 (0.5 * pi, 0.));
  p.xz = Rot2Cs (vec2 (p.x, abs (p.z)), csD);
  p.xy = Rot2D (p.xy, - pi / 10.);
  p.x = - abs (p.x);
  for (int k = 0; k <= 3; k ++) {
    p.zy = Rot2Cs (p.zy, vec2 (csD.x, - csD.y));
    p.y = - abs (p.y);
    p.zy = Rot2Cs (p.zy, csD);
    if (k < 3) p.xy = Rot2Cs (p.xy, sin (-2. * pi / 5. + vec2 (0.5 * pi, 0.)));
  }
  p.xy = sin (mod (atan (p.x, p.y) + pi / 5., 2. * pi / 5.) - pi / 5. +
     vec2 (0., 0.5 * pi)) * length (p.xy);
  p.xz = - vec2 (abs (p.x), p.z);
  return p;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, r;
  dMin = dstFar;
  p.y += 1.2 * sin (0.1 * pi * tCur);
  p.xz += Rot2D (vec2 (1., 0.), 0.1 * pi * tCur); 
  p.xz = Rot2D (p.xz, 0.05 * pi * tCur);
  r = 3.3;
  d = PrSphDf (p, r + 0.2);
  if (d < 0.1) {
    for (int k = VAR_ZERO; k < 16; k ++) {
      r *= 0.92;
      p.xz = Rot2D (p.xz, 0.43 * pi);
      p.xy = Rot2D (p.xy, 0.05 * pi * tCur);
      q = DodecSym (p);
      q.yz -= vec2 (0.365, -1.) * r;
      d = PrSphDf (q, 0.05 * sqrt (r));
      DMIN (1 + k);
    }
  } else dMin = d;
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 StarPat (vec3 rd, float scl) 
{
  vec3 tm, qn, u;
  vec2 q;
  float f;
  tm = -1. / max (abs (rd), 0.0001);
  qn = - sign (rd) * step (tm.zxy, tm) * step (tm.yzx, tm);
  u = Maxv3 (tm) * rd;
  q = atan (vec2 (dot (u.zxy, qn), dot (u.yzx, qn)), vec2 (1.)) / pi;
  f = 0.57 * (Fbm2 (11. * dot (0.5 * (qn + 1.), vec3 (1., 2., 4.)) + 131.13 * scl * q) +
      Fbm2 (13. * dot (0.5 * (qn + 1.), vec3 (1., 2., 4.)) + 171.13 * scl * q.yx));
  return 8. * vec3 (1., 1., 0.8) * pow (f, 16.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col = HsvToRgb (vec3 (mod (float (idObj) / 16. + 0.03 * tCur, 1.), 0.5, 1.));
    col = col * (0.2 + 0.8 * max (dot (vn, ltDir), 0.)) +
       0.2 * pow (max (dot (ltDir, reflect (rd, vn)), 0.), 32.);
    col *= exp (-0.3 * (dstObj - 17.) / 6.);
  } else col = StarPat (rd, 12.);
  return clamp (col, 0., 1.);
}

#define AA  0   // optional antialiasing

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az -= 0.005 * pi * tCur;
    el -= 0.1 * pi * sin (0.003 * pi * tCur);
  }
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -20.);
  zmFac = 4.;
  dstFar = 50.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
}

mat3 StdVuMat (float el, float az)
{
  vec2 ori, ca, sa;
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  return mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
         mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1., 0., 1.), c.y);
}

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec2 t, ip, fp;
  ip = floor (p);  
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = mix (Hashv2v2 (ip), Hashv2v2 (ip + vec2 (0., 1.)), fp.y);
  return mix (t.x, t.y, fp.x);
}

float Fbm2 (vec2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}
