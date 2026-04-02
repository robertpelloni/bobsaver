#version 420

// original https://www.shadertoy.com/view/wtyGRD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Snake Worship" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// (Mostly from "Multisegment Floppy Tube", "Parthenon 2" and "Woven Basket")

#define AA  1   // optional antialiasing

float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrRoundCylDf (vec3 p, float r, float rt, float h);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float SmoothBump (float lo, float hi, float w, float x);
float Noiseff (float p);
float Fbm2 (vec2 p);
float Fbm3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec4 hxHit;
vec3 qHit, fCylPos;
float tCur, dstFar, aMin, dLoop, aLoop, hLen, snbRad, fCylRad, fCylLen, flmFlkr;
int idObj;
const int idBask = 1, idEye = 2, idSnk = 3, idAltr = 4, idLogs = 5, idCoal = 6;
const float pi = 3.14159, sqrt3 = 1.73205;
const float nSeg = 2.;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }
#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float SnakeDf (vec3 p, float dMin)
{
  vec3 q;
  vec2 b, c;
  float d, lb;
  p.z = 0.6 * (abs (p.z) - 1.5);
  p.xy = Rot2D (p.xy, 0.5 * pi - 0.5 * aLoop);
  p.x -= - hLen + (dLoop + snbRad) * sin (0.5 * aLoop);
  p.xy = Rot2D (p.xy, 0.5 * pi - aLoop);
  q = p;
  q.z = abs (q.z);
  q -= vec3 (-0.5, -0.5, 0.5) * snbRad;
  d = PrSphDf (q, 0.3 * snbRad);
  DMIN (idEye);
  d = dMin;
  for (float k = 0.; k < nSeg; k ++) {
    q = p;
    q.xy = vec2 (- q.y, q.x);
    q.xy = Rot2D (vec2 (q.x, q.y - dLoop), aLoop - 0.5 * pi);
    b = vec2 (length (q.xy) - dLoop, q.z);
    lb = length (b);
    c = atan (vec2 (q.y, b.x), vec2 (- q.x, b.y)) * vec2 (4. * dLoop / pi, 1.) / pi;
    d = max (lb - snbRad, dot (vec2 (q.x, abs (q.y)), sin (aLoop + vec2 (0., 0.5 * pi))));
    if (k == 0.) d = min (d, PrSphDf (p, snbRad));
    p.xy = Rot2D (q.xy, aLoop) + vec2 (dLoop, 0.);
    p.x *= -1.;
    if (k == nSeg - 1.) d = min (d, PrSphDf (p, snbRad));
    if (d < dMin) hxHit = vec4 (c, lb, k);
    DMIN (idSnk);
  }
  return dMin;
}

float ObjDf (vec3 p)
{
  vec3 q, qq;
  vec2 cs;
  float dMin, d, szFac, rt, rc, h, s;
  dMin = dstFar;
  q = p;
  q.y -= 0.5;
  d = min (max (max (PrSphDf (q, 0.78), -0.01 + q.y), -0.3 - q.y),
     PrCylDf ((q - vec3 (0., -0.7, 0.)).xzy, 0.15, 0.42));
  DMINQ (idAltr);
  qq = p;
  qq.y -= fCylPos.y - fCylLen + 0.09;
  d = PrCylDf (qq.xzy, fCylRad, 0.1);
  if (d < 0.05) {
    cs = sin (pi * vec2 (1.3, 0.8));
    for (int j = 0; j < 5; j ++) {
      qq.xz = Rot2Cs (qq.xz, cs);
      q = qq;
      q.x += 0.21;
      d = PrRoundCylDf (q, 0.05 - 0.01 * sin (10. * pi * q.z), 0.02, 0.666);
      DMIN (idLogs);
    }
    q = p;
    q.y -= fCylPos.y - fCylLen - 0.02;
    d = PrCylDf (q.xzy, fCylRad- 0.03, 0.01);
    DMIN (idCoal);
  } else dMin = min (dMin, d);
  szFac = 0.2;
  dMin /= szFac;
  p /= szFac;
  p.xz = Rot2D (abs (p.xz) - 12., -0.25 * pi);
  qq = p;
  rt = 0.1;
  rc = 16. / pi;
  h = 2.;
  p.y -= -2.6 + h + 2. * rt;
  p.xz *= 1.1 - 0.1 * (p.y + h) / h;
  q = p;
  q.xz = vec2 (rc * atan (q.z, - q.x), length (q.xz) - rc);
  d = length (vec2 (abs (q.y) - h, q.z)) - 2. * rt;
  q.xy = mod (q.xy + 0.5, 1.) - 0.5;
  s = rt * cos (2. * pi * q.x);
  d = min (d, max (min (length (vec2 ((mod ((q.x - q.y) + 0.5, 1.) - 0.5) / sqrt (2.), q.z + s)),
     length (vec2 ((mod ((q.x + q.y) + 0.5, 1.) - 0.5) / sqrt (2.), q.z - s))) - rt, abs (p.y) - h));
  q = p;
  q.y -= - h;
  d = min (d, PrCylDf (q.xzy, rc, 2. * rt));
  DMIN (idBask);
  p = qq;
  dMin = SnakeDf (p, dMin);
  dMin *= szFac;
  return 0.8 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
    p = ro + dHit * rd;
    d = ObjDf (p);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.0002, -0.0002);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd, float dLight)
{
  float sh, d, h;
  sh = 1.;
  d = 0.1;
  for (int j = 0; j < 40; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += max (0.1, h);
    if (sh < 0.05 || d > dLight) break;
  }
  return 0.5 + 0.5 * sh;
}

