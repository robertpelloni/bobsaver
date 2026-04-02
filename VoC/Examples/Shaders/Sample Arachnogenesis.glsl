#version 420

// original https://www.shadertoy.com/view/Ndc3RH

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Arachnogenesis" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  No. 7 in "Spider" series
    "Octopod"                     (4tjSDc)
    "Moebius Strip"               (lddSW2)
    "Moebius Strip 2"             (MscXWX)
    "Spider Ascent"               (4sd3WX)
    "Moebius, Menger, Spiders"    (wsXyzM)
    "Helical Ramps with Spiders"  (3sscWf)
*/

float PrSphDf (vec3 p, float r);
float PrEETapCylDf (vec3 p, vec3 v1, vec3 v2, float r, float rf);
float PrEllipsDf (vec3 p, vec3 r);
float Maxv3 (vec3 p);
float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);

#if 0
#define VAR_ZERO min (frames, 0)
#else
#define VAR_ZERO 0
#endif

vec3 footPos[8], kneePos[8], hipPos[8], ltDir, qHit;
float tCur, dstFar, legLenU, legLenD, bdyHt, spdVel;
int idObj;
const int idBdy = 1, idHead = 2, idEye = 3, idAnt = 4, idLegU = 5, idLegD = 6;
const float pi = 3.1415927;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float SpdDf (vec3 p, float dMin)
{ // (see "Moebius, Menger, Spiders")
  vec3 q;
  float d, s, len, szFac;
  szFac = 0.12;
  p /= szFac;
  dMin /= szFac; 
  p.y -= bdyHt - 0.1;
  q = p - vec3 (0., -0.15, 0.2);
  d = PrEllipsDf (q, vec3 (0.7, 0.5, 1.3));
  DMINQ (idBdy);
  q = p - vec3 (0., 0.1, 1.1);
  d = PrEllipsDf (q, vec3 (0.2, 0.4, 0.5));
  DMINQ (idHead);
  q = p;
  q.x = abs (q.x);
  q -= vec3 (0.15, 0.25, 1.5);
  d = PrSphDf (q, 0.13);
  DMINQ (idEye);
  q -= vec3 (0., 0.15, -0.3);
  d = PrEETapCylDf (q, 1.3 * vec3 (0.3, 1.1, 0.4), vec3 (0.), 0.07, 0.7);
  DMINQ (idAnt);
  p.y += bdyHt;
  for (int j = 0; j < 8; j ++) {
    q = p - hipPos[j];
    d = 0.6 * PrEETapCylDf (q, kneePos[j], hipPos[j], 0.25, 0.3);
    DMINQ (idLegU);
    q = p - kneePos[j];
    d = 0.6 * PrEETapCylDf (q, footPos[j] - vec3 (0.3), kneePos[j] - vec3 (0.3), 0.2, 1.2);
    DMINQ (idLegD);
  }
  dMin *= szFac;
  return dMin;
}

