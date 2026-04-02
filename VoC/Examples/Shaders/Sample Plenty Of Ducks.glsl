#version 420

// original https://www.shadertoy.com/view/4tdcW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Plenty O'Dux" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  Lots more ducks than in my earlier "Dodecahedral Duckohedron" (mouseable).
  Starting from Shane's "Polyhedral Gears" -- see his comments for background, including
  work by DjinnKahn and Knighty, as well as Goldberg polyhedra.
*/

#define AA    0

float PrCylDf (vec3 p, float r, float h);
float PrRoundBox2Df (vec2 p, vec2 b, float r);
float PrEllipsDf (vec3 p, vec3 r);
float PrEllCylDf (vec3 p, vec2 r, float h);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
mat3 OrthMat (vec3 n);

mat3 icMat[4], hxMat[3];
vec3 vf[3], qWhl, ltDir;
float dstFar, tCur, dSpoke, dAxl, dTooth, dWhl, dDuk;
int idObj;
const float pi = 3.14159, phi = 1.618034;

vec3 IcosSymP (vec3 p)
{
  vec3 s;
  s = sign (p);
  for (int k = 0; k < 3; k ++) {
    p = icMat[k] * abs (p);
    s *= sign (p);
  }
  return abs (p) * vec3 (s.x * s.y * s.z, 1, 1);
}

float DukDist (vec3 p, float szFac, float a)
{
  vec3 q;
  vec2 r, cs;
  float d, h, s;
  d = dstFar / szFac;
  p /= szFac;
  p.xz = Rot2D (p.xz, a);
  q = p;
  r = vec2 (0.04, 0.06 + 0.01 * clamp (q.z, -0.4, 0.4));
  h = 0.1;
  s = (length (q.xz / r) - 1.) * min (r.x, r.y);
  d = min (d, min (max (s, abs (q.y) - h), length (vec2 (s, q.y)) - h));
  q = p;  q.x = abs (q.x);  q -= vec3 (0.1, 0.06, 0.12);
  cs = vec2 (cos (0.3), sin (0.3));
  q.yz = Rot2Cs (q.yz, cs);
  cs.y = - cs.y;
  q.xy = Rot2Cs (q.xy, cs);
  q.xz = Rot2Cs (q.xz, cs);
  q = q.yxz;
  r = vec2 (0.06, 0.1 + 0.016 * clamp (q.z, -0.4, 0.4));
  h = 0.014;
  s = (length (q.xz / r) - 1.) * min (r.x, r.y);
  d = min (d, SmoothMin (min (max (s, abs (q.y) - h), length (vec2 (s, q.y)) - h), d, 0.01));
  q = p;  q.yz -= vec2 (0.15, -0.08);
  d = min (d, SmoothMin (PrEllipsDf (q, vec3 (0.08, 0.07, 0.1)), d, 0.02));
  q = p;  q.yz -= vec2 (0.14, -0.19);
  r = vec2 (0.03, 0.008);
  h = 0.02;
  d = min (d, max (PrEllCylDf (q, r, h), - PrEllCylDf (q - vec3 (0., 0., h), r - 0.004, 2. * h)));
  return d * szFac;
}

float ToothDist (vec3 p, float nt, float a, float rad, float thk)
{
  vec3 q;
  q = p;
  q.xy = Rot2D (q.xy, (floor (a * nt) + 0.5) * 2. * pi / nt);
  q.x += rad;
  thk *= 0.7 + 2. * q.x;
  q = abs (q);
  return max (0.5 * (max (q.x - 0.05, q.y - 0.02) + length (q.xy * vec2 (0.71, 1.)) - 0.025), q.z - thk);
}

void PentDist (vec3 p, float rad, float thk)
{
  vec3 q;
  float a, tRad;
  tRad = (0.9 + p.z) * rad;
  p.xy = Rot2D (p.xy, - mod (tCur / 1.5, 2. * pi / 5.) - pi);
  a = atan (p.y, abs (p.x)) / (2. * pi);
  q = p;
  q.xy = Rot2D (q.xy, (floor (a * 5.) + 0.5) * 2. * pi / 5.);
  dAxl = max (max (abs (q.x), abs (q.y)) - 0.15 * rad, abs (q.z - 0.5 * thk) - 0.5 * thk);
  q += vec3 (0.5 * rad, 0., -0.5 * thk);
  dSpoke = PrCylDf (q.zyx, 0.1 * rad, 0.4 * rad);
  q += vec3 (0.3 * rad, 0., -0.6 * thk);
  dDuk = DukDist (q.yzx, 0.8 * rad, tCur / 1.5);
  dWhl = PrRoundBox2Df (vec2 (length (p.xy) - 0.8 * tRad, p.z), vec2 (0.2 * tRad, thk), 0.05 * thk);
  qWhl = q;
  dTooth = ToothDist (p, 15., a, tRad, thk);
}