vec2 CylHit (vec3 ro, vec3 rd, float cylRad, float cylHt)
{
  vec3 s;
  float dCylIn, dCylOut, a, ai, b, w, ws, srdy;
  dCylIn = dstFar;
  dCylOut = dstFar;
  a = dot (rd.xz, rd.xz);
  b = dot (rd.xz, ro.xz);
  w = b * b - a * (dot (ro.xz, ro.xz) - cylRad * cylRad);
  if (w > 0.) {
    ws = sqrt (w);
    srdy = sign (rd.y);
    if (a > 0.) {
      ai =  1. / a;
      dCylIn = (- b - ws) * ai;
      dCylOut = (- b + ws) * ai;
    }
    if (a > 0.) s = ro + dCylIn * rd;
    else s.y = cylHt;
    if (abs (s.y) > cylHt) {
      if (srdy * ro.y < - cylHt) {
        dCylIn = - (srdy * ro.y + cylHt) / abs (rd.y);
        if (length (ro.xz + dCylIn * rd.xz) > cylRad) dCylIn = dstFar;
      } else dCylIn = dstFar;
    }
    if (dCylIn < dstFar) {
      if (a > 0.) s = ro + dCylOut * rd;
      else s.y = cylHt;
      if (abs (s.y) > cylHt && srdy * ro.y < cylHt)
         dCylOut = (- srdy * ro.y + cylHt) / abs (rd.y);
    }
  }
  return vec2 (dCylIn, dCylOut);
}

