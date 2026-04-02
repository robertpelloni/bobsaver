#version 420

// original https://www.shadertoy.com/view/3dSfzt

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Belvedere" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1  // optional antialiasing

float PrBoxDf (vec3 p, vec3 b);
float PrBox2Df (vec2 p, vec2 b);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrFlatCylDf (vec3 p, float rhi, float rlo, float h);
float PrFlatCyl2Df (vec2 p, float rhi, float rlo);
float PrEllipsDf (vec3 p, vec3 r);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
float Fbm1 (float p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 ltDir, qHit, vuDir, vuPln;
float dstFar, tCur, fAng;
int idObj;
const int idFlr = 1, idPil = 2, idBal = 3, idFrz = 4, idRf = 5, idLBld = 6, idLad = 7,
   idGrnd = 8, idStr = 9, idWal = 10, idPen = 20;
const float pi = 3.1415927;

#define VAR_ZERO min (frames, 0)

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }
#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float PengDf (vec3 p, float szFac, float rot, int isSit, float dMin)
{
  vec3 q;
  float d, dh;
  dMin /= szFac;
  p /= szFac;
  if (isSit > 0) p.y -= 1.25;
  else p.y -= 1.55;
  q = p;
  q.y -= 0.5;
  d = PrSphDf (q, 2.5);
  if (d < dMin) {
    p.xz = Rot2D (p.xz, rot);
    q = p;
    d = PrEllipsDf (q.xzy, vec3 (1.3, 1.2, 1.4));
    q.y -= 1.5;
    dh = PrEllipsDf (q.xzy, vec3 (0.8, 0.6, 1.3));
    q = p;
    q.x = abs (q.x);
    q -= vec3 (0.3, 2., -0.4);
    d = SmoothMin (d, max (dh, - PrCylDf (q, 0.15, 0.3)), 0.2);
    DMINQ (idPen + 1);
    q = p;
    q.yz -= vec2 (1.6, -0.6);
    d = max (PrEllipsDf (q, vec3 (0.4, 0.2, 0.6)), 0.01 - abs (q.y));
    DMINQ (idPen + 2);
    q = p;
    q.x = abs (q.x);
    q -= vec3 (0.3, 2., -0.4);
    d = PrSphDf (q, 0.15);
    DMINQ (idPen + 3);
    q = p;
    q.x = abs (q.x);
    if (isSit > 0) {
      q.xy -= vec2 (0.6, -1.05);
      q.yz = Rot2D (q.yz, -0.5 * pi);
      q.y -= -0.6;
    } else {
      q.xy -= vec2 (0.4, -0.8);
    }
    d = PrCylDf (q.xzy, 0.12, 0.7);
    DMINQ (idPen + 4);
    q -= vec3 (0.1, -0.67, -0.4);
    q.xz = Rot2D (q.xz, -0.07 * pi);
    d = PrEllipsDf (q.xzy, vec3 (0.15, 0.5, 0.05));
    q.z -= 0.5;
    q.xz = Rot2D (q.xz, 0.15 * pi);
    q.z -= -0.5;
    d = SmoothMin (d, PrEllipsDf (q.xzy, vec3 (0.15, 0.5, 0.05)), 0.05);
    q.z -= 0.5;
    q.xz = Rot2D (q.xz, -0.3 * pi);
    q.z -= -0.5;
    d = SmoothMin (d, PrEllipsDf (q.xzy, vec3 (0.15, 0.5, 0.05)), 0.05);
    DMINQ (idPen + 5);
    q = p;
    q.x = abs (q.x);
    q -= vec3 (1.1, 0.3, -0.2);
    q.yz = Rot2D (q.yz, -0.25 * pi);
    q.xy = Rot2D (q.xy, fAng) - vec2 (0.1, -0.4);
    d = PrEllipsDf (q.xzy, vec3 (0.05, 0.25, 0.9));
    DMINQ (idPen + 6);
  } else dMin = min (dMin, d);
  dMin *= szFac;
  return dMin;
}

