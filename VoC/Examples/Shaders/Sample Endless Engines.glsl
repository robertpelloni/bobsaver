#version 420

// original https://www.shadertoy.com/view/ltffzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Endless Engines" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrBoxDf (vec3 p, vec3 b);
float PrBox2Df (vec2 p, vec2 b);
float PrSphDf (vec3 p, float s);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
vec3 HsvToRgb (vec3 c);
float RgbToVal (vec3 c);
float Hashfv3 (vec3 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 bSize, qHit, cId;
vec2 aCs[3], crCs[3], crMid[3];
float tCur, dstFar, crRad, crLen, aRot, stepCnt;
int idObj;
bool colImg, marchImg;
const float pi = 3.14159;
const int idWhl = 1, idSpk = 2, idCrnk = 3, idAx = 4, idPis = 5, idCrod = 6, idCyl = 7,
   idCylEnt = 8, idValv = 9, idPipes = 10, idSup = 11, idBase = 12, idFlr = 13, idCol = 14,
   idRail = 15, idLt = 16;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }
#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float HallDf (vec3 p, float dMin)
{
  vec3 q;
  float d;
  q = p;
  d = max (0.5 * bSize.y - 0.4 - abs (q.y),
    - PrBox2Df (vec2 (q.x, abs (q.z) - 0.5 * bSize.z), vec2 (16., 8.)));
  DMINQ (idFlr);
  d = length (abs (q.xz) - vec2 (16.6, 11.9)) - 0.6;
  DMIN (idCol);
  q = p;  q.z = abs (q.z) - 11.8;  q.y -= -4.6;
  d = min (min (PrCylDf (q.zyx, 0.15, 16.1),
     PrCylDf (vec3 (abs (abs (q.x) - 7.) - 3.5, q.y + 2.5, q.z).xzy, 0.1, 2.5)),
     PrCylDf (vec3 (q.x, abs (q.y + 2.5) - 1., q.z).zyx, 0.1, 16.1));
  q = p;  q.xz = abs (q.xz) - vec2 (16.4, 19.4);  q.y -= -4.6;
  d = min (d, min (min (PrCylDf (q, 0.15, 7.7),
     PrCylDf (vec3 (q.x, q.y + 2.5, abs (q.z) - 2.).xzy, 0.1, 2.5)),
     PrCylDf (vec3 (q.x, abs (q.y + 2.5) - 1., q.z), 0.1, 7.7)));
  DMIN (idRail);
  q = p;  q.xz = abs (q.xz);  q -= vec3 (6., 9.6, 6.);
  d = PrCylDf (q.xzy, 2., 0.2);
  DMINQ (idLt);
  return dMin;
}

float CrnkDf (vec3 p, float dMin)
{
  vec3 q;
  float d, dz;
  for (int k = 0; k < 3; k ++) {
    dz = float (k - 1) * 4.;
    q = p;  q.x -= 8.;
    q.xy = Rot2Cs (q.xy, aCs[k]);
    q.z += dz;
    d = min (PrBoxDf (vec3 (q.x + 0.5 * crRad, q.y, abs (q.z) - 0.5), vec3 (0.5 * crRad, 0.2, 0.1)),
       PrCylDf (vec3 (abs (q.x + 0.5 * crRad) - 0.5 * crRad, q.y, abs (q.z) - 0.5), 0.6, 0.1));
    DMIN (idCrnk);
    d = PrCylDf (vec3 (q.x + crRad, q.yz), 0.3, 0.65);
    DMIN (idAx);
    q = p;  q.xz -= vec2 (8., - dz);
    q.xy = Rot2Cs (q.xy + crMid[k], crCs[k]);
    d = min (PrCylDf (vec3 (abs (q.y) - 0.12, q.zx), 0.15, crLen - 0.5),
       PrCylDf (vec3 (abs (q.x) - crLen, q.yz), 0.6, 0.15));
    DMIN (idCrod);
    q = p;  q.xz -= vec2 (3.5 - (crMid[k].x + crLen * crCs[k].x), - dz);
    d = PrCylDf (q.yzx, 0.25, 3.7);
    DMIN (idPis);
    d = PrCylDf ((q - vec3 (0.7, 1.7, 0.)).yzx, 0.07, 3.);
    DMIN (idPis);
    q.x -= 4.5;
    d = PrCylDf (q, 0.3, 0.5);
    DMIN (idAx);
    d = min (min (PrCylDf ((q + vec3 (0.8, 0., 0.)).yzx, 0.6, 0.13),
       PrCylDf ((q + vec3 (0.8, -0.8, 0.)).xzy, 0.08, 0.95)),
       PrCylDf (vec3 (q.xy, abs (q.z) - 0.35), 0.7, 0.1));
    DMIN (idCrnk);
  }
  return dMin;
}

