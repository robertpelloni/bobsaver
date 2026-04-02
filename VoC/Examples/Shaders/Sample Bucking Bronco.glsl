#version 420

// original https://www.shadertoy.com/view/ftK3Rt

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Bucking Bronco" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  0   // (= 0/1) optional antialiasing

#if 0
#define VAR_ZERO min (frames, 0)
#else
#define VAR_ZERO 0
#endif

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrTorusBxDf (vec3 p, vec3 b, float ri);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrRoundCylDf (vec3 p, float r, float rt, float h);
vec3 HsvToRgb (vec3 c);
float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float Fbm1 (float p);
float Fbm2 (vec2 p);

vec3 ltPos[3], ltCol[3], pUp, qHit;
vec2 aRotCs[3];
float tCur, dstFar, movFac, platRad[2];
int idObj;
const int idTube = 1, idBall = 2, idBase = 3, idLeg = 4, idPlat = 5, idSeat = 6, idGrip = 7; 
const float pi = 3.1415927;

struct TbCon {
  vec3 pLo, pHi;
  vec2 aLimCs, tRotCs[2], pRotCs[2];
  float chLen, chDist, ang, rad;
};
TbCon tbCon[4];

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

#define F(x) (sin (x) / x - b)

float SecSolve (float b)
{  // (from "Robotic Head")
  vec3 t;
  vec2 f;
  float x;
  if (b < 0.95) {
    t.yz = vec2 (0.7, 1.2);
    f = vec2 (F(t.y), F(t.z));
    for (int nIt = 0; nIt < 4; nIt ++) {
      t.x = (t.z * f.x - t.y * f.y) / (f.x - f.y);
      t.zy = t.yx;
      f = vec2 (F(t.x), f.x);
    }
    x = t.x;
  } else if (b < 1.) {
    x = sqrt (10. * (1. - sqrt (1. - 1.2 * (1. - b))));
  } else {
    x = 0.;
  }
  return x;
}