float StairDf (vec3 p, float st, float w, float h)
{
  return 0.7 * max ((st + p.y - p.z - abs (mod (p.y + p.z, 2. * st) - st) / sqrt(2.)),
     max (abs (p.x) - w, max (abs (p.y) - h, abs (p.z) - h)));
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, wb, len, wid, b, ds;
  dMin = dstFar;
  len = 4.;
  wid = 1.;
  b = 0.1;
  wb = 0.4 * b;
  q = p;
  q.y -= (vuDir.y > 0.) ? 1.2 : -3.;
  q.xz = (vuDir.y > 0.) ? q.xz : q.zx;
  d = PrBoxDf (q, vec3 (wid + 1.5 * b, 0.1, len + 1.5 * b));
  DMINQ (idFlr);
  if (vuDir.y > 0.) {
    q = p;
    q.y -= 4.4;
    d = abs (q.z) - (len + 1.5 * b);
    q.z = mod (q.z + (1./3.) * len + 0.05, (2./3.) * len + 0.1) - (1./3.) * len - 0.05;
    d = max (d, min (max (max (length (vec2 (q.yz)) - (1./3.) * len , length (q.xy) - wid - b) - 0.1,
       0.3 - q.y), min (PrCylDf ((q - vec3 (0., 1.3, 0.)).xzy, 0.07 * (1. - 1.3 * (q.y - 1.3)), 0.35),
       PrCylDf ((q - vec3 (0., 1.5, 0.)).xzy, 0.15, 0.03))));
    DMIN (idRf);
    q = p;
    q.y = (abs (q.y - 2.4) - 1.8) * sign (q.y - 2.4);
    d = max (PrBoxDf (q, vec3 (wid + wb, 0.5, len + wb)), - PrBox2Df (q.xz, vec2 (wid, len) - wb));
    d = max (d, - PrFlatCyl2Df (vec2 (q.x, q.y + 0.4), wid - b - 0.7, 0.8));
    d = max (d, - PrFlatCyl2Df (vec2 (mod (q.z + (1./3.) * len, (2./3.) * len) -
       (1./3.) * len, q.y + 0.4), (1./3.) * len - b - 0.7, 0.8));
    DMIN (idFrz);
  } else {
    q = p;
    q.y -= -4.5;
    d = PrBoxDf (q, vec3 (len + b, 1.4, wid + b));
    d = max (d, - max (PrFlatCylDf ((q - vec3 (- len - b, 0.3, 0.)).yzx, 0.2, 0.6, 0.4), 0.2 - q.y));
    d = max (d, - max (PrFlatCylDf ((q - vec3 (0.5, 0.3, - wid - b)).yxz, 0.2, 0.6, 0.4), 0.2 - q.y));
    d = max (d, - max (PrFlatCylDf ((q - vec3 (3., -0.3, - wid - b)).yxz, 0.7, 0.5, 0.4), -0.8 - q.y));
    d = min (d, PrBoxDf (q - vec3 (- len - b, -0.5, - wid - b - 0.5), vec3 (0.35, 0.2, 0.4)));
    DMINQ (idLBld);
    q = p - vec3 (-2.7, -4.1, -2.3);
    d = StairDf (q, 0.25, 1., 1.2);
    DMINQ (idStr);
    q = p - vec3 (-9., -5.5, -5.);
    d = PrBoxDf (q, vec3 (8.1, 0.4, 6.3));
    DMINQ (idGrnd);
    q = p - vec3 (-1., -4.7, -6.);
    d = PrBoxDf (q, vec3 (0.1, 0.4, 5.2));
    DMINQ (idWal);
    q = p - vec3 (-7., -4.7, 1.2);
    d = PrBoxDf (q, vec3 (9., 0.4, 0.1));
    DMINQ (idWal);
  }
  q = p;
  q.y -= (vuDir.y > 0.) ? 1.7 : -2.5;
  q.xz = (vuDir.y > 0.) ? q.xz : q.zx;
  d = max (PrBoxDf (q, vec3 (wid + wb, 0.4, len + wb)), - PrBox2Df (q.xz, vec2 (wid, len) - wb));
  d = max (d, - PrBoxDf (q - vec3 (- wid, 0., ((vuDir.y > 0.) ? 0. : - (2./3.) * len)),
     vec3 (0.2, 0.5, (1./3.) * len)));
  d = max (d, - max (PrFlatCyl2Df (vec2 (q.y, mod (mod (q.z + (1./3.) * len, (2./3.) * len) -
     (1./3.) * len + 0.2, 0.4) - 0.2), 0.17, 0.13), abs (q.z) - (len - 0.9 * b)));
  d = max (d, - PrFlatCyl2Df (vec2 (q.y, mod (q.x + 0.2, 0.4) - 0.2), 0.17, 0.13));
  DMIN (idBal);
  if (vuDir.y > 0.) {
    q = p;
    d = max (abs (q.y - 3.) - 1.8, PrBox2Df (vec2 (abs (q.x) - wid,
       abs (abs (q.z) - (2./3.) * len) - (1./3.) * len), vec2 (b)));
    DMIN (idPil);
  }
  q = p;
  q = vec3 (abs (q.x) - wid, q.y + 0.5, abs (abs (q.z) - 2. * len / 3.) - len / 3.);
  d = max (PrBox2Df (q.xz, vec2 (b)), abs (q.y) - 1.6);
  if (vuDir.y < 0.) d = max (d, - dot (q, vuPln));
  DMIN (idPil);
  q = p;
  q = vec3 (abs (abs (q.x) - 2. * len / 3.) - len / 3., q.y + 1.1, abs (q.z) - wid);
  d = max (PrBox2Df (q.xz, vec2 (b)), abs (q.y) - 2.);
  if (vuDir.y > 0.) d = max (d, dot (q, vuPln));
  DMIN (idPil);
  q = p;
  q.xy -= (vuDir.y > 0.) ? vec2 (-1.3, 1.) : vec2 (-2.39, -2.);
  d = abs (q.y) - ((vuDir.y > 0.) ? 1.3 : 2.7);
  q.xy = Rot2D (q.xy, 0.1 * pi);
  d = max (d, PrBox2Df (vec2 (q.x, abs (q.z) - ((vuDir.y > 0.) ? 0.3 : 0.28)), vec2 (0.05)));
  ds = (vuDir.y > 0.) ? max (PrCylDf (vec3 (q.x, mod (q.y + 0.1, 0.4) - 0.21, q.z), 0.03, 0.3),
     abs (q.y + 1.) - 2.2) : max (PrCylDf (vec3 (q.x, Rot2D (vec2 (mod (q.y + 0.15, 0.4) - 0.2, q.z),
     -0.019 * pi * (q.y + 0.9))), 0.03, 0.3), abs (q.y - 1.) - 2.2);
  d = min (d, ds);
  DMIN (idLad);
  q = p - vec3 (-4.1, -4.8, -1.7);
  dMin = PengDf (q, 0.3, 0.45 * pi, 1, dMin);
  q = p - ((vuDir.y > 0.) ? vec3 (-0.6, 1.3, 0.9) : vec3 (-2.5, -2.9, -0.9));
  dMin = PengDf (q, 0.35, ((vuDir.y > 0.) ? 0.6 * pi : 0.), 0, dMin);
  q = p - ((vuDir.y > 0.) ? vec3 (0.3, 1.3, -3.3) : vec3 (3.3, -2.9, -0.3));
  dMin = PengDf (q, 0.35, ((vuDir.y > 0.) ? 0. : -0.3 * pi), 0, dMin);
  q = p - vec3 (-3., -5.1, -6.8);
  q.z = (abs (q.z) - 1.33) * sign (q.z);
  dMin = PengDf (q, 0.4, 0.7 * pi, 0, dMin);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 150; j ++) {
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
  e = vec2 (0.002, -0.002);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjAO (vec3 ro, vec3 rd)
{
  float ao, d;
  ao = 0.;
  for (int j = VAR_ZERO; j < 8; j ++) {
    d = float (j + 1) / 16.;
    ao += max (0., d - 3. * ObjDf (ro + d * rd));
  }
  return 0.6 + 0.4 * clamp (1. - 0.2 * ao, 0., 1.);
}

vec4 PengCol (vec3 p)
{
  vec4 col4;
  if (idObj == idPen + 1) col4 = (qHit.z < -0.2 || qHit.z < 0. && length (qHit.xy) < 0.2) ?
     vec4 (0.95, 0.95, 0.95, 0.05) : vec4 (0.15, 0.15, 0.2, 0.1);
  else if (idObj == idPen + 2) col4 = vec4 (1., 0.8, 0.2, 0.2);
  else if (idObj == idPen + 3) col4 = vec4 (0.05, 0.15, 0.05, 0.2);
  else if (idObj == idPen + 4) col4 = vec4 (0.05, 0.1, 0.05, 0.1);
  else if (idObj == idPen + 5) col4 = vec4 (0.9, 0.9, 0., 0.3);
  else if (idObj == idPen + 6) col4 = vec4 (0.25, 0.25, 0.3, 0.1);
  return col4;
}

vec3 ShowScene (vec3 ro, vec3 rd, vec3 bgCol)
{
  vec4 col4;
  vec3 col, vn;
  float dstObj, ao;
  fAng = -0.2 * pi + 0.15 * pi * SmoothBump (0.25, 0.75, 0.1, mod (0.2 * tCur, 1.)) *
     sin (8. * pi * tCur);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == idFlr) col4 = (vn.y > -0.99) ? vec4 (0.9, 0.85, 0.85, 0.1) :
       vec4 (1., 0.3, 0., 0.2);
    else if (idObj == idBal) col4 = vec4 (0.6, 0.3, 0.1, 0.2);
    else if (idObj == idLBld) col4 = (abs (qHit.x) < 3.8 && abs (qHit.z) < 0.8) ?
       vec4 (0., 0., 0.4, 0.) : vec4 (0.85, 0.8, 0.8, 0.2);
    else if (idObj == idLad) col4 = vec4 (0.95, 0.95, 1., 0.2);
    else if (idObj == idGrnd) col4 = vec4 (0.7, 0.8, 0.7, 0.1) *
       (1. - 0.2 * abs (dot (floor (mod (0.75 * qHit.xz, 2.)), vec2 (1., -1.))));
    else if (idObj == idWal) col4 = vec4 (0.7, 0.7, 0.8, 0.1);
    else if (idObj == idPil) col4 = vec4 (1., 0.8, 0.2, 0.1);
    else if (idObj == idStr) col4 = (abs (qHit.x) > 0.85) ? vec4 (0.9, 0.85, 0.85, 0.2) :
       vec4 (0.6, 0.7, 0.6, 0.1);
    else if (idObj == idRf) col4 = vec4 (1., 0.3, 0., 0.2);
    else if (idObj == idFrz) col4 = vec4 (0.9, 0.5, 0., 0.2);
    else if (idObj > idPen) col4 = PengCol (ro);
    if (idObj == idLBld || idObj == idFlr || idObj == idWal) vn = VaryNf (16. * ro, vn, 0.5);
    ao = (idObj != idLad) ? ObjAO (ro, vn) : 1.;
    col = col4.rgb * (0.2 + 0.8 * max (dot (vn, ltDir), 0.)) +
       col4.a * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    col *= ao;
  } else {
    col = bgCol;
  }
  return pow (clamp (col, 0., 1.), vec3 (0.9));
}