float EngDf (vec3 p, float dMin)
{
  vec3 q;
  float d;
  p.y += 4.6;
  d = min (PrBoxDf (p + vec3 (0., 4., 0.), vec3 (13., 1., 6.)),
     PrBoxDf (vec3 (abs (p.x + 9.) - 2., p.y + 2.5, p.z), vec3 (1., 1.4, 5.)));
  DMIN (idBase);
  q = p;  q.x -= 8.;
  q.xy = Rot2Cs (q.xy, aCs[0]);
  q.z = abs (q.z) - 7.;
  d = min (PrCylAnDf (q, 4., 0.2, 0.6), PrCylDf (q, 0.6, 0.6));
  DMINQ (idWhl);
  q.xy = Rot2D (q.xy, 2. * pi * (floor (6. * atan (q.y, - q.x) / (2. * pi) + 0.5)) / 6.);
  d = PrCylDf (vec3 (q.x + 2.2, q.y, abs (q.z) - 0.35).zyx, 0.2, 1.7);
  DMIN (idSpk);
  d = max (PrCylDf (p - vec3 (8., 0., 0.), 0.3, 7.8), min (0.35 - abs (mod (p.z + 2., 4.) - 2.),
     6. - abs (p.z)));
  DMIN (idAx);
  dMin = CrnkDf (p, dMin);
  q = p;  q.x -= -8.9;  q.z = mod (q.z + 2., 4.) - 2.;
  d = max (PrCylDf ((q + vec3 (-3.5, 0., 0.)).yzx, 0.7, 0.2), abs (p.z) - 6.);
  DMINQ (idCylEnt);
  d = max (PrCylDf (q.yzx, 1.5, 3.5), abs (p.z) - 6.);
  DMINQ (idCyl);
  q = p + vec3 (8.9, -1.7, 0.);  q.z = mod (q.z + 2., 4.) - 2.;
  d = max (PrCylDf (q.yzx, 0.5, 2.5), abs (p.z) - 6.);
  DMINQ (idValv);
  q = vec3 (abs (p.x + 8.9) - 1.5, p.y - 2.5, p.z);
  d = min (min (max (PrCylDf ((vec3 (q.x, q.y, mod (q.z + 2., 4.) - 2.)).xzy, 0.35, 1.25),
     abs (p.z) - 6.), PrCylDf (vec3 (q.x, q.y - 1.3, q.z), 0.35, 4.)),
     PrSphDf (vec3 (q.x, q.y - 1.3, abs (q.z) - 4.), 0.35));
  q = p + vec3 (8.9, -6.3, 0.);
  d = min (d, min (PrCylDf ((q + vec3 (-1.5, 0., 2.)).xzy, 0.35, 2.5),
     PrCylDf ((q + vec3 (1.5, 0., -2.)).xzy, 0.35, 2.5)));
  d = min (d, length (vec2 (abs (q.x) - 1.5, q.y - 2.5)) - 0.4);
  DMIN (idPipes);
  q = p;  q.x -= 8.;  q.z = abs (abs (p.z) - 4.) - 1.7;
  d = min (PrBoxDf (q + vec3 (0., 1.6, 0.), vec3 (0.5, 1.5, 0.2)), PrCylDf (q, 0.5, 0.3));
  DMIN (idSup);
  q = p + vec3 (-8., -1.8, -2.3);
  d = PrCylDf ((q + vec3 (0., 0.6, 0.)).xzy, 0.12, 0.8);
  q.xz = Rot2D (q.xz, 4. * aRot);
  q.xz = Rot2D (q.xz, 2. * pi * (floor (4. * atan (q.z, - q.x) / (2. * pi) + 0.5)) / 4.);
  q.xy = Rot2D (q.xy, -0.25 * pi);
  d = min (d, PrCylDf ((q + vec3 (0.4, -0.1, 0.)).yzx, 0.05, 0.4));
  DMIN (idAx);
  d = PrSphDf (q + vec3 (0.7, -0.1, 0.), 0.15);
  DMIN (idPis);
  return dMin;
}