float FlmAmp (vec3 ro, vec3 rd, vec2 dst)
{
  vec3 p, q;
  float fh, fr, aSum, a, d;
  const float ns = 24.;
  p = ro + dst.x * rd;
  d = dst.x + fCylRad / ns;
  aSum = 0.;
  for (float j = 0.; j < ns; j ++) {
    p = ro + d * rd;
    fr = 1. - length (p.xz) / fCylRad;
    fh = 0.5 * (1. - p.y / fCylLen);
    q = 2. * p;
    q.xz = Rot2D (q.xz, 0.3 * q.y);
    a = 1.1 * Fbm3 (q - vec3 (0., 4. * tCur, 0.));
    q = 5. * p;
    q.xz = Rot2D (q.xz, -0.4 * q.y);
    a += 0.9 * Fbm3 (q - vec3 (0., 5. * tCur, 0.));
    aSum += max (0.3 * fr * fr * fh * (a * a - 0.6), 0.);
    q = 73. * p;
    aSum += step (0.85, Fbm3 (q - vec3 (0., 16. * tCur, 0.))) * smoothstep (0.1, 0.2, fr) *
       smoothstep (0.3, 0.4, fh);
    d += fCylRad / ns;
    if (d > dst.y || aSum > 1.) break;
  }
  return clamp (aSum, 0., 1.);
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

float HexEdgeDist (vec2 p)
{
  p = abs (p);
  return (sqrt3/2.) - p.x + 0.5 * min (p.x - sqrt3 * p.y, 0.);
}

vec4 SnkCol ()
{
  vec4 col4;
  vec2 p, ip;
  float c, s, sx;
  sx = sign (hxHit.x);
  s = sign (2. * mod (hxHit.w, 2.) - 1.);
  if (hxHit.z < 0.3 * snbRad && hxHit.x < 0.) {
    col4 = vec4 (0., 0., 1., -1.);
  } else if (s * sx < 0. && abs (hxHit.y - 0.5 * sx) < 0.03 ||
     s * sx > 0. && abs (hxHit.y + 0.5 * sx) < 0.03) {
    col4 = vec4 (1., 0., 0., 0.2);
  } else {
    p = 4. * hxHit.xy * vec2 (3. * sqrt3, 3.);
    ip = PixToHex (p);
    c = mod (dot (mod (2. * ip + ip.yx, 3.), vec2 (1., 2.)), 3.);
    col4 = (c == 0.) ? vec4 (0.7, 0.6, 0., 0.2) : ((c == 1.) ? vec4 (0.8, 0.8, 0.4, 0.2) :
       vec4 (0.4, 0.2, 0., 0.2));
    col4 *= 0.3 + 0.7 * smoothstep (0.05, 0.07, HexEdgeDist (p - HexToPix (ip)));
  }
  return col4;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 vn, col, foVec;
  vec2 dstFlm;
  float dstObj, dstGrnd, tCyc, sLoop, sh, fIntens, f, lDist, grDep;
  int idObjF;
  grDep = 0.48;
  tCyc = 10.;
  aMin = 0.5;
  sLoop = aMin + 5. * pow (1. - SmoothBump (0.25, 0.75, 0.24, mod (tCur / tCyc, 1.)), 4.);
  aLoop = 0.25 * pi / sLoop;
  dLoop = 7. * 0.25 * pi * sLoop;
  hLen = 2. * nSeg * dLoop * sin (aLoop);
  snbRad = 0.25;
  fCylPos = vec3 (0., 2.53, 0.);
  fCylRad = 0.8;
  fCylLen = 2.;
  dstFlm = CylHit (ro - fCylPos, rd, fCylRad, fCylLen);
  fIntens = (dstFlm.x < dstFar) ? FlmAmp (ro - fCylPos, rd, dstFlm) : 0.;
  flmFlkr = Noiseff (tCur * 64.);
  dstObj = ObjRay (ro, rd);
  idObjF = idObj;
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == idBask) {
      col4 = vec4 (0.4, 0.2, 0., 0.);
      vn = VaryNf (16. * ro, vn, 2.);
    } else if (idObj == idEye) {
      col4 = vec4 (0., 1., 0., -1.);
    } else if (idObj == idSnk) {
      col4 = SnkCol ();
    } else if (idObj == idAltr) {
      col4 = vec4 (0.1, 0.4, 0.1, 0.2);
      if (qHit.y < -0.4) col4 = mix (col4, vec4 (0.5, 0., 0., -1.),
         SmoothBump (0.3, 0.6, 0.05, 0.5 + 0.5 * sin (2. * pi * (4. * qHit.y + 0.5 * tCur))));
    } else if (idObj == idLogs || idObj == idCoal) {
       f = clamp (1.2 * Fbm3 ((idObj == idLogs) ? 32. * vec3 (qHit.z,
          atan (qHit.y, - qHit.x) / (2. * pi), 2. * length (qHit.xy) - 0.03 * tCur) :
          vec3 (64. * qHit.xz, qHit.y + 0.5 * tCur).xzy) - 0.2, 0.1, 1.);
       col4.rgb = (idObj == idLogs) ? vec3 (1., 0.7 * f, 0.3 * f * f) * (0.5 +
          0.5 * max (- dot (rd, VaryNf (4. * qHit, vn, 1.)), 0.)) *
          (1. - 0.5 * smoothstep (0.5, 0.666, abs (qHit.z))) :
          f * vec3 (1., 0.2, 0.1) * (1. - 0.5 * pow (length (qHit.xz) / fCylRad, 4.));
       col4 = vec4 (min (3. * f * col4.rgb * (1. + 0.1 * flmFlkr), 1.), -1.);
    }
    if (col4.a >= 0.) {
      foVec = fCylPos - ro;
      lDist = length (foVec);
      foVec /= lDist;
      sh = ObjSShadow (ro, foVec, lDist);
      col = col4.rgb * (0.2 + sh * (0.3 + 0.7 * smoothstep (0., 0.05, - dot (rd, vn))) *
         max (dot (vn, foVec), 0.) * (0.25 + 5. * (0.6 + 0.4 * flmFlkr) *
         pow (lDist, -1.5) * vec3 (1., 0.3, 0.2)));
    } else col = col4.rgb * (0.5 + 0.5 * max (- dot (vn, rd), 0.));
  } else if (rd.y < 0.) {
    dstGrnd = - (ro.y + grDep) / rd.y;
    ro += dstGrnd * rd;
    foVec = fCylPos - ro;
    lDist = length (foVec);
    foVec /= lDist;
    sh = ObjSShadow (ro, foVec, lDist);
    col = sh * mix (vec3 (0.3, 0.4, 0.3), vec3 (0.4, 0.3, 0.3),
       smoothstep (0.3, 0.7, Fbm2 (8. * ro.xz))) * pow (lDist, -1.5);
  } else {
    col = vec3 (0.03);
  }
  if (! (dstObj < dstFar && idObjF == idAltr || dstObj < dstFlm.x))
     col = mix (col, mix (vec3 (1., 0.2, 0.2), vec3 (0.8, 0.6, 0.2),
        smoothstep (0.5, 0.8, fIntens)), fIntens);
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
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  el = -0.1 * pi;
  az = 0.25 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
  } else {
    az += 0.3 * pi * sin (0.02 * 2. * pi * tCur);
    el -= 0.3 * (az - 0.25 * pi) * (az - 0.25 * pi);
  }
  zmFac = 4.;
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 1., -16.);
  rd = vuMat * normalize (vec3 (uv, zmFac));
  dstFar = 100.;
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (pow (col, vec3 (0.8)), 1.);
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
  float dxy, dz;
  dxy = length (p.xy) - r;
  dz = abs (p.z) - h;
  return min (min (max (dxy + rt, dz), max (dxy, dz + rt)), length (vec2 (dxy, dz) + rt) - rt);
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
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
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

float Fbm2 (vec2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
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
  for (int i = 0; i < 5; i ++) {
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
  for (int i = 0; i < 3; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  vec2 e;
  e = vec2 (0.1, 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
