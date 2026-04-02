#version 420

// original https://www.shadertoy.com/view/4dsBWf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Truchet Flythrough 2" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// The original updated to use cubic cell Truchet (see Truchet Tentacles by WAHa_06x36 for mapping)

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
float PrRCylDf (vec3 p, float r, float rt, float h);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
float Hashfv3 (vec3 p);
float Noisefv3 (vec3 p);

vec3 dronePos[2], ltPos;
vec2 aTilt[2];
float dstFar, tCur;
int idObj;
const int idDrBod = 11, idDrLamp = 12, idDrCam = 13;
const float pi = 3.14159;

float DroneDf (vec3 p, float dMin)
{
  vec3 q;
  float d;
  q = p;
  q.y -= 0.05;
  d = PrRCylDf (q.xzy, 0.2, 0.03, 0.07);
  if (d < dMin) { dMin = d;  idObj = idDrBod; }
  q.y -= 0.07;
  d = PrRoundBoxDf (q, vec3 (0.06, 0.02, 0.12), 0.04);
  if (d < dMin) { dMin = d;  idObj = idDrLamp; }
  q = p;
  q.y -= -0.05;
  d = PrSphDf (q, 0.17);
  if (d < dMin) { dMin = d;  idObj = idDrCam; }
  q = p;
  q.xz = abs (q.xz) - 0.7;
  d = min (PrCylAnDf (q.xzy, 0.5, 0.05, 0.05), PrCylDf (q.xzy, 0.1, 0.03));
  q -= vec3 (-0.4, -0.15, -0.4);
  d = min (d, PrRCylDf (q.xzy, 0.05, 0.03, 0.2));
  q -= vec3 (-0.3, 0.2, -0.3);
  q.xz = Rot2D (q.xz, 0.25 * pi);
  d = min (d, min (PrRCylDf (q, 0.05, 0.02, 1.), PrRCylDf (q.zyx, 0.05, 0.02, 1.)));
  if (d < dMin) { dMin = d;  idObj = idDrBod; }
  return dMin;
}

vec3 TrackPath (float t)
{
  return vec3 (2. * sin (0.2 * t) + 0.9 * sin (0.23 * t),
     1.3 * sin (0.17 * t) + 0.66 * sin (0.24 * t), t);
}

vec2 TubeNutDf (vec3 p)
{
  vec3 q;
  float a, dNut, dTor;
  float radI = 0.05;
  p.z -= 0.5;
  q = p;
  a = atan (- q.y, q.x);
  q.xy = Rot2D (q.xy, 2. * pi * (floor (8. * a / (2. * pi)) + 0.5) / 8.);
  q.x -= 0.5;
  q = abs (q);
  dNut = max (max (max (q.x * 0.866 + q.z * 0.5, q.z) - radI - 0.015,
     q.y - 0.03), 0.007 - q.y);
  dNut = min (dNut, PrRCylDf (q.xzy, radI + 0.005, 0.001, 0.045));
  dTor = length (vec2 (length (p.xy) - 0.5, p.z)) - radI +
     0.004 * SmoothBump (0.2, 0.8, 0.07, mod (24. * a + 1./24., 1.));
  return vec2 (dTor, dNut);
}

