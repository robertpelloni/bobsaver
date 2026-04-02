#version 420

// original https://www.shadertoy.com/view/slscWj

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Nautilus at Sunset" by dr2 - 2022
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// (Based on "Nautilus Submerging"; others in series listed in "Nautilus Egg" (7dj3Wz).)

#if 1
#define VAR_ZERO min (frames, 0)
#else
#define VAR_ZERO 0
#endif

float PrBox2Df (vec2 p, vec2 b);
float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
float PrFlatCylDf (vec3 p, float rhi, float rlo, float h);
vec2 Rot2D (vec2 q, float a);
mat3 StdVuMat (float el, float az);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Noisev2v4 (vec4 p);
float Fbm1 (float p);
float Fbm2 (vec2 p);
float Fbm3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 vuPos, sunDir;
float dstFar, tCur, sbLen, sbDepth, prpRot;
int idObj;
const int idBod = 1, idKl = 2, idSth = 3, idSup = 4, idTl = 5, idWinF = 6, idWinS = 7, idProp = 8,
   idSpk = 9, idPlat = 10, idWfrm = 11, idLmpF = 12, idLmpB = 13;
const float pi = 3.1415927;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float WaveHt (vec2 p)
{
  mat2 qRot;
  vec4 t4;
  vec2 q, t, tw;
  float wAmp, h;
  qRot = 2. * mat2 (0.8, -0.6, 0.6, 0.8);
  q = 0.05 * p + vec2 (0., 0.025 * tCur);
  wAmp = 1.;
  h = 0.;
  tw = 0.1 * tCur * vec2 (1., -1.);
  for (int j = 0; j < 5; j ++) {
    q *= qRot;
    t4 = q.xyxy + tw.xxyy;
    t = Noisev2v4 (t4);
    t4 = abs (sin (t4 + 2. * t.xxyy - 1.));
    t4 = (1. - t4) * (t4 + sqrt (1. - t4 * t4));
    t = 1. - sqrt (t4.xz * t4.yw);
    t *= t;
    h += wAmp * dot (t, t);
    wAmp *= 0.5;
  }
  return 0.4 * h * (1. - smoothstep (0.5, 1.2, length (p - vuPos.xz) / dstFar));
}

float WaveRay (vec3 ro, vec3 rd, float u)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  dHit = dstFar;
  ro.y *= u;
  rd.y *= u;
  s = 0.;
  sLo = 0.;
  for (int j = VAR_ZERO; j < 60; j ++) {
    p = ro + s * rd;
    h = p.y - u * WaveHt (p.xz);
    if (h < 0.) break;
    sLo = s;
    s += max (0.5, 1.3 * h) + 0.01 * s;
    if (s > dstFar) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = VAR_ZERO; j < 5; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      if (p.y > u * WaveHt (p.xz)) sLo = s;
      else sHi = s;
    }
    dHit = sHi;
  }
  return dHit;
}

vec3 WaveNf (vec3 p, float d)
{
  vec2 e;
  e = vec2 (max (0.1, 1e-4 * d * d), 0.);
  return normalize (vec3 (WaveHt (p.xz) - vec2 (WaveHt (p.xz + e.xy),
     WaveHt (p.xz + e.yx)), e.x)).xzy;
}