vec3 BgCol (vec2 uv)
{
  return (uv.y + 0.05 < 0.05 * Fbm1 (32. * uv.x)) ? mix (mix (vec3 (0.3, 0.5, 0.3),
     vec3 (0.2, 0.5, 0.2), smoothstep (0.4, 0.6, Fbm2 (256. * uv))),
     vec3 (0.85, 0.85, 1.) * (1. - 0.05 * Fbm1 (128. * uv.x)),
     smoothstep (-0.1, -0.01, uv.y + 0.05)) : mix (vec3 (0.7, 0.7, 0.8), vec3 (0.4, 0.4, 1.),
     uv.y + 0.05);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col, bgCol, vx, vy;
  vec2 canvas, uv, uvv;
  float el, az, zmFac, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.25 * pi;
  el = 0.;
  if (false && mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.5 * pi * mPtr.y;
  }
  ro = vec3 (0., - 1.5 * sign (uv.y), -10.);
  ro.yz = Rot2D (ro.yz, - el);
  ro.xz = Rot2D (ro.xz, - az);
  rd = normalize (- ro);
  vuDir = rd;
  vx = normalize (vec3 (vuDir.z, 0., - vuDir.x));
  vy = vec3 (0., 1., 0.) - vuDir.y * vuDir;
  vuPln = vy;
  zmFac = 0.15;
  dstFar = 30.;
  ltDir = normalize (vec3 (-0.5, 0.7, -1.));
  bgCol = BgCol (uv);
  if (max (abs (uv.x), abs (uv.y)) < 0.98) {
#if ! AA
    const float naa = 1.;
#else
    const float naa = 3.;
#endif  
    col = vec3 (0.);
    sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
    for (float a = float (VAR_ZERO); a < naa; a ++) {
      uvv = uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.), sr * (0.667 * a + 0.5) * pi);
      col += (1. / naa) * ShowScene (ro + vec3 (uvv.x * vx + uvv.y * vy) / zmFac, rd, bgCol);
    }
  } else if (abs (uv.x) < 1.) {
    uv = abs (uv) - 0.97;
    col = vec3 (0.8, 0.7, 0.2) * (0.5 + 0.5 * smoothstep (0., 0.03, max (uv.x, uv.y)));
  } else col = vec3 (0.75);
  if (false && mPtr.z > 0. && length (uv) < 0.01) col *= 0.5;
  glFragColor = vec4 (col, 1);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d;
  d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
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

float PrFlatCyl2Df (vec2 p, float rhi, float rlo)
{
  return length (p - vec2 (clamp (p.x, - rhi, rhi), 0.)) - rlo;
}

float PrEllipsDf (vec3 p, vec3 r)
{
  return (length (p / r) - 1.) * min (r.x, min (r.y, r.z));
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

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
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
