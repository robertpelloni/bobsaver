#version 420

// original https://www.shadertoy.com/view/MdyyzG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Tesla's Laboratory" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
float Noisefv2 (vec2 p);
float Fbm1 (float p);
float Fbm2 (vec2 p);
float Fbm2p (vec2 p);

vec4 pth[4];
vec3 qHit, qnBlk[2], bSize;
float tCur, dstFar, illum, illumMin;
int idObj;
const float pi = 3.14159;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  p.y -= 4.6;
  if (illum > 0.) {
    for (int k = 0; k < 4; k ++) {
      q = p;
      q.xz = Rot2D (q.xz, (0.5 + float (k)) * 0.5 * pi);
      q.y -= 0.2 * Fbm1 (5. * tCur);
      q.z += 4.5;
      q.yz = Rot2D (q.yz, 0.1 * pi);
      d = PrCylDf (q, 0.85, 4.);
      if (d < dMin) {
        q.xy -= SmoothBump (-3.5, 3.9, 0.5, q.z) * (2. *
           vec2 (Fbm2p (vec2 (0.4 * q.z, 0.) + pth[k].xy),
           Fbm2p (vec2 (0.3 * q.z, 0.) + pth[k].zw)) - 1.);
        d = PrCylDf (q, 0.015, 4.);
        DMINQ (1);
      }
    }
  }
  dMin *= 0.5;
  q = p;
  q.y -= 1.4;
  d = PrSphDf (q, 0.8);
  DMINQ (2);
  q.y -= -3.;
  d = PrCylDf (q.xzy, 0.3 + 0.05 * abs (sin (4. * pi * q.y)), 3.);
  DMINQ (3);
  q.y -= -2.95;
  d = PrCylDf (q.xzy, 1., 0.05);
  DMINQ (4);
  q = p;
  q.xz = abs (q.xz) - 5.9;
  q.y -= -1.2;
  d = PrSphDf (q, 0.3);
  DMINQ (2);
  q.y -= -1.7;
  d = PrCylDf (q.xzy, 0.15 + 0.02 * abs (sin (4. * pi * q.y)), 1.7);
  DMINQ (3);
  q.y -= -1.67;
  d = PrCylDf (q.xzy, 0.5, 0.03);
  DMINQ (4);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = ObjDf (ro + rd * dHit);
    if (d < 0.0005 || dHit > dstFar) break;
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