float ObjDf (vec3 p)
{
  vec3 q, qe;
  float dMin, d, rad, s, dph, suLen;
  dMin = dstFar;
  p.y -= sbDepth;
  q = p;
  s = q.z / sbLen;
  rad = 1.2 * (1. - 0.9 * smoothstep (0.4, 1.1, s)) * (1. - 0.85 * smoothstep (0.6, 1.1, - s));
  q.x *= 1.1  - 0.1 * smoothstep (0.7, 0.9, abs (s));
  d = max (mix (max (abs (q.y), dot (abs (q.xy), vec2 (0.866, 0.5))), length (q.xy),
     clamp (s * s, 0., 1.)) - rad, abs (q.z) - sbLen);
  dph = 0.54 - length (q.yz);
  DMIN (idBod);
  q = p;
  d = max (PrRoundBoxDf (q, vec3 (1.2 * rad - 0.05, 0.02, sbLen - 0.02), 0.02), dph);
  DMIN (idPlat);
  s = (q.y > 0.) ? 2. * rad - 0.24 : 1.5 * rad - 0.15;
  d = max (PrRoundBoxDf (q, vec3 (0.03, s, sbLen - 0.02), 0.02),
     - max (PrBox2Df (q.yz, vec2 (s - 0.2, sbLen - 0.1)), - q.y));
  d = max (d, ((q.y > 0.) ? 2. - q.z : 0.4 - abs (q.z - 0.3 * q.y + 1.)));
  DMIN (idKl);
  s += 0.05;
  d = max (PrRoundBoxDf (q, vec3 (0.06, s, sbLen - 0.02), 0.01),
     - PrBox2Df (q.yz, vec2 (s - 0.1, sbLen - 0.1 + 0.1)));
  d = max (max (max (d, abs (mod (q.y + 0.05, 0.1) - 0.05) - 0.03),
     2. - q.z), max (q.y - 2.1, - q.y - 1.65));
  DMIN (idSth);
  q = p;
  q.yz -= vec2 (1.8, -2.8 - 0.5 * (q.y - 1.8));
  d = PrRoundBoxDf (q, vec3 (0.03, 0.35, 0.1), 0.02);
  DMIN (idKl);
  q.z -= 0.1;
  d = max (PrRoundBoxDf (q, vec3 (0.06, 0.3, 0.05), 0.02),
     abs (mod (q.y + 0.05, 0.1) - 0.05) - 0.03);
  DMIN (idSth);
  q = p;
  q.z -= - sbLen + 0.2;
  d = PrRoundBoxDf (q, vec3 (0.03, 1.1 + 0.5 * smoothstep (-1., 0.5, - q.z),
     1.8 - step (q.z, 0.)), 0.02);
  q.z -= -0.35;
  d = max (d, - PrBox2Df (q.yz, vec2 (0.7, 0.15)));
  DMIN (idTl);
  q = p;
  q.z -= sbLen + 1.;
  d = PrCylDf (q, 0.18 * (0.6 - 0.4 * q.z), 1.);
  DMIN (idSpk);
  q = p;
  q.z -= -0.13 - sbLen;
  d = PrCylDf (q, 0.25 * (1. + q.z), 0.13);
  q.xy = Rot2D (q.xy, prpRot);
  s = sign (q.x) * sign (q.y);
  q.xy = Rot2D (abs (q.xy) - 0.25, 0.25 * pi);
  q.xz = Rot2D (q.xz, -0.2 * s * pi);
  d = min (d, PrRoundBoxDf (q, vec3 (0.11, 0.28 * (1. - 4. * q.x * q.x), 0.002), 0.01));
  DMIN (idProp);
  qe = vec3 (abs (p.x), p.yz) - vec3 (0.25, 1.7, 1.95);
  q = p;
  q.yz -= vec2 (1.44, -0.4);
  suLen = 2.7;
  s = q.z / suLen;
  rad = 0.7 * (1. - 0.9 * smoothstep (0., 2., s)) * (1. - 0.5 * smoothstep (0., 2., - s));
  q.x += 0.2 * q.y * sign (q.x);
  d = - PrBox2Df (q.yz - vec2 (1., -2. + 0.2 * q.y), vec2 (1., 3.));
  q.z += 0.2 * q.y * sign (q.z);
  d = max (max (d, PrFlatCylDf (q.zxy, suLen, rad, 0.76)), - PrSphDf (qe, 0.32));
  DMIN (idSup);
  q = p;
  d = PrCylAnDf (q.yzx, 0.53, 0.02, 1.45);
  DMIN (idWfrm);
  q = p;
  q.x = abs (q.x) - 0.85;
  d = max (PrSphDf (q, 0.75), - dph);
  DMIN (idWinS);
  d = PrSphDf (qe, 0.3);
  DMIN (idWinF);
  q = p;
  q.x = abs (q.x);
  q -= vec3 (0.15, 2.1, suLen - 0.35);
  d = PrSphDf (q, 0.08);
  DMIN (idLmpF);
  q = p;
  q.yz -= vec2 (1.42, suLen - 6.27);
  d = PrSphDf (q, 0.05);
  DMIN (idLmpB);
  return 0.7 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float d, dHit;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 160; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.002 || dHit > dstFar) break;
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