float ObjDf (vec3 p)
{
  float dMin;
  dMin = dstFar;
  dMin = HallDf (p, dMin);
  dMin = EngDf (p, dMin);
  return dMin;
}

void SetEngConf ()
{
  aRot = -(0.1 + 0.3 * Hashfv3 (cId + 11.)) * 2. * pi * tCur;
  aCs[0] = vec2 (cos (aRot), sin (aRot));
  aCs[1] = vec2 (cos (aRot + pi * 2./3.), sin (aRot + pi * 2./3.));
  aCs[2] = vec2 (cos (aRot + pi * 4./3.), sin (aRot + pi * 4./3.));
  for (int k = 0; k < 3; k ++) {
    crMid[k].y = -0.5 * crRad * aCs[k].y;
    crCs[k] = vec2 (cos (asin (crMid[k].y / crLen)), crMid[k].y / crLen);
    crMid[k].x = crLen * crCs[k].x + crRad * aCs[k].x;
  }
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p, rdi, s, cIdP;
  float dHit, d, eps;
  eps = 0.0005;
  dHit = eps;
  if (rd.x == 0.) rd.x = 0.001;
  if (rd.y == 0.) rd.y = 0.001;
  if (rd.z == 0.) rd.z = 0.001;
  ro /= bSize;
  rd /= bSize;
  rdi = 1. / rd;
  cIdP = vec3 (-99.);
  stepCnt = 0.;
  for (int j = 0; j < 180; j ++) {
    p = ro + dHit * rd;
    cId = floor (p);
    if (cId.x != cIdP.x || cId.y != cIdP.y || cId.z != cIdP.z) {
      SetEngConf ();
      cIdP = cId;
    }
    s = (cId + step (0., rd) - p) * rdi;
    d = min (ObjDf (bSize * (p - cId - 0.5)), abs (min (min (s.x, s.z), s.y)) + eps);
    dHit += d;
    ++ stepCnt;
    if (d < eps || dHit > dstFar) break;
  }
  if (d >= eps) dHit = dstFar;
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0005, -0.0005);
  p -= bSize * (cId + 0.5);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p, cIdP;
  float sh, d, h;
  sh = 1.;
  cIdP = vec3 (-99.);
  d = 0.1;
  for (int j = 0; j < 16; j ++) {
    p = ro + d * rd;
    cId = floor (ro / bSize);
    if (cId.x != cIdP.x || cId.y != cIdP.y || cId.z != cIdP.z) {
      SetEngConf ();
      cIdP = cId;
    }
    h = ObjDf (p - bSize * (cId + 0.5));
    sh = min (sh, smoothstep (0., 0.1 * d, h));
    d += 0.3;
    if (sh < 0.05) break;
  }
  return sh;
}

vec3 ShGrid (vec2 p)
{
  vec2 q, sq, ss;
  q = p;
  sq = smoothstep (0.05, 0.1, abs (fract (q + 0.5) - 0.5));
  q = fract (q) - 0.5;
  ss = 0.3 * smoothstep (0.3, 0.5, abs (q.xy)) * sign (q.xy);
  if (abs (q.x) < abs (q.y)) ss.x = 0.;
  else ss.y = 0.;
  return vec3 (ss.x, 0.8 + 0.2 * sq.x * sq.y, ss.y);
}

