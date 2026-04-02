#version 420

// original https://www.shadertoy.com/view/wdSyRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Cave Dolphins" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrSphDf (vec3 p, float r);
float PrEllipsDf (vec3 p, vec3 r);
float Minv3 (vec3 p);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Hashfv3 (vec3 p);
vec3 Hashv3v3 (vec3 p);
float Noisefv3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 fishPos, ltPos, ltAx;
vec2 trkAx, trkAy, trkFx, trkFy;
float fishAngH, fishAngV, fishAngI, dstFar, tCur;
int idObj;
bool isSh, isPano;
const float pi = 3.14159;

vec3 TrackPath (float t)
{
  return vec3 (dot (trkAx, sin (trkFx * t)), dot (trkAy, sin (trkFy * t)), t);
}

vec3 TrackVel (float t)
{
  return vec3 (dot (trkAx * trkFx, cos (trkFx * t)), dot (trkAy * trkFy, cos (trkFy * t)), 1);
}

float VPoly (vec3 p)
{
  vec3 ip, fp, a, w;
  p *= 14.;
  ip = floor (p);
  fp = fract (p);
  a = vec3 (4.);
  for (float gz = -1.; gz <= 1.; gz ++) {
    for (float gy = -1.; gy <= 1.; gy ++) {
      for (float gx = -1.; gx <= 1.; gx ++) {
        w = vec3 (gx, gy, gz) + 0.8 * Hashv3v3 (ip + vec3 (gx, gy, gz)) - fp;
        a.z = dot (w, w);
        if (a.z < a.x) a.xy = a.zx;
        else a.y = min (a.z, a.y);
      }
    }
  }
  return sqrt (a.y - a.x);
}

float FishDf (vec3 p, float dMin)
{
  vec3 q;
  float szFac, dm, dBodyF, dBodyB, dMouth, dFinT, dFinP, dFinD, dEye;
  int id;
  szFac = 0.25;
  dMin /= szFac;
  p = (p - fishPos) / szFac;
  p.xz = Rot2D (p.xz, fishAngH);
  p.yz = Rot2D (p.yz, fishAngV);
  p.x = abs (p.x);
  p.z -= 0.2;
  p.yz = Rot2D (p.yz, 0.2 * fishAngI);
  q = p;
  q.z -= -0.06;
  dBodyF = PrEllipsDf (q, vec3 (0.07, 0.08, 0.24));
  q = p;
  q.z -= -0.12;
  q.yz = Rot2D (q.yz, fishAngI);
  q.z -= -0.16;
  dBodyB = PrEllipsDf (q, vec3 (0.035, 0.05, 0.25));
  q.z -= -0.22;
  q.yz = Rot2D (q.yz, 2. * fishAngI);
  q.xz -= vec2 (0.05, -0.05);
  q.xz = Rot2D (q.xz, 0.4);
  dFinT = PrEllipsDf (q, vec3 (0.08, 0.007, 0.04));
  q = p;
  q.yz -= vec2 (-0.03, 0.17);
  q.yz = Rot2D (q.yz, 0.1);
  q.y = abs (q.y) - 0.004;
  dMouth = PrEllipsDf (q, vec3 (0.025, 0.012, 0.06));
  q = p;
  q.yz -= vec2 (0.07, -0.1);
  q.yz = Rot2D (q.yz, 0.6);
  dFinD = PrEllipsDf (q, vec3 (0.005, 0.1, 0.035));
  q = p;
  q.xy = Rot2D (q.xy, 0.8);
  q.xz -= vec2 (0.07, -0.01);
  q.xz = Rot2D (q.xz, 0.6);
  dFinP = PrEllipsDf (q, vec3 (0.09, 0.004, 0.03));
  q = p;
  q -= vec3 (0.04, 0.01, 0.11);
  dEye = PrSphDf (q, 0.015);
  dm = SmoothMin (dBodyF, dBodyB, 0.03);
  dm = SmoothMin (dm, dFinT, 0.01);
  dm = SmoothMin (dm, dMouth, 0.015);
  dm = SmoothMin (dm, dFinD, 0.002);
  dm = SmoothMin (dm, dFinP, 0.002);
  if (dm < dEye) id = 2;
  else {
    dm = dEye;
    id = 3;
  }
  if (dm < dMin) {
    dMin = dm;
    idObj = id;
  }
  return dMin * szFac;
}