vec4 ObjCol (vec3 p, vec3 vn)
{
  vec4 col4, cc, cu, cd, cb;
  float t;
  p.y -= sbDepth;
  cd = vec4 (0.2, 0.2, 0.2, 0.);
  cu = vec4 (0.4, 0.3, 0.2, 0.1);
  cb = vec4 (0.4, 0.4, 0.5, 0.2);
  cc = (p.y > 0.) ? mix (cu, cb, smoothstep (0.45, 0.55, Fbm3 (2. * p))) : cu;
  if (idObj == idBod) {
    col4 = cc * (0.7 + 0.3 * smoothstep (0.05, 0.07, 
       length (mod (vec2 (6. * atan (p.y, - p.x) / pi, 2. * p.z + 0.5), 1.) - 0.5))) *
       (0.7 + 0.3 * max (step (3., abs (p.z + 1.)), smoothstep (0.01, 0.012, abs (p.y + 0.55))));
  } else if (idObj == idPlat) {
    col4 = (abs (vn.y) > 0.2) ? cc : cd;
  } else if (idObj == idWfrm) {
    col4 =  (abs (vn.x) < 0.2) ? cc : cd;
  } else if (idObj == idKl) {
    col4 = (abs (vn.x) > 0.2) ? cu : cd;
  } else if (idObj == idSth) {
    col4 = vec4 (0.5, 0.5, 0.7, 0.2); 
  } else if (idObj == idSup) {
    t = smoothstep (0.05, 0.07, length (mod (vec2 (((abs (p.x) > 0.5) ?
       2. * p.z : 2. * p.x + 0.5), 2. * p.y + 0.5) + 0.5, 1.) - 0.5));
    t = min (t, smoothstep (0.01, 0.012, abs (abs (length (vec2 (p.x, abs (p.z + 1.) - 0.5)) -
       0.18) - 0.12)));
    t = min (t, 1. - step (length (vec2 (p.y - 1.1, abs (abs (p.z + 0.5) - 0.5) - 0.25)), 0.15) *
       smoothstep (0.18, 0.2, abs (mod (24. * p.y + 0.5, 1.) - 0.5)));
    t = min (t, 1. - step (length (vec2 (p.x, p.z - 1.3)), 0.3) *
       smoothstep (0.25, 0.3, abs (mod (12. * p.x + 0.5, 1.) - 0.5)));
    col4 = cc * (0.7 + 0.3 * t);
  } else if (idObj == idTl) {
    col4 = (abs (vn.x) > 0.2) ? cc * (1. - 0.5 * SmoothBump (-0.01, 0.01, 0.003, p.z + 6.28)) : cd;
  } else if (idObj == idProp) {
    col4 = vec4 (0.7, 0.5, 0.2, 0.2) * (0.7 + 0.3 * smoothstep (0.01, 0.012,
       abs (length (p.xy) - 0.6)));
  } else if (idObj == idSpk) {
    col4 = vec4 (0.5, 0.5, 0.7, 0.2) * (0.7 + 0.3 * smoothstep (0.1, 0.15,
       abs (mod (12. * p.z + 0.5, 1.) - 0.5)));
  } else if (idObj == idLmpF) {
    col4 = vec4 (0.8, 0.8, 0.2, -1.);
  } else if (idObj == idLmpB) {
    col4 = vec4 (0.8, 0.2, 0.2, -1.);
  } else if (idObj == idWinF || idObj == idWinS) {
    if (idObj == idWinF) {
      p = vec3 (abs (p.x), p.yz) - vec3 (0.25, 1.7, 1.95);
      p.xy = Rot2D (p.xy, -0.05 * pi);
      p.xz = Rot2D (p.xz, -0.05 * pi);
      t = length (p.yz) - 0.17;
    } else {
      t = length (p.yz) - 0.3;
    }
    if (min (step (0.02, abs (t)), max (step (t, 0.), step (0.02,
       min (abs (p.y + p.z), abs (p.y - p.z))))) == 0.) col4 = cb;
    else col4 = vec4 (0.5, 0.4, 0.2, -1.);
  }
  return col4;
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  int idObjP;
  idObjP = idObj;
  sh = 1.;
  d = 0.1;
  for (int j = VAR_ZERO; j < 20; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  idObj = idObjP;
  return 0.5 + 0.5 * sh;
}

vec2 LBeamDf (vec3 p)
{
  vec3 q;
  float d, bz;
  p.y -= sbDepth;
  q = p;
  q.x = abs (q.x);
  q -= vec3 (0.15, 2.1, 2.35);
  q.yz = Rot2D (q.yz, -0.04 * pi);
  q.xz = Rot2D (q.xz, 0.01 * pi);
  bz = q.z / 20.;
  d = length (q.xy) - 0.08 * (1. + 3. * bz);
  d = 0.9 * max (d, - min (20. * (1. - bz), q.z));
  return vec2 (d, bz);
}

vec2 LBeamRay (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 d2;
  float dHit;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 80; j ++) {
    d2 = LBeamDf (ro + dHit * rd);
    dHit += d2.x;
    if (d2.x < 0.001 || dHit > dstFar) break;
  }
  return vec2 (dHit, d2.y);
}