void SetConf ()
{
  vec3 vp;
  float tubeLen, t, h, rm, a[3];
  movFac = SmoothBump (0.15, 0.85, 0.07, mod (0.05 * tCur, 1.));
  t = 1.5 * tCur;
  platRad[0] = 3.3;
  platRad[1] = 1.;
  rm = 0.55 * (platRad[1] - platRad[0]);
  h = 0.1 + movFac * 0.9 * (1.2 + 0.6 * sin (2.3 * t));
  tubeLen = length (vec2 (platRad[1] - platRad[0], 2.));
  pUp.xz = movFac * Rot2D (vec2 (rm, 0.), t + 0.5 * (Fbm1 (t) - 0.5));
  pUp.y = h;
  a[0] = movFac * 0.1 * pi * sin (2.7 * t);
  a[1] = movFac * 0.1 * pi * sin (2.9 * t);
  a[2] = movFac * pi * (Fbm1 (0.5 * t) - 0.5) + 0.25 * pi;
  aRotCs[0] = sin (a[0] + vec2 (0.5 * pi, 0.));
  aRotCs[1] = sin (a[1] + vec2 (0.5 * pi, 0.));
  aRotCs[2] = sin (a[2] + vec2 (0.5 * pi, 0.));
  for (int k = 0; k < 4; k ++) {
    tbCon[k].pLo = vec3 (Rot2D (vec2 (platRad[0] + 0.11, 0.), float (k) * 0.5 * pi), - h).xzy;
    tbCon[k].pHi = vec3 (Rot2D (vec2 (platRad[1] + 0.11, 0.), float (k) * 0.5 * pi) + pUp.xz,
       pUp.y).xzy;
    tbCon[k].pHi.xy = Rot2D (tbCon[k].pHi.xy, - a[0]);
    tbCon[k].pHi.zy = Rot2D (tbCon[k].pHi.zy, - a[1]);
    vp = tbCon[k].pHi - tbCon[k].pLo;
    tbCon[k].pLo.y += h;
    tbCon[k].pHi.y += pUp.y;
    tbCon[k].chLen = 0.5 * length (vp);
    tbCon[k].tRotCs[0] = sin (atan (vp.x, vp.z) + vec2 (0.5 * pi, 0.));
    tbCon[k].tRotCs[1] = sin (- asin (length (vp.xz) / length (vp)) + vec2 (0.5 * pi, 0.));
    tbCon[k].ang = SecSolve (tbCon[k].chLen / tubeLen);
    tbCon[k].chDist = tbCon[k].chLen / tan (tbCon[k].ang);
    tbCon[k].rad = length (vec2 (tbCon[k].chDist, tbCon[k].chLen));
    tbCon[k].aLimCs = sin (- tbCon[k].ang + vec2 (0.5 * pi, 0.));
  }
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, a;
  dMin = dstFar;
  p.y -= 0.36;
  q = p;
  q.y -= -0.05;
  d = PrRoundCylDf (q.xzy, platRad[0] + 0.03, 0.02, 0.04);
  DMINQ (idBase);
  q.y -= -0.22;
  q.xz = abs (q.xz) - 0.63 * platRad[0];
  d = PrCylDf (q.xzy, 0.1 * platRad[0], 0.15);
  DMINQ (idLeg);
  for (int k = 0; k < 4; k ++) {
    d = PrSphDf (p - tbCon[k].pLo, 0.1);
    DMINQ (idBall);
  }
  q = p;
  q.y -= pUp.y;
  q.xy = Rot2Cs (q.xy, aRotCs[0]);
  q.zy = Rot2Cs (q.zy, aRotCs[1]);
  q -= pUp;
  q.y -= -0.1;
  d = PrRoundCylDf (q.xzy, platRad[1] + 0.07, 0.02, 0.04);
  DMINQ (idPlat);
  q.y -= 0.3;
  d = PrCylDf (q.xzy, 0.15, 0.25);
  DMINQ (idSeat);
  q.y -= 0.33;
  q.xz = Rot2Cs (q.xz, aRotCs[2]);
  d = PrRoundBoxDf (q, vec3 (0.4, 0.15, 0.08), 0.1);
  DMINQ (idSeat);
  q.xy -= vec2 (0.3, 0.25);
  d = PrTorusBxDf (q.yzx, vec3 (0.25, 0.12, 0.08), 0.03);
  DMINQ (idGrip);
  for (int k = 0; k < 4; k ++) {
    d = PrSphDf (p - tbCon[k].pHi, 0.1);
    DMINQ (idBall);
  }
  for (int k = 0; k < 4; k ++) {
    q = p - tbCon[k].pLo;
    q.xz = Rot2Cs (q.xz, tbCon[k].tRotCs[0]);
    q.yz = Rot2Cs (q.yz, tbCon[k].tRotCs[1]) - vec2 (tbCon[k].chLen, tbCon[k].chDist);
    a = fract ((128. / tbCon[k].ang) * atan (q.y, - q.z) / (2. * pi));
    d = max (dot (vec2 (abs (q.y), - q.z), tbCon[k].aLimCs), length (vec2 (length (q.yz) -
       tbCon[k].rad, q.x)) - (0.08 - 0.012 * smoothstep (0.15, 0.35, 0.5 - abs (0.5 - a))));
    DMINQ (idTube);
  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    p = ro + dHit * rd;
    d = ObjDf (p);
    if (d < 0.001 || dHit > dstFar || p.y < 0.) break;
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
    d += h;
    if (sh < 0.001 || d > dMax) break;
  }
  return 0.3 + 0.7 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, ltDir, ltAx, c;
  vec2 u;
  float dstObj, nDotL, sh, att, ltDst, a, r;
  bool isMet;
  SetConf ();
  dstObj = ObjRay (ro, rd);
  col = vec3 (0.);
  isMet = false;
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == idTube) {
      col4 = vec4 (0.8, 0.8, 0.9, 0.3);
      isMet = true;
    } else if (idObj == idBall) {
      col4 = vec4 (0.9, 0.7, 0.4, 0.3);
      isMet = true;
    } else if (idObj == idBase) {
      r = length (qHit.xz);
      col4 = vec4 (0.5, 0.6, 0.4, 0.1) * (0.85 + 0.15 * smoothstep (0., 0.05,
         abs (r - 1.1 * platRad[1])));
      u = Rot2D (qHit.xz, pi / 16.);
      a = (r > 0.) ? atan (u.y, - u.x) / (2. * pi) : 0.;
      u = Rot2D (u, 2. * pi * (floor (16. * a + 0.5) / 16.));
      if (length (u + vec2 (platRad[0] - 0.3, 0.)) < 0.15) col4 = vec4 (((movFac > 0.2) ?
         HsvToRgb (vec3 (mod (a + 0.5 * pi * tCur, 1.), 1., 1.)) :
         vec3 (1., 1., 0.) * (0.8 + 0.2 * sin (16. * pi * tCur))), -1.);
    } else if (idObj == idLeg) {
      col4 = vec4 (0.5, 0.6, 0.4, 0.1);
    } else if (idObj == idPlat) {
      col4 = vec4 (0.6, 0.5, 0.7, 0.2);
      r = length (qHit.xz);
      u = Rot2D (qHit.xz, pi / 8.);
      a = (r > 0.) ? atan (u.y, - u.x) / (2. * pi) : 0.;
      u = Rot2D (u, 2. * pi * (floor (8. * a + 0.5) / 8.));
      if (length (u + vec2 (platRad[1] - 0.15, 0.)) < 0.1)
         col4 = vec4 (((movFac > 0.) ? vec3 (1., 0., 0.) : vec3 (0., 1., 0.)), -1.);
    } else if (idObj == idSeat) {
      col4 = vec4 (0.7, 0.5, 0.1, 0.2);
    } else if (idObj == idGrip) {
      col4 = vec4 (1., 0.5, 0.5, 0.2);
      isMet = true;
    }
  } else if (rd.y < 0.) {
    dstObj = - ro.y / rd.y;
    ro += dstObj * rd;
    vn = vec3 (0., 1., 0.);
    u = ro.xz;
    col4 = vec4 (0.6, 0.5, 0.5, 0.1) * (1. - 0.2 * Fbm2 (4. * u));
    u = abs (fract (u + 0.5) - 0.5);
    col4.rgb *= (1. - 0.15 * smoothstep (0.05, 0.08,
       abs (max (abs (u.x + u.y), abs (u.x - u.y)) - 0.2) - 0.2)) *
       (1. - 0.15 * smoothstep (0.05, 0.08, length (max (u - 0.42, 0.))));
  }
  if (dstObj < dstFar) {
    if (col4.a >= 0.) {
      for (int k = VAR_ZERO; k < 3; k ++) {
        ltDir = ltPos[k] - ro;
        ltDst = length (ltDir);
        ltDir /= ltDst;
        ltAx = normalize (ltPos[k] - vec3 (0., 2., 0.));
        att = smoothstep (0., 0.02, dot (ltDir, ltAx) - 0.97);
        sh = (dstObj < dstFar) ? ObjSShadow (ro + 0.01 * vn, ltDir, ltDst) : 1.;
        nDotL = max (dot (vn, ltDir), 0.);
        if (isMet) nDotL *= nDotL * nDotL;
        c = att * ltCol[k] * (col4.rgb * (0.1 + 0.9 * sh * nDotL) +
           col4.a * step (0.95, sh) * pow (max (dot (ltDir, reflect (rd, vn)), 0.), 32.));
        col += c * c;
      }
      col = sqrt (col);
    } else col = col4.rgb * (0.5 + 0.5 * max (0., - dot (vn, rd)));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.2 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az += 0.03 * pi * tCur;
    el += 0.08 * pi * cos (0.02 * pi * tCur);
  }
  el = clamp (el, -0.4 * pi, -0.01 * pi);
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 1.5, -20.);
  for (int k = VAR_ZERO; k < 3; k ++) {
    ltPos[k] = vec3 (0., 30., 0.);
    ltPos[k].xy = Rot2D (ltPos[k].xy, 0.25 * pi * (1. + 0.2 * sin (0.05 * pi * tCur -
       pi * float (k) / 3.)));
    ltPos[k].xz = Rot2D (ltPos[k].xz, -0.1 * pi * tCur + 2. * pi * float (k) / 3.);
  }
  ltCol[0] = vec3 (1., 0.2, 0.2);
  ltCol[1] = ltCol[0].gbr;
  ltCol[2] = ltCol[0].brg;
  zmFac = 4.2;
  dstFar = 60.;
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

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrTorusBxDf (vec3 p, vec3 b, float ri)
{
  return length (vec2 (length (max (abs (p.xy) - b.xy, 0.)) - b.z, p.z)) - ri;
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrRoundCylDf (vec3 p, float r, float rt, float h)
{
  return length (max (vec2 (length (p.xy) - r, abs (p.z) - h), 0.)) - rt;
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. -
     3.) - 1., 0., 1.), c.y);
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

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
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