float ObjDf (vec3 p)
{
  vec3 q, db;
  float dMin, r, b;
  const float dSzFac = 15.;
  q = p;
  q.xy -= TrackPath (q.z).xy;
  r = floor (8. * Hashfv3 (floor (q)));
  q = fract (q);
  if (r >= 4.) q = q.yxz;
  r = mod (r, 4.);
  if (mod (r, 2.) == 0.) q.x = 1. - q.x;
  if (abs (r - 1.5) == 0.5) q.y = 1. - q.y;
  db = vec3 (length (vec2 (length (q.xy) - 0.5, q.z - 0.5)),
     length (vec2 (length (vec2 (q.z, 1. - q.x)) - 0.5, q.y - 0.5)),
     length (vec2 (length (1. - q.yz) - 0.5, q.x - 0.5)));
  dMin = 0.7 * (Minv3 (db) - 0.1 - 0.017 * VPoly (p));
  idObj = 1; 
  if (! isSh) dMin = FishDf (p, dMin);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
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
  for (int j = 0; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd, float ltDist)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 20; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.03 * d, h));
    d += h;
    if (sh < 0.05 || d > ltDist) break;
  }
  return 0.5 + 0.5 * sh;
}

float WatShd (vec3 rd)
{
  vec2 p;
  float t, h;
  if (rd.y == 0.) rd.y = 0.0001;
  p = 20. * rd.xz / rd.y;
  t = tCur * 2.;
  h = sin (2. * p.x + 0.77 * t + sin (0.73 * p.y - t)) + sin (0.81 * p.y - 0.89 * t +
     sin (0.33 * p.x + 0.34 * t)) + 0.5 * (sin (1.43 * p.x - t) + sin (0.63 * p.y + t));
  h *= 0.04 * smoothstep (0.5, 1., rd.y);
  return h;
}

vec3 BgCol (vec3 rd)
{
  float t, gd, b;
  t = tCur * 4.;
  b = dot (vec2 (atan (rd.x, rd.z), 0.5 * pi - acos (rd.y)), vec2 (2., sin (rd.x)));
  gd = clamp (sin (5. * b + t), 0., 1.) * clamp (sin (3.5 * b - t), 0., 1.) +
     clamp (sin (21. * b - t), 0., 1.) * clamp (sin (17. * b + t), 0., 1.);
  return mix (vec3 (0., 0.5, 0.8), vec3 (0.25, 0.4, 1.), 0.5 + 0.5 * rd.y) *
     (0.24 + 0.44 * (rd.y + 1.) * (rd.y + 1.)) * (1. + gd * 0.05);
}

