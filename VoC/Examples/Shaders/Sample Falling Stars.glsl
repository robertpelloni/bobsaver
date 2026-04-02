#version 420

// original https://www.shadertoy.com/view/lsVyz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Falling Stars" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float SmoothMin (float a, float b, float r);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float Hashfv2 (vec2 p);
vec3 Hashv3v3 (vec3 p);

vec3 ltDir;
vec2 csI, csI2, csD, csD2;
float tCur, dstFar;
const vec3 bGrid = vec3 (2.);
const float pi = 3.14159;

vec3 IcosSym (vec3 p)
{
  float a, w;
  w = 2. * pi / 3.;
  p.yz = Rot2Cs (vec2 (p.y, abs (p.z)), csI);
  p.x = - abs (p.x);
  for (int k = 0; k < 3; k ++) {
    if (dot (p.yz, csI) > 0.) p.zy = Rot2Cs (p.zy, csI2) * vec2 (1., -1.);
    p.xy = Rot2D (p.xy, - w);
  }
  if (dot (p.yz, csI) > 0.) p.zy = Rot2Cs (p.zy, csI2) * vec2 (1., -1.);
  a = mod (atan (p.x, p.y) + 0.5 * w, w) - 0.5 * w;
  p.yx = vec2 (cos (a), sin (a)) * length (p.xy);
  p.xz = - vec2 (abs (p.x), p.z);
  return p;
}

vec3 DodecSym (vec3 p)
{
  float a, w;
  w = 2. * pi / 5.;
  p.xz = Rot2Cs (vec2 (p.x, abs (p.z)), vec2 (csD.x, - csD.y));
  p.xy = Rot2D (p.xy, - 0.25 * w);
  p.x = - abs (p.x);
  for (int k = 0; k < 3; k ++) {
    if (dot (p.yz, csD) > 0.) p.zy = Rot2Cs (p.zy, csD2) * vec2 (1., -1.);
    p.xy = Rot2D (p.xy, - w);
  }
  if (dot (p.yz, csD) > 0.) p.zy = Rot2Cs (p.zy, csD2) * vec2 (1., -1.);
  a = mod (atan (p.x, p.y) + 0.5 * w, w) - 0.5 * w;
  p.yx = vec2 (cos (a), sin (a)) * length (p.xy);
  p.xz = - vec2 (abs (p.x), p.z);
  return p;
}

float ObjDf (vec3 p, vec3 cId)
{
  vec3 q, h;
  float d;
  d = dstFar;
  h = Hashv3v3 (cId);
  if (h.x * step (2., length (cId.xz)) > 0.6) {
    p -= bGrid * (cId + 0.5);
    p -= (0.2 + 0.1 * bGrid.x * h.x) * vec3 (cos (h.z * tCur + h.x), 0., sin (h.z * tCur + h.x));
    p.xz = Rot2D (p.xz, (h.y - 0.5) * tCur);
    p.xy = Rot2D (p.xy, (h.z - 0.5) * tCur);
    q = p;
    d = PrSphDf (q, 0.2);
    q = IcosSym (p);
    q.z += 0.48;
    d = SmoothMin (d, PrCylDf (q, 0.05 * (0.55 + 1.5 * q.z), 0.3), 0.01);
    q = DodecSym (p);
    q.z += 0.48;
    d = 0.9 * SmoothMin (d, PrCylDf (q, 0.05 * (0.55 + 1.5 * q.z), 0.3), 0.01);
  }
  return d;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p, cId, s;
  float dHit, d, eps;
  eps = 0.0005;
  if (rd.x == 0.) rd.x = 0.001;
  if (rd.y == 0.) rd.y = 0.001;
  if (rd.z == 0.) rd.z = 0.001;
  dHit = eps;
  for (int j = 0; j < 120; j ++) {
    p = ro + rd * dHit;
    cId.xz = floor (p.xz / bGrid.xz);
    p.y += 0.2 * tCur * (1. + Hashfv2 (cId.xz));
    cId.y = floor (p.y / bGrid.y);
    d = ObjDf (p, cId);
    s = (bGrid * (cId + step (0., rd)) - p) / rd;
    d = min (d, abs (min (min (s.x, s.y), s.z)) + eps);
    dHit += d;
    if (d < eps || dHit > dstFar) break;
  }
  if (d >= eps) dHit = dstFar;
  return dHit;
}

float ObjDfN (vec3 p)
{
  vec3 cId;
  cId.xz = floor (p.xz / bGrid.xz);
  p.y += 0.2 * tCur * (1. + Hashfv2 (cId.xz));
  cId.y = floor (p.y / bGrid.y);
  return ObjDf (p, cId);
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.001, -0.001);
  v = vec4 (ObjDfN (p + e.xxx), ObjDfN (p + e.xyy), ObjDfN (p + e.yxy), ObjDfN (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec3 BgCol (vec3 rd)
{
  float t, gd, b;
  t = tCur * 3.;
  b = dot (vec2 (atan (rd.x, rd.z), 0.5 * pi - acos (rd.y)), vec2 (2., sin (rd.x)));
  gd = clamp (sin (5. * b + t), 0., 1.) * clamp (sin (3.5 * b - t), 0., 1.) +
     clamp (sin (21. * b - t), 0., 1.) * clamp (sin (17. * b + t), 0., 1.);
  return mix (vec3 (0.25, 0.6, 1.), vec3 (0., 0.4, 0.3), 0.5 * (1. - rd.y)) *
     (0.24 + 0.44 * (rd.y + 1.) * (rd.y + 1.)) * (1. + 0.25 * gd);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, bgCol, vn;
  float dstObj, dihedIcos, dihedDodec;
  dihedIcos = 0.5 * acos (sqrt (5.) / 3.);
  csI = vec2 (cos (dihedIcos), - sin (dihedIcos));
  csI2 = vec2 (cos (2. * dihedIcos), - sin (2. * dihedIcos));
  dihedDodec = 0.5 * atan (2.);
  csD = vec2 (cos (dihedDodec), - sin (dihedDodec));
  csD2 = vec2 (cos (2. * dihedDodec), - sin (2. * dihedDodec));
  bgCol = BgCol (rd);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col = mix (vec3 (0.15, 0.35, 0.7), BgCol (reflect (rd, vn)), 0.8);
    col = col * (0.4 + 0.1 * max (vn.y, 0.) + 0.5 * max (dot (vn, ltDir), 0.)) +
       0.1 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    col *= 0.3 + 0.7 * min (rd.y + 1., 1.5);
    col = mix (col, bgCol, smoothstep (0.5 * dstFar, dstFar, dstObj));
  } else col = bgCol;
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd;
  vec2 canvas, uv, ori, ca, sa;
  float el, az;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  //mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.02 * pi * tCur;
  el = 0.2 * pi * sin (0.01 * pi * tCur);
  if (mPtr.z > 0.) {
    az = 2. * pi * mPtr.x;
    el = 0.6 * pi * mPtr.y;
  }
  tCur += 100.;
  el = clamp (el, -0.3 * pi, 0.3 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vec3 (0.5);
  rd = vuMat * normalize (vec3 (uv, 3.));
  ltDir = normalize (vec3 (0.2, 1., -0.2));
  dstFar = 50.;
  glFragColor = vec4 (pow (ShowScene (ro, rd), vec3 (0.8)), 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
}

vec3 Hashv3v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec3 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3))) * cHashM);
}
