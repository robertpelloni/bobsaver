#version 420

// original https://www.shadertoy.com/view/DtKGDm

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Falling Polyhedra" by dr2 - 2023
// License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0

#define AA  0  // (= 0/1) optional antialiasing

#if 0
#define VAR_ZERO min (frames, 0)
#else
#define VAR_ZERO 0
#endif

float Minv3 (vec3 p);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
mat3 StdVuMat (float el, float az);
vec3 HsvToRgb (vec3 c);
float Hashfv2 (vec2 p);
float Hashfv3 (vec3 p);
vec3 Hashv3v3 (vec3 p);

vec3 bGrid, cId, obDisp, obRot, ltDir[4], ltCol[4];
float dstFar, tCur, vSpd;
bool cOcc;
const float pi = 3.1415927;

vec3 DodecSym (vec3 p)
{
  vec2 csD;
  csD = sin (0.5 * atan (2.) + vec2 (0.5 * pi, 0.));
  p.xz = Rot2Cs (vec2 (p.x, abs (p.z)), csD);
  p.xy = Rot2D (p.xy, -0.1 * pi);
  p.x = - abs (p.x);
  for (int k = 0; k < 3; k ++) {
    p.zy = Rot2Cs (p.zy, vec2 (csD.x, - csD.y));
    p.zy = Rot2Cs (vec2 (p.z, - abs (p.y)), csD);
    p.xy = Rot2Cs (p.xy, sin (-2. * pi / 5. + vec2 (0.5 * pi, 0.)));
  }
  p.zy = Rot2Cs (p.zy, vec2 (csD.x, - csD.y));
  p.zy = Rot2Cs (vec2 (p.z, - abs (p.y)), csD);
  p.xy = sin ((2. * pi / 5.) * (fract ((atan (p.x, p.y) + pi / 5.) / (2. * pi / 5.)) - 0.5) +
     vec2 (0., 0.5 * pi)) * length (p.xy);
  p.xz = - vec2 (abs (p.x), p.z);
  return p;
}

float ObjDf (vec3 p)
{  // (from "Pentakis Dodecahedron")
  float d, a;
  d = dstFar;
  if (cOcc) {
    p -= obDisp;
    p.yz = Rot2Cs (p.yz, sin (obRot.x + vec2 (0.5 * pi, 0.)));
    p.xz = Rot2Cs (p.xz, sin (obRot.y + vec2 (0.5 * pi, 0.)));
    p.xy = Rot2Cs (p.xy, sin (obRot.z + vec2 (0.5 * pi, 0.)));
    a = 0.5 * (acos (-1. / sqrt (5.)) - acos (- (80. + 9. * sqrt (5.)) / 109.));
    d = abs (dot (DodecSym (p).yz, sin (a + vec2 (0., 0.5 * pi)))) - 0.12;
  }
  return d;
}

void ObjState ()
{
  vec3 vRan;
  vRan = Hashv3v3 (cId + 11.1);
  cOcc = (vRan.x * step (4., length (cId.xz)) > 0.2);
  if (cOcc) {
    obDisp = bGrid * (cId + 0.5 + 0.3 * cos ((0.5 + 0.5 * vRan) * tCur + vRan.zxy));
    obRot = (vRan - 0.5) * tCur;
  }
}

vec3 ObjCell (vec3 p)
{
  cId.xz = floor (p.xz / bGrid.xz);
  p.y += vSpd * tCur * (1. + Hashfv2 (cId.xz));
  cId.y = floor (p.y / bGrid.y);
  return p;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p, cIdP, rdi;
  float dHit, d, eps;
  eps = 0.0005;
  if (rd.x == 0.) rd.x = 0.001;
  if (rd.y == 0.) rd.y = 0.001;
  if (rd.z == 0.) rd.z = 0.001;
  rdi = 1. / rd;
  cIdP = vec3 (-999.);
  dHit = eps;
  for (int j = VAR_ZERO; j < 120; j ++) {
    p = ObjCell (ro + dHit * rd);
    if (cId != cIdP) {
      ObjState ();
      cIdP = cId;
    }
    d = ObjDf (p);
    d = min (d, abs (Minv3 ((bGrid * (cId + step (0., rd)) - p) * rdi)) + eps);
    dHit += d;
    if (d < eps || dHit > dstFar) break;
  }
  if (d >= eps) dHit = dstFar;
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

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, c, vn, sumD, sumS;
  float dstObj, nDotL;
  col = vec3 (0.1);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ObjCell (ro));
    c = HsvToRgb (vec3 (Hashfv3 (cId), 0.7, 1.));
    sumD = vec3 (0.);
    sumS = vec3 (0.);
    for (int k = VAR_ZERO; k < 4; k ++) {
      nDotL = max (dot (vn, ltDir[k]), 0.);
      nDotL *= nDotL;
      sumD += ltCol[k] * c * nDotL * nDotL;
      sumS += vec3 (0.7) * pow (max (0., dot (ltDir[k], reflect (rd, vn))), 128.);
    }
    col = sumD + sumS;
    col = mix (col, vec3 (0.1), 1. - exp (min (0., 3. - 5. * dstObj / dstFar)));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, e;
  float el, az, sr, zmFac;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tCur += 10.;
  az = 0.;
  el = 0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.5 * pi * mPtr.y;
  } else {
    az += 0.01 * tCur;
  }
  el = clamp (el, -0.4 * pi, 0.4 * pi);
  vuMat = StdVuMat (el, az);
  bGrid = vec3 (1.);
  vSpd = 0.2;
  ro = vec3 (0.5 * bGrid.x);
  zmFac = 6.;
  dstFar = 50.;
  e = vec2 (1., -1.);
  for (int k = VAR_ZERO; k < 4; k ++) {
    ltDir[k] = normalize ((k < 2) ? ((k == 0) ? e.xxx : e.xyy) : ((k == 2) ? e.yxy : e.yyx));
    ltDir[k].xz = Rot2D (ltDir[k].xz, 0.17 * pi * tCur);
    ltDir[k].xy = Rot2D (ltDir[k].xy, 0.13 * pi * tCur);
  }
  ltCol[0] = vec3 (1., 1., 0.3);
  ltCol[1] = ltCol[0].gbr;
  ltCol[2] = ltCol[0].brg;
  ltCol[3] = 0.8 * ltCol[0].rrg;
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

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
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

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
}

float Hashfv3 (vec3 p)
{
  return fract (sin (dot (p, vec3 (37., 39., 41.))) * cHashM);
}

vec3 Hashv3v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  return fract (sin (dot (p, cHashVA3) + vec3 (0., cHashVA3.xy)) * cHashM);
}