vec3 LBeamNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = LBeamDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx))).x;
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 SkyHrzCol (vec3 ro, vec3 rd)
{
  vec3 col, p;
  float ds, fd, att, attSum, sd, a;
  a = atan (rd.z, rd.x) + 0.005 * tCur;
  if (rd.y < 0.015 * Fbm1 (32. * a) - 0.005) {
    col = mix (vec3 (0.2, 0.3, 0.2), vec3 (0.3, 0.35, 0.35), 0.5 +
       0.5 * dot (normalize (rd.xz), - normalize (sunDir.xz))) *
       (1. - 0.4 * Fbm2 (64. * vec2 (a, rd.y)));
  } else {
    p = ((200. - ro.y) / rd.y) * rd;
    ds = 0.1 * sqrt (length (p));
    p += ro;
    fd = 0.002 / (smoothstep (0., 10., ds) + 0.1);
    p.xz = p.xz * fd + 0.1 * tCur;
    att = Fbm2 (p.xz);
    attSum = att;
    for (float j = 0.; j < 4.; j ++) {
      attSum += Fbm2 (p.xz + (1. + j * ds) * fd * sunDir.xz);
    }
    attSum *= 0.3;
    att *= 0.3;
    sd = clamp (dot (sunDir, rd), 0., 1.);
    col = mix (vec3 (0.5, 0.75, 1.), mix (vec3 (0.7, 1., 1.), vec3 (1., 0.4, 0.1),
       0.25 + 0.75 * sd), exp (-2. * (3. - sd) * max (rd.y - 0.1, 0.))) +
       0.3 * (vec3 (1., 0.8, 0.7) * pow (sd, 1024.) + vec3 (1., 0.4, 0.2) * pow (sd, 256.));
    attSum = 1. - smoothstep (1., 9., attSum);
    col = mix (vec3 (0.4, 0., 0.2), mix (col, vec3 (0.3, 0.3, 0.3), att), attSum) +
       vec3 (1., 0.4, 0.) * pow (attSum * att, 3.) * (pow (sd, 10.) + 0.5);
  }
  return col;
}

vec3 SeaFloorCol (vec3 rd)
{
  return mix (vec3 (0.05, 0.17, 0.12), vec3 (0., 0.15, 0.2), 
     smoothstep (0.4, 0.7, Fbm2 (2. * rd.xz / rd.y)));
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
  for (int j = VAR_ZERO + 1; j <= 7; j ++) {
    tt = t * (1. + 1. / float (j));
    b = sin (tt + vec4 (- qq + vec2 (0.5 * pi, 0.), qq + vec2 (0., 0.5 * pi)));
    qq = q + tt + b.xy + b.wz;
    c += 1. / length (q / sin (qq + vec2 (0., 0.5 * pi)));
  }
  return clamp (pow (abs (1.25 - abs (0.167 + 40. * c)), 8.), 0., 1.);
}