void HexLDIst (vec3 p, float rad, float thk)
{
  vec3 q;
  float a, tRad;
  p.z = - p.z;
  tRad = (0.9 + p.z) * rad;
  p.xy = Rot2D (p.xy, - mod (tCur / 1.8, pi / 3.) - pi / 3.);
  a = atan (p.y, abs (p.x)) / (2. * pi);
  q = p;
  q.xy = Rot2D (q.xy, (floor (a * 6.) + 0.5) * 2. * pi / 6.);
  dAxl = max (max (abs (q.x), abs (q.y)) - 0.15 * rad, abs (q.z - 0.5 * thk) - 0.5 * thk);
  q += vec3 (0.5 * rad, 0., -0.5 * thk);
  dSpoke = PrCylDf (q.zyx, 0.1 * rad, 0.4 * rad);
  q += vec3 (0.3 * rad, 0., -0.6 * thk);
  dDuk = DukDist (q.yzx, 0.8 * rad, - 2. * tCur / 1.8);
  dWhl = PrRoundBox2Df (vec2 (length (p.xy) - 0.8 * tRad, p.z), vec2 (0.2 * tRad, thk), 0.05 * thk);
  qWhl = q;
  dTooth = ToothDist (p, 18., a, tRad, thk);
}

void HexSDist (vec3 p, float rad, float thk)
{
  vec3 q;
  float a, tRad, t;
  tRad = (0.9 + p.z) * rad;
  t = sign (p.x) * tCur / 1.2;
  p.x = abs (p.x);
  q = p;
  q.xy = Rot2D (q.xy, - mod (t, pi / 3.) - 2. * pi / 3.);
  q.xy = Rot2D (q.xy, (floor (atan (q.y, abs (q.x)) / (2. * pi) * 6.) + 0.5) * pi / 3.);
  dAxl = max (max (abs (q.x), abs (q.y)) - 0.15 * rad, abs (q.z - 0.5 * thk) - 0.5 * thk);
  q += vec3 (0.5 * rad, 0., -0.5 * thk);
  dSpoke = PrCylDf (q.zyx, 0.1 * rad, 0.4 * rad);
  q += vec3 (0.3 * rad, 0., -0.6 * thk);
  dDuk = DukDist (q.yzx, 0.8 * rad, 2. * t);
  dWhl = PrRoundBox2Df (vec2 (length (p.xy) - 0.8 * tRad, p.z), vec2 (0.2 * tRad, thk), 0.05 * thk);
  qWhl = q;
  q = p;
  q.xy = Rot2D (q.xy, - mod (t + pi / 12., pi / 6.) - 5. * pi / 6.);
  dTooth = ToothDist (q, 12., atan (q.y, abs (q.x)) / (2. * pi), tRad, thk);
}

