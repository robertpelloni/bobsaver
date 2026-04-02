#version 420

// original https://www.shadertoy.com/view/4s2czR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Ultimate Library" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrSphDf (vec3 p, float s);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
float PrTorusDf (vec3 p, float ri, float rc);
vec2 HexCellId (vec2 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
vec3 HsvToRgb (vec3 c);
float ShowInt (vec2 q, vec2 cBox, float mxChar, float val);

const float pi = 3.14159;
const float sqrt3 = 1.73205;

vec3 ltDir, lbPos;
vec2 idCell, szGr, bsa1, bsa2;
float dstFar, tCur, rdRm, htRm, wlThk, rdHol, spShf, htShf;
int idObj;
const int idRm = 1, idRal = 2, idBks = 3, idShlf = 4, idLt = 5, idBl = 6;

float ObjDf (vec3 p)
{
  vec3 q, qq;
  float d, dMin, r, a, dWid, wdShf;
  dMin = dstFar;
  dWid = 0.15 * szGr.x;
  wdShf = 0.06 * rdRm;
  q = p;
  idCell = HexCellId (q.xz / szGr.x);
  q.xz -= vec2 (2. * idCell.x + idCell.y, sqrt3 * idCell.y) * szGr.x;
  r = length (q.xz);
  a = (r > 0.) ? atan (q.z, - q.x) / (2. * pi) : 0.;
  q.y = mod (q.y + szGr.y, 2. * szGr.y) - szGr.y;
  qq = q;
  q.xz = Rot2D (q.xz, 2. * pi * ((floor (6. * a + 0.5)) / 6.));
  d = max (PrCylAnDf (q.xzy, rdRm, wlThk, htRm), dWid - abs (q.z));
  d = min (d, max (htRm - abs (q.y), rdHol - 0.05 - r));
  if (d < dMin) {dMin = d;  idObj = idRm; }
  q = qq;  q.y -= - htRm + 0.6 * htRm;
  d = PrTorusDf (q.xzy, 0.06, rdHol);
  q = qq;  q.y -= - htRm + 0.3 * htRm;
  q.y = abs (abs (q.y) - 0.1 * htRm);
  d = min (d, PrTorusDf (q.xzy, 0.04, rdHol));
  q = qq;  q.y -= - htRm + 0.3 * htRm;
  q.xz = Rot2D (q.xz, 2. * pi * ((floor (18. * a) + 0.5) / 18.));
  q.x += rdHol;
  d = min (d, PrCylDf (q.xzy, 0.04, 0.3 * htRm));
  if (d < dMin) { dMin = d;  idObj = idRal; }
  q = qq;
  q.xz = Rot2D (q.xz, 2. * pi * ((floor (6. * a) + 0.5) / 6.));
  q.z = abs (q.z);
  d = max (abs (r - rdRm + wlThk + 1. * wdShf) - 0.5 * wdShf, dot (q.xz, bsa2));
  d = max (d, abs (q.y) - htRm);
  if (d < dMin) {dMin = d;  idObj = idBks; }
  d = max (abs (r - rdRm + wlThk + wdShf) - wdShf, dot (q.xz, bsa1));
  d = max (d, min (abs (mod (q.y + 0.5 * spShf, spShf) - 0.5 * spShf) - htShf,
     - dot (q.xz, bsa2)));
  d = max (d, abs (q.y) - htRm);
  if (d < dMin) {dMin = d;  idObj = idShlf; }
  q.z = abs (q.z);
  q -= vec3 (- 0.7 * rdRm, htRm - 0.04, 0.8);
  d = PrCylDf (q.xzy, 0.3, 0.03);
  if (d < dMin) {dMin = d;  idObj = idLt; }
  d = PrSphDf (p - lbPos, 0.4);
  if (d < dMin) { dMin = d;  idObj = idBl; }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 200; j ++) {
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

vec3 WoodCol (vec3 p, vec3 n)
{
  float f;
  p *= 4.;
  f = dot (vec3 (Fbm2 (p.zy * vec2 (1., 0.1)),
     Fbm2 (p.zx * vec2 (1., 0.1)), Fbm2 (p.xy * vec2 (1., 0.1))), abs (n));
  return 0.8 * mix (vec3 (0.9, 0.5, 0.3), vec3 (0.55, 0.35, 0.1), f);
}

float GlowCol (vec3 ro, vec3 rd, float dstHit)
{
  vec3 ld;
  float d, wGlow;
  wGlow = 0.;
  ld = lbPos - ro;
  d = length (ld);
  ld /= d;
  if (d < dstHit) wGlow += pow (max (dot (rd, ld), 0.), 1024.);
  return clamp (0.5 * wGlow, 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 roo, col, vn, q, ld, bgCol;
  vec2 gbRm, gbBk, g, bt;
  float dstObj, r, a, bh, s, cRm, idFlr, lbCol, fr, spec;
  bool isLit;
  wlThk = 0.04 * szGr.x;
  rdRm = szGr.x - 0.7 * wlThk;
  rdHol = 0.5 * rdRm;
  htRm = 0.93 * szGr.y;
  spShf = htRm / 3.;
  htShf = 0.05 * spShf;
  bsa1 = vec2 (sin (1.2 * 2. * pi / 24.), cos (1.2 * 2. * pi / 24.));
  bsa2 = vec2 (sin (1.16 * 2. * pi / 24.), cos (1.16 * 2. * pi / 24.));
  roo = ro;
  dstObj = ObjRay (ro, rd);
  isLit = true;
  bgCol = (abs (rd.y) < 0.5) ? 0.5 * vec3 (0.7, 0.5, 0.) : ((rd.y > 0.) ?
     vec3 (0.5, 0.5, 0.55) : vec3 (0., 0., 0.2));
  if (dstObj < dstFar) {
    ro += rd * dstObj;
    q = ro;
    q.xz -= vec2 (2. * idCell.x + idCell.y, sqrt3 * idCell.y) * szGr.x;
    r = length (q.xz);
    a = (r > 0.) ? atan (q.z, - q.x) / (2. * pi) : 0.;
    idFlr = floor (q.y / (2. * szGr.y) + 0.5);
    gbRm = idCell + idFlr;
    cRm = Noisefv2 (gbRm * vec2 (17., 11.));
    q.y = mod (q.y + szGr.y, 2. * szGr.y) - szGr.y;
    vn = ObjNf (ro);
    spec = 0.1;
    if (idObj == idRm) {
      if (r < rdHol + 0.05) col = vec3 (0.6, 0.6, 0.7);
      else if (vn.y < -0.99 && r < 0.99 * rdRm) col = vec3 (1.);
      else if (r >= 0.99 * rdRm && vn.y <= 0.99) {
        col = HsvToRgb (vec3 (Noisefv2 (vec2 (33. * idFlr + 1., 1.)), 0.4, 0.8));
        if (abs (vn.y) < 0.01) col *= 0.6 + 0.3 * q.y / htRm;
        isLit = false;
      } else if (r > 0.99 * (rdRm - wlThk) ||
          r >= 0.99 * rdRm && vn.y > 0.99) col = vec3 (0.7, 0.5, 0.);
      else {
        fr = (r - rdHol) / (rdRm - rdHol);
        col = mix (vec3 (0.7), HsvToRgb (vec3 (cRm, 1., 1.)),
           SmoothBump (0.1, 0.3, 0.05, mod (7. * fr, 1.))) * 
           (0.5 + 0.5 * smoothstep (0.1, 0.3, abs (0.5 - mod (6. * a - 0.5, 1.))) *
           smoothstep (0.3, 0.6, fr));
        g = vec2 (5. * (mod (6. * mod (a + 1./12., 1.), 1.) - 0.5), r - 0.835 * rdRm);
        if (length (max (abs (g) - vec2 (0.5, 0.15), 0.)) < 0.1) {
          col = vec3 (0.8);
          if (ShowInt (vec2 (g.x - 0.5, g.y + 0.13),
             vec2 (1., 0.25), 4., dot (mod (vec2 (42., 24.) + idCell, 100.),
             vec2 (100., 1.))) != 0.) {
            col = vec3 (0.1);
            isLit = false;
          }
        }
        g.y = r - 1.1 * rdHol;
        if (length (max (abs (g) - vec2 (0.5, 0.15), 0.)) < 0.1) {
          col = vec3 (0.8);
          if (ShowInt (vec2 (g.x - 0.5, g.y + 0.12), vec2 (1., 0.25), 4.,
             2048. + idFlr) != 0.) {
            col = vec3 (0.1);
            isLit = false;
          }
        }
      }
    } else if (idObj == idRal) {
      col = vec3 (1.2, 1.2, 1.);
      spec = 0.5;
    } else if (idObj == idBks) {
      bt = vec2 (5000. * a, 200. * q.y);
      a = 52. * mod (6. * a + 0.5, 1.);
      gbBk = floor (vec2 (q.y / spShf, a));
      bh = (0.7 + 0.3 * Fbm2 ((gbRm + gbBk) * vec2 (19., 31.))) * spShf;
      q.y = mod (q.y, spShf);
      if (q.y < bh) {
        q.xy = vec2 (2. * mod (a, 1.) - 1., q.y / bh - 0.5);
        col = vec3 (HsvToRgb (vec3 (mod (cRm +
           0.5 * (Fbm2 (gbBk * vec2 (17., 11.)) - 0.5), 1.), 1.,
           SmoothBump (0.08, 0.92, 0.01, 0.55 + 0.45 * q.x))));
        if (abs (abs (q.y) - 0.35) < 0.01 || abs (q.x) < 0.3 && abs (q.y) < 0.2 &&
           Noisefv2 ((gbRm + gbBk) * vec2 (19., 31.) + floor (bt)) > 0.7) {
          col *= 1.6;
        } else {
          spec = 0.3;
          vn.xz = Rot2D (vn.xz, q.x);
        }
      } else {
        col = vec3 (0.02);
        isLit = false;
      }
    } else if (idObj == idShlf) {
      q = vec3 (5. * (mod (6. * a, 1.) - 0.5), ro.y, r);
      col = WoodCol (q, vn);
    } else if (idObj == idLt) {
      col = vec3 (1., 1., 0.7) * (0.5 - 0.5 * vn.y);
      isLit = false;
    } else if (idObj == idBl) {
      col = (0.75 + 0.25 * dot (rd, normalize (lbPos - ro))) *
         HsvToRgb (vec3 (0.14 + 0.02 * sin (4. * tCur), 1., 1.));
      isLit = false;
    }
    if (idObj != idBl) {
      ld = lbPos - ro;
      s = length (ld);
      ld /= s;
      lbCol = 2. * clamp (dot (vn, ld), 0., 1.) / (1. + s * s);
    }
    if (isLit) col = col * (0.2 + 2. * lbCol +
       0.5 * max (0., max (dot (vn, ltDir), 0.)) +
       spec * pow (max (0., dot (ltDir, reflect (rd, vn))), 16.));
  } else col = bgCol;
  col = mix (col, vec3 (1., 1., 0.5), GlowCol (roo, rd, dstObj));
  col = mix (col, bgCol, smoothstep (0.6, 1., min (dstObj / dstFar, 1.)));
  col = clamp (col, 0., 1.);
  return col;
}

vec3 TrackPath (float t)
{
  vec3 p;
  vec2 tp[7], td[6];
  float dir, tc, tm;
  tc = floor (t / 27.);
  tm = mod (t, 27.);
  p.y = 0.1 + 0.2 * sin (0.6 * t) + 2. * tc;
  td[0] = vec2 (1., 0.);
  tp[0] = vec2 (-0.5 + 2. * tc + step (13., tm), -0.5 * sqrt3);
  if (tm < 26.) {
    dir = -1. + 2. * step (13., tm);
    tm = mod (tm, 13.);
    if (tm < 12.) {
      dir *= -1. + 2. * step (6., tm);
      tm = mod (tm, 6.);
      td[1] = vec2 (0.5, 0.5 * sqrt3 * dir);
      td[2] = vec2 (-0.5, 0.5 * sqrt3 * dir);
      td[3] = - td[0];
      td[4] = - td[1];
      td[5] = - td[2];
      for (int k = 0; k < 6; k ++) tp[k + 1] = tp[k] + td[k];
      if (tm < 1.)      p.xz = tp[0] + td[0] * tm;
      else if (tm < 2.) p.xz = tp[1] + td[1] * (tm - 1.); 
      else if (tm < 3.) p.xz = tp[2] + td[2] * (tm - 2.); 
      else if (tm < 4.) p.xz = tp[3] + td[3] * (tm - 3.); 
      else if (tm < 5.) p.xz = tp[4] + td[4] * (tm - 4.); 
      else if (tm < 6.) p.xz = tp[5] + td[5] * (tm - 5.); 
    } else {
      p.xz = tp[0] + td[0] * (tm - 12.);
    }
  } else {
    p.xz = tp[0] + td[0];
    p.y += 2. * (tm - 26.);
  }
  p.xz *= 4. * szGr.x;
  p.y *= szGr.y;
  return p;
}

void main(void)
{
  mat3 vuMat;
  vec2 mPtr;
  vec3 ro, rd, fpF, fpB, vd;
  vec2 uv, ori, ca, sa;
  float el, az, spd;
  uv = 2. * gl_FragCoord.xy / resolution.xy - 1.;
  uv.x *= resolution.x / resolution.y;
  tCur = time;
  mPtr = mouse.xy*resolution.xy;
  mPtr.xy = mPtr.xy / resolution.xy - 0.5;
  az = 0.;
  el = 0.;
  //if (mPtr.z > 0.) {
  //  az = az + 2. * pi * mPtr.x;
  //  el = el + 0.95 * pi * mPtr.y;
  //}
  szGr = vec2 (10., 3.3);
  spd = 0.12;
  lbPos = 0.5 * (TrackPath (spd * tCur + 0.4) + TrackPath (spd * tCur + 0.6));
  fpF = TrackPath (spd * tCur + 0.1);
  fpB = TrackPath (spd * tCur - 0.1);
  ro = 0.5 * (fpF + fpB);
  vd = fpF - fpB;
  ori = vec2 (el, az + ((length (vd.xz) > 0.) ? atan (vd.x, vd.z) : 0.5 * pi));
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = vuMat * normalize (vec3 (uv, 1.6));
  dstFar = 300.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
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

float PrTorusDf (vec3 p, float ri, float rc)
{
  return length (vec2 (length (p.xy) - rc, p.z)) - ri;
}

vec2 HexCellId (vec2 p)
{
  vec3 c, r, dr;
  p.y *= (1./sqrt3);
  c.xz = vec2 (0.5 * (p.x - p.y), p.y);
  c.y = - c.x - c.z;
  r = floor (c + 0.5);
  dr = abs (r - c);
  r -= step (2., step (dr.yzx, dr) + step (dr.zxy, dr)) * dot (r, vec3 (1.));
  return r.xz;
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

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

float DigSeg (vec2 q)
{
  return step (abs (q.x), 0.12) * step (abs (q.y), 0.6);
}

#define DSG(q) k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q)

float ShowDig (vec2 q, int iv)
{
  float d;
  int k, kk;
  const vec2 vp = vec2 (0.5, 0.5), vm = vec2 (-0.5, 0.5), vo = vec2 (1., 0.);
  if (iv == -1) k = 8;
  else if (iv < 2) k = (iv == 0) ? 119 : 36;
  else if (iv < 4) k = (iv == 2) ? 93 : 109;
  else if (iv < 6) k = (iv == 4) ? 46 : 107;
  else if (iv < 8) k = (iv == 6) ? 122 : 37;
  else             k = (iv == 8) ? 127 : 47;
  q = (q - 0.5) * vec2 (1.5, 2.2);
  d = 0.;
  kk = k;
  DSG (q.yx - vo);  DSG (q.xy - vp);  DSG (q.xy - vm);  DSG (q.yx);
  DSG (q.xy + vm);  DSG (q.xy + vp);  DSG (q.yx + vo);
  return d;
}

float ShowInt (vec2 q, vec2 cBox, float mxChar, float val)
{
  float nDig, idChar, s, sgn, v;
  q = vec2 (- q.x, q.y) / cBox;
  s = 0.;
  if (min (q.x, q.y) >= 0. && max (q.x, q.y) < 1.) {
    q.x *= mxChar;
    sgn = sign (val);
    val = abs (val);
    nDig = (val > 0.) ? floor (max (log (val) / log (10.), 0.)) + 1. : 1.;
    idChar = mxChar - 1. - floor (q.x);
    q.x = fract (q.x);
    v = val / pow (10., mxChar - idChar - 1.);
    if (sgn < 0.) {
      if (idChar == mxChar - nDig - 1.) s = ShowDig (q, -1);
      else ++ v;
    }
    if (idChar >= mxChar - nDig) s = ShowDig (q, int (mod (floor (v), 10.)));
  }
  return s;
}