float ObjDf (vec3 p)
{
  vec3 q;
  vec2 vMin;
  float dMin, r;
  const float dSzFac = 15.;
  q = p;
  q.xy -= TrackPath (q.z).xy;
  r = floor (8. * Hashfv3 (floor (q)));
  q = fract (q);
  if (r >= 4.) q = q.yxz;
  r = mod (r, 4.);
  if (r == 0.) q.x = 1. - q.x;
  else if (r == 1.) q.y = 1. - q.y;
  else if (r == 2.) q.xy = 1. - q.xy;
  vMin = min (TubeNutDf (q), min (TubeNutDf (vec3 (q.z, 1. - q.x, q.y)),
     TubeNutDf (vec3 (1. - q.yz, q.x))));
  if (vMin.x < vMin.y) { dMin = vMin.x;  idObj = 1; }
  else { dMin = vMin.y;  idObj = 2; }
  dMin *= 0.9;
  dMin *= dSzFac;
  for (int k = 0; k < 2; k ++) {
    q = dSzFac * (p - dronePos[k]);
    q.yz = Rot2D (q.yz, - aTilt[k].y);
    q.yx = Rot2D (q.yx, - aTilt[k].x);
    dMin = DroneDf (q, dMin);
  }
  dMin /= dSzFac;
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = ObjDf (ro + rd * dHit);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
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

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 16; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += 0.07;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, ltVec;
  float dHit, ltDist, sh, spec;
  dHit = ObjRay (ro, rd);
  if (dHit < dstFar) {
    ro += dHit * rd;
    if (idObj >= idDrBod) {
      if (idObj == idDrBod) {
        col = vec3 (0.2, 0.2, 0.9);
        spec = 1.;
      } else if (idObj == idDrLamp) {
        col = mix (vec3 (0., 1., 0.), vec3 (1., 0., 0.),
           step (0., sin (10. * tCur)));
        spec = -1.;
      } else if (idObj == idDrCam) {
        col = vec3 (0.1);
        spec = 1.;
      }
    } else {
      if (idObj == 1) col = vec3 (1., 0.5, 0.);
      else col = vec3 (1., 1., 0.2);
      col *= 0.5 + 0.5 * smoothstep (0., 1., 0.5 + 0.5 * Noisefv3 (500. * ro));
      spec = 0.3;
    }
    vn = ObjNf (ro);
    ltVec = ltPos - ro;
    ltDist = length (ltVec);
    ltVec /= ltDist;
    if (spec >= 0.) {
      sh = ObjSShadow (ro, ltVec);
      col = col * (0.1 + 0.9 * sh * max (dot (vn, ltVec), 0.)) +
         spec * sh * pow (max (dot (normalize (vn - rd), vn), 0.), 64.);
      col *= 1. / (1. + 0.1 * ltDist * ltDist);
    }
  } else col = vec3 (0.);
  return col;
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, pF, pB, u, vd;
  vec2 canvas, uv, ori, ca, sa;
  float az, el, asp, zmFac, vFly, f;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  asp = canvas.x / canvas.y;
  vFly = 1.5;
  for (int k = 0; k < 2; k ++) {
    dronePos[k] = TrackPath (vFly * tCur + 0.5 + 0.8 * float (k));
    dronePos[k].y += 0.06 * (1. - 2. * float (k)) * sin (0.2 * tCur);
    aTilt[k] = vec2 (20. * (TrackPath (dronePos[k].z + 0.05).x -
       dronePos[k].x), 0.2);
  }
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az = 2. * pi * mPtr.x;
    el = -0.1 * pi + pi * mPtr.y;
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  zmFac = 2.;
  rd = normalize (vec3 ((2. * tan (0.5 * atan (uv.x / (asp * zmFac)))) * asp,
    uv.y / zmFac, 1.));
  pF = TrackPath (vFly * tCur + 0.1);
  pB = TrackPath (vFly * tCur - 0.1);
  ro = 0.5 * (pF + pB);
  vd = normalize (pF - pB);
  u = - vd.y * vd;
  f = 1. / sqrt (1. - vd.y * vd.y);
  vuMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd) *
     vuMat;
  rd = vuMat * rd;
  rd.xy = Rot2D (rd.xy, 2. * (pF.x - pB.x));
  ltPos = ro + vuMat * vec3 (0.3, 0.5, 0.1);
  dstFar = 30.;
  glFragColor = vec4 (pow (clamp (ShowScene (ro, rd), 0., 1.), vec3 (0.8)), 1.);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
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

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

float Hashfv3 (vec3 p)
{
  return fract (sin (dot (p, cHashA3)) * cHashM);
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noisefv3 (vec3 p)
{
  vec4 t1, t2;
  vec3 ip, fp;
  float q;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  q = dot (ip, cHashA3);
  t1 = Hashv4f (q);
  t2 = Hashv4f (q + cHashA3.z);
  return mix (mix (mix (t1.x, t1.y, fp.x), mix (t1.z, t1.w, fp.x), fp.y),
              mix (mix (t2.x, t2.y, fp.x), mix (t2.z, t2.w, fp.x), fp.y), fp.z);
}