vec3 UnwCol (vec3 rd)
{
  float t, gd, b;
  t = tCur * 2.;
  b = dot (vec2 (atan (rd.x, rd.z), 0.5 * pi - acos (rd.y)), vec2 (2., sin (rd.x)));
  gd = clamp (sin (5. * b + t), 0., 1.) * clamp (sin (3.5 * b - t), 0., 1.) +
     clamp (sin (21. * b - t), 0., 1.) * clamp (sin (17. * b + t), 0., 1.);
  return vec3 (0.1, 0.3, 0.4) * (0.2 + 0.4 * (rd.y + 1.)) * (1. + 0.1 * gd);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, roc, row, vnw, rdo, rdd, colUw, vnb;
  vec2 lbDist;
  float dstObj, dstWat, dstDom, sh, foamFac, eta, atFac, s, h;
  bool hitWat, unWat;
  eta = 1.33;
  atFac = 5.;
  prpRot = 0.5 * 2. * pi * tCur;
  sbLen = 6.;
  dstDom = 5.;
  roc = ro + dstDom * rd;
  rdo = rd;
  dstObj = ObjRay (ro, rd);
  unWat = (roc.y < WaveHt (roc.xz));
  dstWat = dstDom + WaveRay (roc, rd, (! unWat ? 1. : -1.));
  hitWat = (dstWat < min (dstObj, dstFar));
  if (hitWat) {
    ro += dstWat * rd;
    row = ro;
    vnw = WaveNf (ro, dstWat);
    if (! unWat) {
      rd = refract (rd, vnw, 1. / eta);
    } else {
      vnw *= -1.;
      rdd = refract (rd, vnw, eta);
      rd = (length (rdd) > 0.) ? rdd : reflect (rd, vnw);
    }
    ro += 0.01 * rd;
    dstObj = ObjRay (ro, rd);
  }
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col4 = ObjCol (ro, vn);
    sh = unWat ? 1. : ObjSShadow (ro, sunDir);
    h = WaveHt (ro.xz) - ro.y;
    if (col4.a >= 0.) {
      col = col4.rgb * (0.3 + 0.1 * max (vn.y, 0.) +
         0.2 * max (dot (vn, normalize (vec3 (- sunDir.xz, 0.)).xzy), 0.) +
         0.7 * sh * max (0., max (dot (vn, sunDir), 0.))) + 
         col4.a * step (0.95, sh) * vec3 (1., 0.9, 0.5) * pow (max (0.,
         dot (sunDir, reflect (rd, vn))), 32.);
      if (unWat) col += 0.2 * TurbLt (0.1 * ro, abs (vn), 0.3 * tCur) *
         (1. - smoothstep (0.5, 0.8, dstObj / dstFar)) * smoothstep (0., 0.1, vn.y);
      else col *= 0.6 + 0.4 * (1. - smoothstep (1., 4., h));
    } else col = col4.rgb;
    col *= mix (vec3 (1.), vec3 (0.7, 0.9, 1.), (unWat ? 1. : smoothstep (0., 0.1, h)));
  } else {
    col = (hitWat == unWat) ? SkyHrzCol (ro, rd) : SeaFloorCol (rd);
  }
  if (! unWat) {
    if (hitWat) {
      col = mix (col, 0.8 * SkyHrzCol (row, reflect (rdo, vnw)), pow (1. - abs (dot (rdo, vnw)), 5.));
      s = Fbm3 (128. * row);
      foamFac = pow (smoothstep (0., 1., WaveHt (row.xz) - 0.6) + 0.008 * s, 8.);
      col = mix (col, vec3 (1.), foamFac);
      col = mix (col, 0.9 * SkyHrzCol (ro, rdo), smoothstep (0.2, 0.5, dstWat / dstFar));
    }
  } else {
    colUw = UnwCol (rd);
    if (dstObj < dstFar) {
      col = mix (colUw, col, min (1., exp (1. - atFac * dstObj / dstFar)));
    } else if (dstWat < dstFar) {
      col = (rd.y > 0.) ? mix (colUw, col, exp (- atFac * dstWat / dstFar)) : colUw;
    } else col = colUw;
  }
  if (sbDepth < -2. && unWat) {
    lbDist = LBeamRay (roc, rdo);
    vnb = LBeamNf (roc + lbDist.x * rdo);
    if (lbDist.x < min (dstObj, dstFar))
       col = mix (col, vec3 (0.6, 0.6, 0.7), 0.5 * (1. - lbDist.y) * (0.7 - 0.3 * dot (vnb, rd)));
  }
  return clamp (col, 0., 1.);
}