float ObjDf (vec3 p)
{
  vec3 hxv, qqw1, qqw2;
  float dMin, d, thk;
  dMin = dstFar;
  d = length (p) - 1.2;
  if (d < 0.02) {
    thk = 0.1;
    hxv = IcosSymP (p);
    for (int k = 0; k < 4; k ++) {
      if (k == 0) PentDist (icMat[3] * hxv - vec3 (0., 0., 1.), 0.185, thk);
      else if (k == 1) HexLDIst (hxMat[0] * (hxv - vf[2]), 0.25, thk);
      else HexSDist (hxMat[k - 1] * (hxv - vf[k - 2]), 0.16, thk);
      if (dSpoke < dMin) { dMin = dSpoke;  idObj = 1; }
      if (dWhl < dMin) {
        dMin = dWhl;
        if (k < 2) { idObj = 2;  qqw1 = qWhl; }
        else { idObj = 3;  qqw2 = qWhl; }
      }
      if (dTooth < dMin) { dMin = dTooth;  idObj = 4; }
      if (dAxl < dMin) { dMin = dAxl;  idObj = 5; }
      if (dDuk < dMin) { dMin = dDuk;  idObj = 6; }
    }
    if (idObj == 2) qWhl = qqw1;
    if (idObj == 3) qWhl = qqw2;
    dMin *= 0.9;
  } else dMin = d;
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = ObjDf (ro + rd * dHit);
    if (d < 0.0002 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0001, -0.0001);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjAO (vec3 ro, vec3 rd)
{
  float ao, d;
  ao = 0.;
  for (float j = 1.; j <= 4.; j ++) {
    d = 0.02 * j;
    ao += max (0., d - 5. * ObjDf (ro + d * rd));
  }
  return 0.5 + 0.5 * clamp (1. - ao, 0., 1.);
}

void InitBasis ()
{
  vec3 v0, v1, v2, u;
  vec2 e = vec2 (1., -1.);
  float c;
  v0 = vec3 (0, 1., phi - 1.);
  v1 = v0.zxy;
  v2 = v1 * e.yxx;
  vf[0] = (2. * v0 + v2) / 3.;
  vf[1] = (2. * v0 + v1) / 3.;
  vf[2] = (v0 + vec3 (0., 0., 2.)) / 3.;
  hxMat[0] = OrthMat (cross (vf[2] - v0, vf[2] - v1));
  hxMat[1] = OrthMat (vf[0]);
  hxMat[2] = OrthMat (vf[1]);
  c = 1. / sqrt (phi + 2.);
  vf[0] *= 1.1547 * c * phi;
  vf[1] *= 1.1547 * c * phi;
  vf[2] *= 1.2425 * c * phi;
  u = 0.5 * vec3 (1., phi - 1., phi);
  icMat[0] = mat3 (u.xzy * e.xyx, u.zyx * e.xxy, u.yxz);
  icMat[1] = mat3 (u.zyx * e.xxy, u.yxz, u.xzy * e.xyx);
  icMat[2] = mat3 (u.yxz * e.yyx, u.xzy * e.xyy, u.zyx);
  icMat[3] = 0.5 * mat3 (sqrt (3. - phi), - phi, 0., - c * phi, 1. - phi, 2. * c * phi,
     c * sqrt (2. + 3. * phi), 1., 2. * c);
}
vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj;
  InitBasis ();
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == 1) col = vec3 (0.6, 0.6, 0.65);
    else if (idObj == 2) col = vec3 (0.7, 0.7, 0.3);
    else if (idObj == 3) col = vec3 (0.7, 0.7, 0.3);
    else if (idObj == 4) col = vec3 (0.7, 0.7, 0.3);
    else if (idObj == 5) col = vec3 (0., 0.4, 0.1);
    else if (idObj == 6) col = vec3 (1., 0.2, 0.1);
    if (idObj == 2 || idObj == 3) col *= 0.6 + 0.4 * step (0.003, abs (qWhl.y));
    col = col * (0.2 + 0.8 * max (dot (ltDir, vn), 0.)) +
       0.3 * pow (max (dot (reflect (ltDir, vn), rd), 0.), 32.);
    col *= ObjAO (ro, vn) * (1. - smoothstep (3., 5., dstObj));
  } else col = vec3 (0.1);
  return col;
}

void main(void)
{
  mat3 vuMat;
  vec2 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = mouse.xy*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.;
  zmFac = 2.2;
  //if (mPtr.z > 0.) {
  //  az += 2. * pi * mPtr.x;
  //  el += pi * mPtr.y;
  //  zmFac += 3. * SmoothBump (0.25 * pi, 0.75 * pi, 0.2 * pi, mod (az, pi));
  //} else {
    az += 0.05 * pi * tCur;
    el -= 0.2 * pi * sin (0.06 * pi * tCur);
  //}
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -3.);
  rd = vuMat * normalize (vec3 (uv, zmFac));
  ltDir = vuMat * normalize (vec3 (1., 1., -1));
  dstFar = 10.;
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.),
       0.5 * pi * (a + 0.5)), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (clamp (col, 0., 1.), 1.);
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrRoundBox2Df (vec2 p, vec2 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrEllipsDf (vec3 p, vec3 r)
{
  return (length (p / r) - 1.) * min (r.x, min (r.y, r.z));
}

float PrEllCylDf (vec3 p, vec2 r, float h)
{
  return max ((length (p.xy / r) - 1.) * min (r.x, r.y), abs (p.z) - h);
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
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

mat3 OrthMat (vec3 n)
{
  mat3 mm;
  float a;
  n = normalize (n);
  if (n.z > -1.) {
    a = 1. / (1. + n.z);
    mm = mat3 (1. - n.x * n.x * a, - n.x * n.y * a, n.x,
       - n.x * n.y * a, 1. - n.y * n.y * a, n.y, - n.x, - n.y, n.z);
  } else mm = mat3 (1., 0., 0., 0., 1., 0., 0., 0., -1.);
  return mm;
}