float ObjDf (vec3 p)
{ // (see "Spiraling Out")
  vec3 q;
  float dMin, d, r, a;
  dMin = dstFar;
  q = p;
  r = length (q.xz);
  if (r > 0.01) {
    a = atan (q.z, q.x) / pi;
    q.xz = - (mod (vec2 (0.5 * (pi * log (r) + a) - 0.05 * tCur, 5. * a) + 0.5, 1.) - 0.5);
    q.y *= 0.7 / sqrt (r);
    dMin = 0.5 * r * SpdDf (q, dMin);
  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 160; j ++) {
    p = ro + dHit * rd;
    d = ObjDf (p);
    if (d < 0.0005 || dHit > dstFar || p.y < 0.) break;
    dHit += d;
  }
  if (p.y < 0.) dHit = dstFar;
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

float ObjSShadow (vec3 ro, vec3 rd, float dMax)
{
  float sh, d, h;
  sh = 1.;
  d = 0.01;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += max (h, 0.01);
    if (h < 0.001 || d > dMax) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 SpdCol (vec3 vn)
{
  vec3 col, c1, c2;
  c1 = vec3 (0.5, 1., 0.2);
  c2 = vec3 (0.5, 0.2, 0.2);
  if (idObj == idBdy) {
    col = mix (c1, c2, SmoothBump (0.2, 0.7, 0.05, mod (4. * qHit.z, 1.)));
  } else if (idObj == idHead) {
    col = c2;
    if (qHit.z > 0.4) col = mix (vec3 (0.2, 0.05, 0.05), col,
       smoothstep (0.02, 0.04, abs (qHit.x)));
  } else if (idObj == idEye) {
    col = (vn.z < 0.6) ? vec3 (0., 1., 0.) : c1;
  } else if (idObj == idLegU || idObj == idLegD) {
    col = mix (c2, c1,  SmoothBump (0.4, 1., 0.2, fract (3.5 * length (qHit))));
  } else if (idObj == idAnt) {
    col = vec3 (1., 1., 0.3);
  }
  return col;
}

void SpdSetup (float gDisp)
{
  vec3 v;
  float a, az, fz, d, ll;
  for (int j = 0; j < 4; j ++) {
    a = 0.2 * (1. + float (j)) * pi;
    hipPos[j] = 0.5 * vec3 (- sin (a), 0., 1.5 * cos (a));
    hipPos[j + 4] = hipPos[j];
    hipPos[j + 4].x *= -1.;
  }
  bdyHt = 1.5;
  legLenU = 2.2;
  legLenD = 3.;
  ll = legLenD * legLenD - legLenU * legLenU;
  for (int j = 0; j < 8; j ++) {
    fz = fract ((gDisp + 0.93 + ((j < 4) ? -1. : 1.) + mod (7. - float (j), 4.)) / 3.);
    az = smoothstep (0.7, 1., fz);
    footPos[j] = 5. * hipPos[j];
    footPos[j].x *= 1.7;
    footPos[j].y += 0.7 * sin (pi * clamp (1.4 * az - 0.4, 0., 1.));
    footPos[j].z += ((j < 3) ? 0.5 : 1.) - 3. * (fz - az);
    hipPos[j] += vec3 (0., bdyHt - 0.3, 0.2);
    v = footPos[j] - hipPos[j];
    d = length (v);
    a = asin ((hipPos[j].y - footPos[j].y) / d);
    kneePos[j].y = footPos[j].y + legLenD *
       sin (acos ((d * d + ll) / (2. * d *  legLenD)) + a);
    kneePos[j].xz = hipPos[j].xz + legLenU * sin (acos ((d * d - ll) /
       (2. * d *  legLenU)) + 0.5 * pi - a) * normalize (v.xz);
  }
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj, sh;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col = SpdCol (vn);
    if (idObj != idEye) col = Maxv3 (col) * vec3 (1.);
    col = col * (0.2 + 0.8 * max (dot (vn, ltDir), 0.)) +
       0.2 * pow (max (dot (ltDir, reflect (rd, vn)), 0.), 32.);
    col = mix (vec3 (0.3), col, smoothstep (0.05, 0.1, length (vec2 (ro.xz))));
  } else if (rd.y < 0.) {
    ro += (- ro.y / rd.y) * rd;
    vn = vec3 (0., 1., 0.);
    sh = ObjSShadow (ro + 0.01 * vn, ltDir, dstFar);
    col = vec3 (0.4) * (0.2 + 0.8 * sh * max (dot (vn, ltDir), 0.));
  } else col = vec3 (0.4);
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, vd, col;
  vec2 canvas, uv;
  float el, az, zmFac;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = -0.03 * pi * tCur;
  el = -0.2 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.5 * pi * mPtr.y;
  }
  el = clamp (el, -0.35 * pi, -0.15 * pi);
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -30.);
  zmFac = 4.;
  dstFar = 100.;
  ltDir = vuMat * normalize (vec3 (0.7, 1., -1.));
  spdVel = 1.5;
  SpdSetup (spdVel * tCur);
  rd = vuMat * normalize (vec3 (uv, zmFac));
  col = ShowScene (ro, rd);
  glFragColor = vec4 (col, 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrEETapCylDf (vec3 p, vec3 v1, vec3 v2, float r, float rf)
{
  vec3 v;
  float s;
  v = v1 - v2;
  s = clamp (dot (p, v) / dot (v, v), 0., 1.);
  return length (p - s * v) - r * (1. - rf * s * s);
}

float PrEllipsDf (vec3 p, vec3 r)
{
  return (length (p / r) - 1.) * min (r.x, min (r.y, r.z));
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
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