float TurbLt (vec3 p, vec3 n, float t)
{
  vec4 b;
  vec2 q, qq;
  float c, tt;
  q = 2. * pi * mod (vec2 (dot (p.yzx, n), dot (p.zxy, n)), 1.) - 256.;
  t += 11.;
  c = 0.;
  qq = q;
  for (int j = 1; j <= 7; j ++) {
    tt = t * (1. + 1. / float (j));
    b = sin (tt + vec4 (- qq + vec2 (0.5 * pi, 0.), qq + vec2 (0., 0.5 * pi)));
    qq = q + tt + b.xy + b.wz;
    c += 1. / length (q / sin (qq + vec2 (0., 0.5 * pi)));
  }
  return clamp (pow (abs (1.25 - abs (0.167 + 40. * c)), 8.), 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, bgCol, vn, vno, roo, ltVec, ltDir;
  float dstObj, ltDist, sh, atten, eDark, aDotL;
  roo = ro;
  isSh = false;
  dstObj = ObjRay (ro, rd);
  bgCol = BgCol (rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    vno = vn;
    if (idObj == 1) {
      col4 = vec4 (mix (vec3 (0.7, 0.75, 0.7), vec3 (0.7, 0.7, 0.75),
         smoothstep (0.45, 0.55, Noisefv3 (41.1 * ro))), 0.3);
      col4 *= 1. - 0.2 * Noisefv3 (19.1 * ro);
      vn = VaryNf (64. * ro, vn, 2.);
    } else if (idObj == 2) {
      col4 = vec4 (vec3 (0.95, 0.8, 0.7) * (1. - 0.3 * smoothstep (-0.5, -0.4, vn.y)), 0.2);
    } else if (idObj == 3) {
      col4 = vec4 (0.5, 1., 0.5, -1.);
    }
    ltVec = roo + ltPos - ro;
    ltDist = length (ltVec);
    ltDir = ltVec / ltDist;
    aDotL = dot (ltAx, - ltDir);
    atten = min (1., 0.3 + (isPano ? smoothstep (-1., 0., aDotL) :
       smoothstep (0.6, 0.9, aDotL)) / (1. + 0.3 * ltDist * ltDist));
    if (col4.a >= 0.) {
      isSh = true;
      eDark = (idObj == 1) ? 0.8 + 0.2 * smoothstep (0.2, 0.3, VPoly (ro)) : 1.;
      sh = ObjSShadow (ro, ltDir, ltDist);
      col = atten * col4.rgb * (0.2 + 0.8 * sh * max (dot (vn, ltDir), 0.) +
         col4.a * step (0.95, sh) * pow (max (dot (reflect (rd, vn), ltDir), 0.), 64.)) * eDark;
    } else col = col4.rgb;
    col += 0.2 * step (0.95, sh) * TurbLt (0.05 * ro, abs (vno), 0.5 * tCur) *
       (1. - smoothstep (0.5, 0.8, dstObj / dstFar)) * smoothstep (-0.2, -0.1, vno.y);
    col = mix (col, bgCol, 0.1 + 0.9 * smoothstep (0., 0.85, dstObj / dstFar));
  } else col = bgCol + WatShd (rd);
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, vd, col;
  vec2 canvas, uv;
  float az, el, zmFac, fSpd, t;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  isPano = (mPtr.z <= 0.);
  if (isPano) az = pi;
  else {
    t = mod (0.02 * tCur, 2.);
    az = pi * SmoothBump (0.25, 0.75, 0.07, mod (t, 1.)) * (2. * floor (t) - 1.);
  }
  el = 0.;
  if (! isPano && mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  }
  if (abs (uv.y) < 0.85) {
    trkAx = vec2 (2., 0.9);
    trkAy = vec2 (1.3, 0.66);
    trkFx = vec2 (0.2, 0.23);
    trkFy = vec2 (0.17, 0.24);
    fSpd = 0.2;
    t = fSpd * tCur;
    ro = TrackPath (t);
    ro.xy += 0.05 * sin (0.05 * pi * tCur);
    vd = normalize (TrackVel (t));
    vuMat = StdVuMat (el + sin (vd.y), az + atan (vd.x, vd.z));
    t += (isPano ? 0.2 : 0.4) * sign (0.5 * pi - abs (az));
    fishPos = TrackPath (t);
    vd = normalize (TrackVel (t));
    fishAngH = atan (vd.x, vd.z);
    fishAngV = sin (vd.y);
    fishAngI = 0.1 * sin (pi * tCur);
    zmFac = isPano ? 0.6 : 2.2;
    uv /= zmFac;
    rd = vuMat * normalize (isPano ? vec3 (sin (uv.x + vec2 (0., 0.5 * pi)), uv.y).xzy : vec3 (uv, 1.));
    ltPos = vuMat * vec3 (0., 0.3, 0.);
    ltAx = vuMat * vec3 (0., 0., 1.);
    dstFar = 16.;
    col = ShowScene (ro, rd);
  } else col = vec3 (0.);
  glFragColor = vec4 (col, 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}
float PrEllipsDf (vec3 p, vec3 r)
{
  return (length (p / r) - 1.) * min (r.x, min (r.y, r.z));
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
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

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

vec3 Hashv3v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  return fract (sin (dot (p, cHashVA3) + vec3 (0., cHashVA3.xy)) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
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

float Noisefv3 (vec3 p)
{
  vec4 t;
  vec3 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp *= fp * (3. - 2. * fp);
  t = mix (Hashv4v3 (ip), Hashv4v3 (ip + vec3 (0., 0., 1.)), fp.z);
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
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
