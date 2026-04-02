#version 420

// original https://www.shadertoy.com/view/ld2czz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Drone Flight" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Flight through terrain adapted from Shane's "Canyon Pass"

float PrSphDf (vec3 p, float s);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
float PrRCylDf (vec3 p, float r, float rt, float h);
float PrRoundBoxDf (vec3 p, vec3 b, float r);
vec2 Rot2D (vec2 q, float a);
vec3 VaryNf (vec3 p, vec3 n, float f);

const float pi = 3.14159;

vec3 dronePos, ltPos;
vec2 aTilt;
float dstFar, tCur;
int idObj;
const int idDrBod = 1, idDrLamp = 2, idDrCam = 3;

float ObjDf (vec3 p)
{
  vec3 q, qq;
  float dMin, d;
  const float dSzFac = 6.;
  dMin = dstFar;
  dMin *= dSzFac;
  qq = dSzFac * (p - dronePos);
  qq.yz = Rot2D (qq.yz, - aTilt.y);
  qq.yx = Rot2D (qq.yx, - aTilt.x);
  q = qq;
  q.y -= 0.05;
  d = PrRCylDf (q.xzy, 0.2, 0.03, 0.07);
  if (d < dMin) { dMin = d;  idObj = idDrBod; }
  q.y -= 0.07;
  d = PrRoundBoxDf (q, vec3 (0.06, 0.02, 0.12), 0.04);
  if (d < dMin) { dMin = d;  idObj = idDrLamp; }
  q = qq;
  q.y -= -0.05;
  d = PrSphDf (q, 0.17);
  if (d < dMin) { dMin = d;  idObj = idDrCam; }
  q = qq;
  q.xz = abs (q.xz) - 0.7;
  d = min (PrCylAnDf (q.xzy, 0.5, 0.05, 0.05), PrCylDf (q.xzy, 0.1, 0.03));
  q -= vec3 (-0.4, -0.15, -0.4);
  d = min (d, PrRCylDf (q.xzy, 0.05, 0.03, 0.2));
  q -= vec3 (-0.3, 0.2, -0.3);
  q.xz = Rot2D (q.xz, 0.25 * pi);
  d = min (d, min (PrRCylDf (q, 0.05, 0.02, 1.), PrRCylDf (q.zyx, 0.05, 0.02, 1.)));
  if (d < dMin) { dMin = d;  idObj = idDrBod; }
  return dMin / dSzFac;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 50; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec3 e = vec3 (0.001, -0.001, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec3 TrackPath (float t)
{
  return vec3 (vec2 (sin (t * 0.15), cos (t * 0.17)) * mat2 (4., -1.5, 1.3, 1.7), t);
}

float GrndDf (vec3 p)
{
  vec3 pt;
  float s;
  p.xy -= TrackPath (p.z).xy;
  s = p.y + 3.;
  pt = abs (fract (p + abs (fract (p.zxy) - 0.5)) - 0.5);
  p += (pt - 0.25) * 0.3;
  return min (length (cos (0.6 * p + 0.8 * sin (1.3 * p.zxy))) - 1.1,
     s + 0.07 * dot (pt, vec3 (1.)));
}

float GrndRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = GrndDf (ro + dHit * rd);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

float GrndAO (vec3 ro, vec3 rd)
{
  float ao, d;
  ao = 0.;
  for (int j = 0; j < 8; j ++) {
    d = float (j + 1) / 8.;
    ao += max (0., d - 3. * GrndDf (ro + rd * d));
  }
  return clamp (1. - 0.2 * ao, 0., 1.);
}

vec3 GrndNf (vec3 p)
{
  vec4 v;
  const vec3 e = vec3 (0.001, -0.001, 0.);
  v = vec4 (GrndDf (p + e.xxx), GrndDf (p + e.xyy),
     GrndDf (p + e.yxy), GrndDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float GrndSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.1;
  for (int j = 0; j < 16; j ++) {
    h = GrndDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += max (0.2, 0.1 * d);
    if (sh < 0.05) break;
  }
  return 0.3 + 0.7 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, bgCol, vn, ltDir;
  float dstGrnd, dstObj, ltDist, atten, spec;
  bgCol = vec3 (0.8, 0.8, 0.9);
  dstGrnd = GrndRay (ro, rd);
  dstObj = ObjRay (ro, rd);
  if (min (dstGrnd, dstObj) < dstFar) {
    ltDir = ltPos - ro;
    ltDist = length (ltDir);
    ltDir /= ltDist;
    atten = 1. / (1. + 0.002 * ltDist * ltDist);
    if (dstGrnd < dstObj) {
      ro += rd * dstGrnd;
      vn = GrndNf (ro);
      vn = VaryNf (5. * ro, vn, 50.);
      col = mix (vec3 (0.5, 0.4, 0.1), vec3 (0.4, 0.8, 0.4),
         clamp (0.5 + vn.y, 0., 1.)) *
         (0.2 + 0.8 * max (dot (vn, ltDir), 0.) +
         pow (max (dot (reflect (ltDir, vn), rd), 0.0), 32.)) *
         (0.1 + 0.9 * atten * min (GrndSShadow (ro, ltDir), GrndAO (ro, vn)));
      col = mix (col, bgCol, smoothstep (0.45, 0.99, dstGrnd / dstFar));
    } else {
      ro += rd * dstObj;
      vn = ObjNf (ro);
      if (idObj == idDrBod) {
        col = vec3 (1.5, 1., 1.5);
        spec = 0.5;
      } else if (idObj == idDrLamp) {
        col = mix (vec3 (0.3, 0.3, 2.), vec3 (2., 0., 0.),
           step (0., sin (10. * tCur)));
        spec = -1.;
      } else if (idObj == idDrCam) {
        col = vec3 (0.1, 0.1, 0.1);
        spec = 1.;
      }
      if (spec >= 0.)
        col = col * (0.2 + 0.8 * GrndSShadow (ro, ltDir)) *
           (0.1 + 0.9 * atten * (max (dot (ltDir, vn), 0.) +
           spec * pow (max (dot (reflect (rd, vn), ltDir), 0.), 64.)));
    }
  } else col = bgCol;
  return pow (clamp (col, 0., 1.), vec3 (0.9));
}

void main(void)
{
  mat3 vuMat;
  vec2 mPtr;
  vec3 ro, rd, fpF, fpB, vd;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, s, ss;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = mouse.xy*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  s = 4. * tCur;
  ss = s + 2.5 + 1.5 * cos (0.1 * s);
  dronePos = TrackPath (ss);
  aTilt = vec2 (12. * (TrackPath (ss + 0.1).x - dronePos.x), 0.2);
  fpF = TrackPath (s + 0.1);
  fpB = TrackPath (s - 0.1);
  ro = 0.5 * (fpF + fpB);
  vd = fpF - fpB;
  az = 0.;
  el = 0.;
  //if (mPtr.z > 0.) {
  //  az = az + 2. * pi * mPtr.x;
  //  el = el + 0.95 * pi * mPtr.y;
  //}
  ori = vec2 (el, az + ((length (vd.xz) > 0.) ? atan (vd.x, vd.z) : 0.5 * pi));
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = vuMat * normalize (vec3 (uv, 1.6));
  ltPos = ro + 10. * normalize (vec3 (-0.5, 1., -1.));
  dstFar = 30.;
  glFragColor = vec4 (ShowScene (ro, rd), 2.);
}

float PrSphDf (vec3 p, float s)
{
  return length (p) - s;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCylAnDf (vec3 p, float r, float w, float h)
{
  return max (abs (length (p.xy) - r) - w, abs (p.z) - h);
}

float PrRCylDf (vec3 p, float r, float rt, float h)
{
  vec2 dc;
  float dxy, dz;
  dxy = length (p.xy) - r;
  dz = abs (p.z) - h;
  dc = vec2 (dxy, dz) + rt;
  return min (min (max (dc.x, dz), max (dc.y, dxy)), length (dc) - rt);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec4 t;
  vec2 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv4f (dot (ip, cHashA3.xy));
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
}

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n)) * (1. / 1.9375);
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  float s;
  const vec3 e = vec3 (0.1, 0., 0.);
  s = Fbmn (p, n);
  g = vec3 (Fbmn (p + e.xyy, n) - s, Fbmn (p + e.yxy, n) - s,
     Fbmn (p + e.yyx, n) - s);
  return normalize (n + f * (g - n * dot (n, g)));
}