vec3 ShStagGrid (vec2 p, vec2 g)
{
  vec2 q, sq, ss;
  q = p * g;
  if (2. * floor (0.5 * floor (q.y)) != floor (q.y)) q.x += 0.5;
  sq = smoothstep (0.05, 0.1, abs (fract (q + 0.5) - 0.5));
  q = fract (q) - 0.5;
  ss = 0.3 * smoothstep (0.3, 0.5, abs (q.xy)) * sign (q.xy);
  if (abs (q.x) < abs (q.y)) ss.x = 0.;
  else ss.y = 0.;
  return vec3 (ss.x, 0.8 + 0.2 * sq.x * sq.y, ss.y);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, bgCol, vn, lVec, rg;
  vec2 vf;
  float dstObj, a, s, fFade;
  bool fxz;
  crRad = 2.;
  crLen = 5.;
  bgCol = mix (0.6 * vec3 (0.4, 0.4, 0.5), vec3 (0.21), smoothstep (-0.01, 0.01, rd.y));
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    cId = floor (ro / bSize);
    SetEngConf ();
    vn = ObjNf (ro);
    vf = vec2 (0.);
    fFade = exp (32. * min (0., 0.7 - dstObj / dstFar));
    if (idObj == idFlr) {
      if (vn.y > 0.99) {
        col4 = vec4 (0.4, 0.4, 0.5, 0.1);
        rg = ShGrid (ro.xz);
        col4.rgb *= mix (1., rg.y, fFade) * (1. - 0.3 * Fbm2 (2. * ro.xz));
        if (rg.x == 0.) vn.yz = Rot2D (vn.yz, rg.z * fFade);
        else vn.yx = Rot2D (vn.yx, rg.x * fFade);
        col4 *= (1. - 0.5 * smoothstep (12., 16., length (qHit.xz)));
        vf = vec2 (32., 1.);
      } else if (vn.y < -0.99) {
        col4 = vec4 (vec3 (0.3) * (1. - 0.3 * smoothstep (3., 7.,
           length (abs (qHit.xz) - 6.))), -1.);
      } else {
        col4 = vec4 (0.3, 0.3, 0.3, 0.1);
        vf = vec2 (32., 1.);
      }
    } else if (idObj == idBase) {
      col4 = vec4 (0.6, 0.3, 0.2, 0.1);
      if (abs (vn.y) < 0.01) {
        rg = ro;
        rg.y += 0.5;
        fxz = (abs (vn.x) > 0.99);
        rg = ShStagGrid ((fxz ? rg.zy : rg.xy), vec2 (1., 2.));
        col4.r *= rg.y;
        col4.rgb *= 1. - 0.3 * Fbm2 (2. * (fxz ? ro.zy : ro.xy));
        rg.xz *= sign (fxz ? vn.x : vn.z);
        if (fxz) {
          if (rg.x == 0.) vn.xy = Rot2D (vn.xy, rg.z);
          else vn.xz = Rot2D (vn.xz, rg.x);
        } else {
          if (rg.x == 0.) vn.zy = Rot2D (vn.zy, rg.z);
          else vn.zx = Rot2D (vn.zx, rg.x);
        }
      } else {
        rg = ShGrid (ro.xz);
        col4.r *= rg.y;
        col4.rgb *= 1. - 0.3 * Fbm2 (2. * ro.xz);
        if (vn.y > 0.99) {
          if (rg.x == 0.) vn.yz = Rot2D (vn.yz, rg.z);
          else vn.yx = Rot2D (vn.yx, rg.x);
        }
      }
      vf = vec2 (32., 1.);
    } else if (idObj == idCol) {
      col4 = vec4 (0.8, 0.8, 0.75, 0.05);
      vf = vec2 (32., 1.);
    } else if (idObj == idCyl) {
      col4 = vec4 (0.8, 0.8, 0.9, 0.3);
      a = atan (qHit.z, - qHit.y) / (2. * pi);
      if (abs (vn.x) > 0.99) {
        col4.rgb *= 1. - 0.2 * Fbm2 (4. * qHit.yz);
        col4.rgb *= (1. - 0.5 * SmoothBump (0.2, 0.4, 0.01, mod (16. * a + 0.5, 1.)) *
           SmoothBump (0.05, 0.13, 0.01, 1. - length (qHit.yz) / 1.5));
      } else {
        col4.rgb *= 1. - 0.2 * Fbm2 (4. * vec2 (8. * a, qHit.x));
        col4.rgb *= (1. - 0.5 * SmoothBump (0.03, 0.06, 0.01, 1. - abs (qHit.x) / 3.5));
        a = mod (32. * a, 1.);
        if (abs (qHit.x) < 3.3) vn.yz = Rot2D (vn.yz, 0.4 * SmoothBump (0.25, 0.75, 0.2, a) *
           sign (a - 0.5));
      }
    } else if (idObj == idWhl) {
      if (abs (vn.z) < 0.01) {
        s = length (qHit.xy);
        qHit.xy = vec2 (8. * atan (qHit.x, - qHit.y) / pi, qHit.z);
        if (s > 4.1) {
          s = mod (4. * qHit.z, 1.);
          vn.z = -0.2 * SmoothBump (0.25, 0.75, 0.15, s) * sign (s - 0.5) * sign (ro.z);
          vn = normalize (vn);
        }
      }
      col4 = vec4 (0.5, 0.5, 0.55, 0.05) * (1. + 0.2 * Noisefv2 (128. * qHit.xy));
    } else if (idObj == idSpk) {
      col4 = 1.1 * vec4 (0.5, 0.5, 0.55, 0.2);
    } else if (idObj == idCrnk) {
      col4 = vec4 (0.5, 0.5, 0.6, 0.2);
    } else if (idObj == idAx) {
      col4 = vec4 (0.6, 0.4, 0.1, 0.3);
    } else if (idObj == idPis) {
      col4 = vec4 (0.5, 0.5, 0.2, 0.3);
    } else if (idObj == idCrod) {
      col4 = vec4 (0.6, 0.6, 0.5, 0.3);
    } else if (idObj == idCylEnt) {
      col4 = vec4 (0.7, 0.7, 0.8, 0.2) * (1. - 0.5 * step (length (qHit.yz), 0.33));
    } else if (idObj == idValv) {
      col4 = vec4 (0.7, 0.7, 0.8, 0.5) * (1. - 0.5 * step (0., vn.x) *
         step (length (qHit.yz), 0.13));
      vf = vec2 (32., 0.3);
    } else if (idObj == idPipes) {
      col4 = vec4 (0.6, 0.4, 0.1, 0.1);
      vf = vec2 (32., 0.3);
    } else if (idObj == idSup) {
      col4 = vec4 (0.2, 0.4, 0.1, 0.05);
      vf = vec2 (32., 1.);
    } else if (idObj == idRail) {
      col4 = vec4 (0.2, 0.4, 0.2, 0.1);
      vf = vec2 (32., 0.2);
    } else if (idObj == idLt) {
      qHit.xz = smoothstep (0.05, 0.1, abs (qHit.xz));
      col4 = vec4 (vec3 (1., 1., 0.8) * 0.5 * (1. - vn.y) * (0.7 + 0.3 * qHit.x * qHit.z), -1.);
    }
    if (col4.a >= 0.) {
      if (vf.x > 0.) vn = VaryNf (vf.x * ro, vn, vf.y);
      lVec = normalize (vec3 (1., 1.3, 1.));
      col = 0.2 * col4.rgb;
      for (float sx = -1.; sx <= 1.; sx += 2.) {
        for (float sz = -1.; sz <= 1.; sz += 2.) {
          col += 0.5 * col4.rgb * max (dot (vn, lVec * vec3 (sx, 1., sz)), 0.) +
             col4.a * pow (max (dot (normalize (lVec * vec3 (sx, 1., sz) - rd), vn), 0.), 64.);
        }
      }
      col *= 0.7 + 0.3 * ObjSShadow (ro, vec3 (0., 1., 0.));
    } else col = col4.rgb;
    col = clamp (mix (bgCol, col, fFade), 0., 1.);
  } else col = bgCol;
  if (! colImg) col = pow (vec3 (1., 0.59, 0.18) * RgbToVal (col), vec3 (0.9));
  if (marchImg) col = HsvToRgb (vec3 (0.7 * (1. - stepCnt / 180.), 1., 1.));
  return col;
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, asp;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse.xy*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  bSize = vec3 (40., 20., 40.);
  az = 0.;
  el = -0.05 * pi;
  colImg = false;
  marchImg = false;
  if (mPtr.z > 0. && mPtr.x > 0.4 && mPtr.y < -0.4) colImg = true;
  if (mPtr.z > 0. && mPtr.x > 0.4 && mPtr.y > 0.4) marchImg = true;
  if (mPtr.z > 0. && ! colImg && ! marchImg) {
    az += 2. * pi * mPtr.x;
    el += 0.7 * pi * mPtr.y;
  } else {
    az = 0.5 * pi * (2. * mod (floor (0.07 * tCur), 2.) - 1.) *
       SmoothBump (0.2, 0.8, 0.1, mod (0.07 * tCur, 1.));
  }
  el = clamp (el, -0.4 * pi, 0.4 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -1.) + vec3 (0., 8., 3. * tCur);
  asp = canvas.x / canvas.y;
  uv.xy /= 1.9;
  rd = vuMat * normalize (vec3 (2. * tan (0.5 * atan (uv.x / asp)) * asp, uv.y, 1.));
  dstFar = 180.;
  glFragColor = vec4 (ShowScene (ro, rd), 1.);
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

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

float RgbToVal (vec3 c)
{
  return max (c.r, max (c.g, c.b));
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
  for (int i = 0; i < 5; i ++) {
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
  vec3 e = vec3 (0.1, 0., 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
