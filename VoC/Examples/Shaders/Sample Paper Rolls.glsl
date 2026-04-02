#version 420

// original https://www.shadertoy.com/view/WlKSRd

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Paper Rolls"  by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1  // optional antialiasing

float PrCylDf (vec3 p, float r, float h);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
float Minv3 (vec3 p);
float SmoothMin (float a, float b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Hashv2v2 (vec2 p);
float Fbm2 (vec2 p);

vec3 ltDir, qHit;
vec2 gId, trkF, trkA;
float tCur, dstFar, hgSize, wavHt, nCylV, nCylH, cylHt, cylRd, cylHo, emFrac;
int idObj;
bool isOcc;
const float pi = 3.14159, sqrt3 = 1.7320508;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, a;
  dMin = dstFar;
  p.xz -= HexToPix (gId * hgSize);
  a = atan (p.z, - p.x) / (2. * pi);
  q = p;
  q.xz = Rot2D (q.xz, 2. * pi * (floor (6. * a + 0.5)) / 6.);
  d = max (abs (q.x) - 0.85 * hgSize, q.y - wavHt + 0.05 * dot (q.xz, q.xz));
  DMINQ (1);
  if (isOcc) {
    p.y -= wavHt - 0.03;
    q = p;
    q.xz = Rot2D (q.xz, 2. * pi * (floor (nCylH * a + 0.5)) / nCylH);
    if (nCylH > 1.) q.x = abs (q.x) - 0.8;
    q.y -= cylHt * nCylV;
    d = max (PrCylDf (q.xzy, cylRd, cylHt * nCylV), cylHo - length (q.xz));
    DMINQ (2);
  }
  return dMin;
}

void SetGrObjConf ()
{
  vec2 p, u, fRand;
  p = HexToPix (gId * hgSize);
  u = mod (0.1 * vec2 (p.x + p.y, p.x - p.y) * (1. + 0.3 * sin (0.2 * 2. * pi * p)) +
    0.1 * tCur, 1.) - 0.5;
  wavHt = 0.6 * dot (exp (-100. * u * u), vec2 (1.));
  fRand = Hashv2v2 (gId * vec2 (37.3, 43.1) + 27.1);
  isOcc = (fRand.y >= emFrac);
  if (isOcc) {
    nCylV = 1. + floor (4. * fRand.x);
    nCylH = 1. + floor (6. * fRand.y);
  }
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM, gIdP;
  float dHit, d, s, eps;
  eps = 0.0005;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSize / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]),
     dot (ro.xz, edN[2])) / hgSize;
  pM = HexToPix (PixToHex (ro.xz / hgSize));
  gIdP = vec2 (-99.);
  dHit = 0.;
  for (int j = 0; j < 160; j ++) {
    hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
    s = Minv3 (hv);
    p = ro + dHit * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId != gIdP) {
      gIdP = gId;
      SetGrObjConf ();
    }
    d = ObjDf (p);
    if (dHit + d < s) {
      dHit += d;
    } else {
      dHit = s + eps;
      pM += sqrt3 * ((s == hv.x) ? edN[0] : ((s == hv.y) ? edN[1] : edN[2]));
    }
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
  for (int j = 0; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 gIdP;
  float sh, d, h;
  sh = 1.;
  gIdP = vec2 (-99.);
  d = 0.01;
  for (int j = 0; j < 30; j ++) {
    p = ro + d * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId != gIdP) {
      gIdP = gId;
      SetGrObjConf ();
    }
    h = ObjDf (p);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += clamp (h, 0.05, 0.3);
    if (sh < 0.05) break;
  }
  return 0.6 + 0.4 * sh;
}

