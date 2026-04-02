#version 420

// original https://www.shadertoy.com/view/wlBBRm

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Lit Cell" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrBoxDf (vec3 p, vec3 b);
float PrSphDf (vec3 p, float r);
float SmoothMin (float a, float b, float r);
float SmoothMax (float a, float b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Noiseff (float p);
float Hashfv3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

float tCur, dstFar, wRad, bFac;
int idObj;
const float pi = 3.1415927;

#define VAR_ZERO min (frames, 0)

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

vec2 SphGrid (vec3 p)
{
  vec3 q;
  vec2 a, sc, nSeg;
  float dMin, d1, d2, r;
  nSeg = vec2 (21., 23.);
  sc = sin (0.07 * 2. * pi / nSeg + vec2 (0., 0.5 * pi));
  q = p.yxz;
  q.yz = Rot2D (q.yz, 0.1 * tCur);
  r = length (q.yz);
  a = 2. * pi * (floor (nSeg * atan (q.zx, - vec2 (q.y, r)) / (2. * pi)) + 0.5) / nSeg;
  q.yz = Rot2D (q.yz, a.x);
  d1 = dot (vec2 (q.y, abs (q.z)), sc);
  q.yz = Rot2D (vec2 (r, q.x), a.y);
  d2 = dot (vec2 (q.y, abs (q.z)), sc);
  return vec2 (d1, d2);
}

float ObjDf (vec3 p)
{
  vec3 q;
  vec2 d2;
  float dMin, d, wThk;
  dMin = dstFar;
  wThk = 0.15;
  d2 = SphGrid (p);
  d = SmoothMin (d2.x, d2.y, 0.02);
  d = SmoothMax (abs (PrSphDf (p, wRad)) - wThk, d, 0.02);
  DMIN (1);
  d = PrSphDf (p, 0.15 * wRad);
  DMIN (2);
  q = p;
  q.xz = abs (q.xz) - 15.;
  q.y -= -9.;
  d = PrSphDf (q, 1.);
  DMIN (3);
  d = abs (PrBoxDf (p, vec3 (16., 10., 16.) + 0.1)) - 0.1;
  DMIN (4);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 150; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
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

float SphGridShad (vec3 p)
{
  vec2 d2;
  d2 = SphGrid (p);
  return SmoothMin (d2.x, d2.y, 0.01);
}

vec3 ShStagGrid (vec2 p)
{
  vec2 sp, ss;
  if (2. * floor (0.5 * floor (p.y)) != floor (p.y)) p.x += 0.5;
  sp = smoothstep (0.03, 0.07, abs (fract (p + 0.5) - 0.5));
  p = fract (p) - 0.5;
  ss = 0.3 * smoothstep (0.4, 0.5, abs (p.xy)) * sign (p.xy);
  if (abs (p.x) < abs (p.y)) ss.x = 0.;
  else ss.y = 0.;
  return vec3 (ss.x, sp.x * sp.y, ss.y);
}

vec4 ShStagGrid3d (vec3 p, vec3 vn)
{
  vec3 rg;
  if (abs (vn.x) > 0.99) {
    rg = ShStagGrid (p.zy);
    rg.xz *= sign (vn.x);
    if (rg.x == 0.) vn.xy = Rot2D (vn.xy, rg.z);
    else vn.xz = Rot2D (vn.xz, rg.x);
  } else if (abs (vn.y) > 0.99) {
    rg = ShStagGrid (p.zx);
    rg.xz *= sign (vn.y);
    if (rg.x == 0.) vn.yx = Rot2D (vn.yx, rg.z);
    else vn.yz = Rot2D (vn.yz, rg.x);
  } else if (abs (vn.z) > 0.99) {
    rg = ShStagGrid (p.xy);
    rg.xz *= sign (vn.z);
    if (rg.x == 0.) vn.zy = Rot2D (vn.zy, rg.z);
    else vn.zx = Rot2D (vn.zx, rg.x);
  }
  return vec4 (vn, rg.y);
}

vec4 BallHit (vec3 ro, vec3 rd, float rad)
{
  vec3 vn;
  float b, d, w;
  b = dot (rd, ro);
  w = b * b + rad * rad - dot (ro, ro);
  d = dstFar;
  if (w > 0.) {
    d = - b - sqrt (w);
    vn = (ro + d * rd) / rad;
  }
  return vec4 (d, vn);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4, rg4, db4;
  vec3 col, vn, roo, ltDir;
  float dstObj, nDotL, cFac;
  roo = ro;
  wRad = 2.;
  bFac = 0.96 + 0.04 * Noiseff (32. * tCur);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    ltDir = - normalize (ro);
    if (idObj == 1) col4 = vec4 (0.8, 0.7, 0.6, 0.2);
    else if (idObj == 2) col4 = vec4 (vec3 (1., 1., 0.7) * bFac, -1.);
    else if (idObj == 3) col4 = vec4 (vec3 (0.8, 0.8, 0.8) * bFac, 0.1);
    else if (idObj == 4) {
      col4 = vec4 (0.3, 0.3, 0.3, 0.05);
      rg4 = ShStagGrid3d (0.5 * ro, vn);
      vn = rg4.xyz;
      col4.rgb *= 0.9 + 0.1 * rg4.w;
      if (rg4.w == 1. && min (abs (ro.x), abs (ro.z)) > 15.9) col4.rgb *= 0.7;
      vn = VaryNf (8. * ro, vn, 1.);
    }
    if (idObj == 3 || idObj == 4) col4 *= 0.8 + 0.2 * step (0.001, SphGridShad (ltDir));
    if (col4.a >= 0.) {
      nDotL = max (dot (vn, ltDir), 0.);
      col = bFac * (col4.rgb * (0.2 + 0.2 * max (- dot (vn, ltDir), 0.) + 0.8 * nDotL * nDotL) +
         col4.a * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.));
    } else col = col4.rgb * (0.5 - 0.5 * dot (vn, rd));
  }
  cFac = (idObj == 1 || idObj == 2) ? 0.02 : 0.06;
  for (float r = float (VAR_ZERO); r <= 14.; r ++) {
    db4 = BallHit (roo, rd, wRad + 0.2 * (14. - r + Hashfv3 (rd + 2. * tCur)));
    vn = db4.yzw;
    vn = VaryNf (64. * vn, vn, 0.3);
    if (db4.x < dstFar) col = mix (col, bFac * vec3 (1., 1., 0.8),
       cFac * step (0.001, SphGridShad (vn)));
  }
  return clamp (col, 0., 1.);
}

#define AA  0   // optional antialiasing

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, uvv;
  float el, az, zmFac, sr, asp;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  asp = canvas.x / canvas.y;
  az = 0.;
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az -= 0.01 * pi * tCur;
    el -= 0.08 * pi * sin (0.02 * pi * tCur);
  }
  el = clamp (el, -0.4 * pi, 0.4 * pi);
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -9.);
  zmFac = 2.;
  dstFar = 60.;
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    uvv = (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.), sr * (0.667 * a + 0.5) * pi)) / zmFac;
    rd = vuMat * normalize (vec3 ((2. * tan (0.5 * atan (uvv.x / asp))) * asp, uvv.y, 1.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothMax (float a, float b, float r)
{
  return - SmoothMin (- a, - b, r);
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

const float cHashM = 43758.54;

float Hashfv3 (vec3 p)
{
  return fract (sin (dot (p, vec3 (37., 39., 41.))) * cHashM);
}

vec2 Hashv2f (float p)
{
  return fract (sin (p + vec2 (0., 1.)) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

float Noiseff (float p)
{
  vec2 t;
  float ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv2f (ip);
  return mix (t.x, t.y, fp);
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

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