vec2 BlkHit (vec3 ro, vec3 rd, vec3 bSize)
{
  vec3 v, tm, tp;
  float dMin, dn, df;
  if (rd.x == 0.) rd.x = 0.001;
  if (rd.y == 0.) rd.y = 0.001;
  if (rd.z == 0.) rd.z = 0.001;
  v = ro / rd;
  tp = bSize / abs (rd) - v;
  tm = - tp - 2. * v;
  dn = max (max (tm.x, tm.y), tm.z);
  df = min (min (tp.x, tp.y), tp.z);
  dMin = dstFar;
  if (df > 0. && dn < df) {
    dMin = dn;
    qnBlk[0] = - sign (rd) * step (tm.zxy, tm) * step (tm.yzx, tm);
    qnBlk[1] = - sign (rd) * step (tp, tp.zxy) * step (tp, tp.yzx);
  }
  return vec2 (dMin, df);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, roo, ltPos, ltDir, sCol;
  vec2 dBlock, s;
  float dstObj, f, spec, atten;
  for (int k = 0; k < 4; k ++) {
    f = 0.1 * float (k);
    pth[k] = vec4 (4. + f + (1.5 + f) * tCur + (0.8 - f) * sin ((0.1 + 0.1 * f) * tCur),
       sin ((0.11 + 0.1 * f) * tCur) + (0.3 + 0.2 * f) * sin ((0.17 + 0.5 * f) * tCur),
       5. + 2. * f + (1.3 - f) * tCur + (0.5 + 0.3 * f) * sin ((0.15 - 0.2 * f) * tCur),
       sin ((0.12 - 0.1 * f) * tCur) + (0.4 - 0.2 * f) * sin ((0.12 + 0.2 * f) * tCur));
  }
  illum = illumMin + (1. - illumMin) * smoothstep (0.3, 0.9, Fbm1 (4. * tCur));
  ltPos.y = 5.5;
  roo = ro;
  dBlock = BlkHit (ro - vec3 (0., bSize.y, 0.), rd, bSize);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dBlock.y) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == 1) {
      col = vec3 (0.9, 0.9, 0.6) * clamp (2. * (0.1 + 0.9 * illum) *
         (1. - 0.3 * Fbm1 (5. * qHit.z)) - 0.2, 0., 1.);
      col *= 0.2 + 1.2 * max (0.3 - dot (rd, vn), 0.);
    } else {
      if (idObj == 2) {
        col = vec3 (0.5, 0.3, 0.1);
      } else if (idObj == 3) {
        col = vec3 (0.6, 0.7, 0.8) * (0.8 + 0.2 * SmoothBump (0.1, 0.9, 0.05, mod (4. * qHit.y, 1.)));
        spec = 0.1;
      } else if (idObj == 4) {
        col = vec3 (0.2, 0.5, 0.1) * (1. - 0.2 * Fbm2 (8. * ro.xz));
        spec = 0.05;
      }
      sCol = vec3 (0.);
      for (float k = 0.; k < 4.; k ++) {
        ltPos.xz = Rot2D (vec2 (3., 0.), 0.5 * pi * (k + 0.5));
        ltDir = ltPos - ro;
        atten = 1.2 * step (0.02, -dot (rd, vn)) / (1. + 0.003 * pow (length (ltDir), 2.));
        ltDir = normalize (ltDir);
        sCol += atten * col * (0.5 + 0.5 * max (dot (vn, ltDir), 0.));
        if (idObj != 2) sCol += atten * spec * illum * pow (max (dot (reflect (ltDir, vn), rd), 0.), 32.);
        else sCol += atten * 0.5 * illum * pow (max (dot (vn, ltDir), 0.), 32.);
      }
      col = 0.25 * sCol * (0.1 + 0.9 * illum);
      if (illum < 0.1 && idObj == 2) col += vec3 (0., 0., 0.2) * (0.5 + 0.5 * Fbm1 (64. * tCur)) *
         (1. - smoothstep (0.05, 0.1, illum));
    }
  } else {
    vn = qnBlk[1];
    ro += rd * dBlock.y;
    if (abs (vn.y) > 0.1) {
      if (vn.y > 0.) {
        s = abs (mod (2. * ro.xz + 0.5, 1.) - 0.5);
        col =  mix (vec3 (0.3, 0.4, 0.3), vec3 (0.8, 0., 0.),
           SmoothBump (0.1, 0.2, 0.05, length (ro.xz) - 2.) +
           SmoothBump (0.1, 0.2, 0.05, length (abs (ro.xz) - 5.9) - 1.)) *
           (1. - 0.3 * smoothstep (0.4, 0.45, max (s.x, s.y))) * (1. - 0.2 * Fbm2 (4. * ro.xz));
      } else col = vec3 (0.3, 0.3, 0.1);
    } else {
      s = (abs (vn.x) > 0.1) ? ro.zy : ro.xy;
      col = vec3 (0.4, 0.4, 0.3) * (1. - 0.2 * Fbm2 (s));
      s = abs (mod (vec2 (0.5, 0.25) * s, 1.) - 0.5);
      col *= 1. - 0.3 * smoothstep (0.46, 0.48, max (s.x, s.y));
    }
    sCol = vec3 (0.);
    for (float k = 0.; k < 4.; k ++) {
      ltPos.xz = Rot2D (vec2 (3., 0.), 0.5 * pi * (k + 0.5));
      ltDir = ltPos - ro;
      atten = 1.2 / (1. + 0.003 * pow (length (ltDir), 2.));
      ltDir = normalize (ltDir);
      sCol += atten * (col * (0.1 + 0.9 * max (dot (vn, ltDir), 0.)));
    }
    col = 0.25 * sCol * (0.1 + 0.9 * illum);
    if (illum < 0.1) col += vec3 (0.1, 0.1, 0.4) * (0.5 + 0.5 * Fbm1 (64. * tCur)) *
       (1. - smoothstep (0.00005, 0.001, 1. - max (dot (normalize (vec3 (0., 6., 0.) - roo), rd), 0.))) *
       (1. - smoothstep (0.05, 0.1, illum));
  }
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
  //mPtr = mouse*resolution.xy;
  //mPtr.xy = mPtr.xy / canvas - 0.5;
  illumMin = 0.;
  if (canvas.x < 255.) illumMin = 0.4;
  bSize = vec3 (20., 10., 20.);
  az = 0.;
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.3 * pi * mPtr.y;
  } else {
    az += 0.03 * pi * tCur;
    el -= 0.05 * pi * sin (0.02 * pi * tCur);
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 1., -30.);
  ro.y = clamp (ro.y, 0.3, 2. * bSize.y - 0.3);
  rd = vuMat * normalize (vec3 (uv, 4.2));
  dstFar = 70.;
  glFragColor = vec4 (ShowScene (ro, rd), 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

const float cHashM = 43758.54;

vec2 Hashv2f (float p)
{
  return fract (sin (p + vec2 (0., 1.)) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
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

float Fbm2p (vec2 p)
{
  float f, a, s;
  f = 0.;
  s = 0.;
  a = 1.;
  for (int j = 0; j < 4; j ++) {
    f += a * Noisefv2 (p);
    s += a;
    a *= 1./2.5;
    p *= 2.5;
  }
  return f / s;
}