float ObjAO (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 gIdP;
  float ao, d;
  ao = 0.;
  gIdP = vec2 (-99.);
  for (int j = 0; j < 4; j ++) {
    d = 0.01 + float (j) / 20.;
    p = ro + d * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId != gIdP) {
      gIdP = gId;
      SetGrObjConf ();
    }
    ao += max (0., d - 3. * ObjDf (p));
  }
  return 0.6 + 0.4 * clamp (1. - 2. * ao, 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, bgCol, vn;
  float dstObj, sh, ao;
  bgCol = vec3 (0.5, 0.4, 0.4);
  emFrac = 0.05;
  cylHt = 0.3;
  cylRd = 0.3;
  cylHo = 0.12;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == 1) {
      if (vn.y > 0.01) col = mix (vec3 (0.65, 0.65, 0.7), vec3 (0.6, 0.6, 0.55),
         smoothstep (0.4, 0.6, Fbm2 (ro.xz)));
      else col = vec3 (0.95, 0.95, 1.) * (0.85 + 0.15 * cos (9. * 2. * pi * qHit.z / hgSize));
    } else if (idObj == 2) {
      if (length (qHit.xz) < cylHo + 0.01) col = vec3 (0.6, 0.4, 0.);
      else col = mix (vec3 (1., 0.8, 0.9), vec3 (1.3),
         smoothstep (0.02, 0.05, abs (mod (qHit.y / (2. * cylHt) + 0.5 * (nCylV + 1.), 1.) - 0.5)));
    }
    ao = ObjAO (ro, vn);
    sh = min (ObjSShadow (ro, ltDir), ao);
    col *= ao * (0.3 + 0.2 * max (dot (vn, ltDir * vec3 (-1., 1., -1.)), 0.)) +
       0.7 * sh * max (dot (vn, ltDir), 0.);
    col = mix (col, bgCol, smoothstep (0.5, 1., dstObj / dstFar));
  } else col = (0.1 + 0.9 * step (-0.1, rd.y)) * bgCol;
  return clamp (col, 0., 1.);
}

vec3 TrackPath (float t)
{
  return vec3 (dot (trkA, sin (trkF * t)), dot (trkA.yx, cos (trkF * t)), t);
}

vec3 TrackVel (float t)
{
  return vec3 (dot (trkF * trkA, cos (trkF * t)),
     dot (trkF * trkA.yx, - sin (trkF * t)), 1.);
}

vec3 TrackAcc (float t)
{
  return vec3 (dot (trkF * trkF * trkA, - sin (trkF * t)),
     dot (trkF * trkF * trkA.yx, - cos (trkF * t)), 0.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec4 dateCur;
  vec3 ro, rd, vd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr, vFly;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  dateCur = date;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tCur = mod (tCur, 2400.) + 30. * floor (dateCur.w / 7200.) + 11.1;
  hgSize = 1.6;
  az = 0.;
  el = -0.15 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.3 * pi * mPtr.y;
  }
  el = clamp (el, -0.2 * pi, -0.05 * pi);
  trkF = vec2 (0.1, 0.17);
  trkA = vec2 (1.25, 0.45);
  vuMat = StdVuMat (el, az);
  vFly = 2.;
  ro = TrackPath (vFly * tCur);
  ro.y += 5.;
  vd = normalize (TrackVel (vFly * tCur));
  vuMat = StdVuMat (el + 0.5 * sin (vd.y), az + 2. * atan (vd.x, vd.z));
  zmFac = 2.2;
  dstFar = 120.;
  ltDir = normalize (vec3 (0., 1.5, -1.));
  ltDir.xz = Rot2D (ltDir.xz, 0.3 * pi * sin (0.05 * pi * tCur));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    rd = vuMat * rd;
    rd.xy = Rot2D (rd.xy, -10. * TrackAcc (vFly * tCur).x);
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

vec2 PixToHex (vec2 p)
{
  vec3 c, r, dr;
  c.xz = vec2 ((1./sqrt3) * p.x - (1./3.) * p.y, (2./3.) * p.y);
  c.y = - c.x - c.z;
  r = floor (c + 0.5);
  dr = abs (r - c);
  r -= step (dr.yzx, dr) * step (dr.zxy, dr) * dot (r, vec3 (1.));
  return r.xz;
}

vec2 HexToPix (vec2 h)
{
  return vec2 (sqrt3 * (h.x + 0.5 * h.y), (3./2.) * h.y);
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

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
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