vec3 ShowExScene (vec2 uv, float pRad)
{
  vec3 col, svn;
  vec2 uvr;
  float cRad, r, a;
  cRad = length (uv) - pRad - 0.1;
  svn = normalize (vec3 (normalize (uv) * SmoothBump (0., 0.03, 0.005,
     abs (abs (cRad) - 0.1)) * sign (cRad), -1.));
  a = 2. * pi * floor (12. * atan (uv.y, - uv.x) / (2. * pi) + 0.5) / 12.;
  uvr = Rot2D (uv, a) + vec2 (pRad + 0.1, 0.);
  r = length (uvr);
  if (r < 0.06) {
    col = vec3 (0.6, 0.5, 0.1);
    svn = normalize (vec3 (Rot2D (uvr, - a) * smoothstep (0., 0.06, r) / r, -1.));
  } else {
    col = vec3 (0.5, 0.5, 0.2);
    svn = VaryNf (64. * vec3 (uv, 1.), svn, 0.5);
  }
  col *= 0.2 + 0.8 * max (dot (svn, normalize (vec3 (1., 1., -1.))), 0.);
  r = min (abs (max (PrBox2Df (uvr, vec2 (0.035)), PrBox2Df (Rot2D (uvr, pi / 4.), vec2 (0.035))) -
     0.005), min (PrBox2Df (uvr, vec2 (0.02, 0.)), PrBox2Df(uvr, vec2 (0., 0.02))));
  r = min (r, abs (length (uvr) - 0.06));
  col = mix (col * (0.1 + 0.9 * smoothstep (0., 0.004, r)),
     vec3 (0.15, 0.2, 0.15) * (0.8 + 0.2 * Fbm2 (128. * uv)), step (0.1, cRad));
  return col;
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, pRad;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  pRad = 0.85;
  if (length (uv) < pRad) {
    az = 0.7 * pi;
    el = 0.05 * pi;
    if (mPtr.z > 0.) {
      az += 0.5 * pi * mPtr.x;
      el += 0.4 * pi * mPtr.y;
    }
    az += 0.05 * pi * (SmoothBump (0.25, 0.75, 0.2, mod (0.005 * tCur, 1.)) - 0.5);
    el += 0.2 * pi * (SmoothBump (0.25, 0.75, 0.2, mod (0.012 * tCur, 1.)) - 0.5);
    az = clamp (az, 0.55 * pi, 0.9 * pi);
    el = clamp (el, -0.3 * pi, 0.3 * pi);
    zmFac = 3.2;
    vuMat = StdVuMat (el, az);
    ro = vuMat * vec3 (0., 0., -40.);
    rd = vuMat * normalize (vec3 (uv, zmFac));
    sbDepth = -4. + 4. * sin (0.05 * pi * tCur);
    ro.y += sbDepth;
    vuPos = ro;
    sunDir = normalize (vec3 (0., 0.1, -1.));
    sunDir.xz = Rot2D (sunDir.xz, az - 0.4 * pi);
    dstFar = 300.;
    col = ShowScene (ro, rd);
  } else {
    col = ShowExScene (uv, pRad);
  }
  glFragColor = vec4 (col, 1.);
}

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d;
  d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
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

float PrFlatCylDf (vec3 p, float rhi, float rlo, float h)
{
  return max (length (p.xy - vec2 (clamp (p.x, - rhi, rhi), 0.)) - rlo, abs (p.z) - h);
}

float PrCylAnDf (vec3 p, float r, float w, float h)
{
  return max (abs (length (p.xy) - r) - w, abs (p.z) - h);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
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

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

const float cHashM = 43758.54;

vec2 Hashv2f (float p)
{
  return fract (sin (p + vec2 (0., 1.)) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + vec4 (0., 1., 57., 58.)) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  return fract (sin (dot (p, cHashVA3) + vec4 (0., cHashVA3.xy, cHashVA3.x + cHashVA3.y)) * cHashM);
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

vec2 Noisev2v4 (vec4 p)
{
  vec4 ip, fp, t1, t2;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t1 = Hashv4f (dot (ip.xy, vec2 (1., 57.)));
  t2 = Hashv4f (dot (ip.zw, vec2 (1., 57.)));
  return vec2 (mix (mix (t1.x, t1.y, fp.x), mix (t1.z, t1.w, fp.x), fp.y),
               mix (mix (t2.x, t2.y, fp.z), mix (t2.z, t2.w, fp.z), fp.w));
}

float Fbm1 (float p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    f += a * Noiseff (p);
    a *= 0.5;
    p *= 2.;

  }
  return f * (1. / 1.9375);
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

float Fbm3 (vec3 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    f += a * Noisefv3 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
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
  vec4 v;
  vec3 g;
  vec2 e;
  e = vec2 (0.1, 0.);
  for (int j = VAR_ZERO; j < 4; j ++)
     v[j] = Fbmn (p + ((j < 2) ? ((j == 0) ? e.xyy : e.yxy) : ((j == 2) ? e.yyx : e.yyy)), n);
  g = v.xyz - v.w;
  return normalize (n + f * (g - n * dot (n, g)));
}
