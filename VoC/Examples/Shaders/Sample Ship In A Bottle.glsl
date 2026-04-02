#version 420

// original https://www.shadertoy.com/view/wlXXzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Ship in a Bottle" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1

float PrBoxDf (vec3 p, vec3 b);
float PrBox2Df (vec2 p, vec2 b);
float PrCapsDf (vec3 p, float r, float h);
float PrEVCapsDf (vec3 p, vec4 u, float r);
float PrEECapsDf (vec3 p, vec3 v1, vec3 v2, float r);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
float PrCaps44Df (vec3 p, float r, float h);
float PrCapsAn44Df (vec3 p, float r, float w, float h);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
float Length44c (vec3 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec4 vum[4], vur[5];
vec3 vim[4], vir[5], shipConf, bDeck, qHit, sunDir;
float tCur, dstFar, szFac, rBot;
int idObj;
const int idHull = 1, idRud = 2, idStruc = 3, idMast = 4, idSparT = 5, idSparL = 6, idSailT = 7,
   idSailA = 8, idSailF = 9, idFlag = 10, idRig = 11, idCork = 21, idCap = 22;
bool inBot, chkBot;
const float pi = 3.14159;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }
#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjDf (vec3 p)
{
  float dMin, d, w;
  dMin = dstFar;
  w = 0.05;
  if (chkBot) {
    if (inBot) dMin = SmoothMin (PrCapsAn44Df (p, rBot + w, w, 0.5 * rBot + w),
       PrCylAnDf (vec3 (p.xy, p.z - 1.65 * rBot), 0.25 * rBot + w, w, 0.25 * rBot + w), 10. * w);
    else dMin = SmoothMin (PrCaps44Df (p, rBot, 0.5 * rBot),
       PrCylDf (vec3 (p.xy, p.z - 1.65 * rBot), 0.25 * rBot, 0.25 * rBot), 10. * w);
  } else {
    d = PrCylDf (vec3 (p.xy, p.z - 1.8 * rBot), 0.25 * rBot - 4. * w, 0.25 * rBot);
    DMIN (idCork);
    d = PrCylDf (vec3 (p.xy, p.z - 2. * rBot), 0.25 * rBot + 4. * w, 0.1 * rBot);
    DMIN (idCap);
  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.001, -0.001);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ShipHullDf (vec3 p, float dMin)
{
  vec3 q;
  float d, fy, fz, gz;
  q = p;
  d = abs (p.z) - 4.5;
  q.z = mod (q.z + 1.4, 2.8) - 1.4;
  q.yz -= vec2 (-3.4, -0.4);
  d = max (d, PrBoxDf (q, vec3 (0.3, 0.1, 0.5)));
  DMINQ (idStruc);
  q = p;
  q.x = abs (q.x);
  q.yz -= vec2 (-3.8, 0.5);
  fz = q.z / 5. + 0.3;
  fz *= fz;
  fy = 1. - smoothstep (-1.3, -0.1, q.y);
  gz = smoothstep (2., 5., q.z);
  bDeck = vec3 ((1. - 0.45 * fz * fz) * (1.1 - 0.5 * fy * fy) *
     (1. - 0.5 * smoothstep (-5., -2., q.y) * smoothstep (2., 5., q.z)),
     0.78 - 0.8 * gz * gz - 0.2 * (1. - smoothstep (-5.2, -4., q.z)), 5. * (1. + 0. * 0.02 * q.y));
  d = min (PrBoxDf (vec3 (q.x, q.y + bDeck.y - 0.6, q.z), bDeck),
     max (PrBoxDf (q - vec3 (0., 0.72, -4.6), vec3 (bDeck.x, 0.12, 0.4)),
     - PrBox2Df (vec2 (abs (q.x) - 0.4, q.y - 0.65), vec2 (0.2, 0.08))));
  d = max (d, - PrBoxDf (vec3 (q.x, q.y - 0.58 - 0.1 * fz, q.z),
     vec3 (bDeck.x - 0.07, 0.3, bDeck.z - 0.1)));
  q = p;
  d = max (d, - max (PrBox2Df (vec2 (q.y + 3.35, mod (q.z + 0.25, 0.5) - 0.25), vec2 (0.08, 0.1)),
     abs (q.z + 0.5) - 3.75));
  DMINQ (idHull);
  q = p;
  d = PrBoxDf (q + vec3 (0., 4.4, 4.05), vec3 (0.03, 0.35, 0.5));
  DMINQ (idRud);
  return dMin;
}

float ShipMastDf (vec3 p, float dMin)
{
  vec3 q, qq;
  float d, fy, fz, s, rSpar, yLim, zLim;
  rSpar = 0.05;
  fy = 1. - 0.07 * p.y;
  fz = 1. - 0.14 * step (1., abs (p.z));
  zLim = abs (p.z) - 4.5;
  q = p;
  d = zLim;
  q.z = mod (q.z + 1.4, 2.8) - 1.2;
  d = max (d, PrCapsDf ((q - vec3 (0., 3.7 * (fz - 1.), 0.)).xzy, 0.1 * fy, 3.7 * fz));
  DMINQ (idMast);
  q = p;
  yLim = abs (q.y - 0.2 * fz) - 3. * fz;
  qq = q;
  qq.y = mod (qq.y - 3.3 * (fz - 1.), 2. * fz) - fz;
  qq.z = mod (qq.z + 1.4, 2.8) - 1.4 + 0.1 * fz;
  d = max (max (min (d, PrCylDf (vec3 (qq - vec3 (0., 0.05 * fy * fz, 0.1 * fz - 0.23)).xzy,
     0.15 * fy, 0.11 * fy * fz)), yLim), zLim);
  DMINQ (idMast);
  d = max (max (PrCapsDf (qq.yzx, 0.05, 1.23 * fy * fz), yLim), zLim);
  DMINQ (idSparT);
  q = p;
  d = min (d, min (PrEVCapsDf (q - vim[0], vum[0], rSpar), PrEVCapsDf (q - vim[1], vum[1], rSpar)));
  d = min (d, min (PrEVCapsDf (q - vim[2], vum[2], rSpar), PrEVCapsDf (q - vim[3], vum[3], rSpar)));
  DMINQ (idSparL);
  return dMin;
}

float ShipSailDf (vec3 p, float dMin)
{
  vec3 q, qq, w;
  float d, fy, fz;
  fy = 1. - 0.07 * p.y;
  fz = 1. - 0.14 * step (1., abs (p.z));
  q = p;
  qq = q;
  qq.y = mod (qq.y - 3.1 * (fz - 1.), 2. * fz) - fz;
  qq.z = mod (qq.z + 1.4, 2.8) - 1.4 + 0.2 * (fz - abs (qq.y)) * (fz - abs (qq.y)) - 0.1 * fz;
  d = max (max (max (PrBoxDf (qq, vec3 ((1.2 - 0.07 * q.y) * fz, fz, 0.01)),
     min (qq.y, 1.5 * fy * fz - length (vec2 (qq.x, qq.y + 0.9 * fy * fz)))),
     abs (q.y - 3. * (fz - 1.)) - 2.95 * fz), - PrBox2Df (qq.yz, vec2 (0.01 * fz)));
  d = max (d, abs (p.z) - 4.5);
  DMINQ (idSailT);
  q = p;
  q.z -= -3.8;  q.y -= -1.75 - 0.2 * q.z;
  d = PrBoxDf (q, vec3 (0.01, 0.9 - 0.2 * q.z, 0.6));
  DMINQ (idSailA);
  q = p;
  q.yz -= vec2 (-1., 4.5);
  w = vec3 (1., q.yz);
  d = max (max (max (abs (q.x) - 0.01, - dot (w, vec3 (2.3, 1., -0.35))),
     - dot (w, vec3 (0.68, -0.74, -1.))), - dot (w, vec3 (0.41, 0.4, 1.)));
  DMINQ (idSailF);
  q = p;
  q.yz -= vec2 (3.4, 0.18);
  d = PrBoxDf (q, vec3 (0.01, 0.2, 0.3));
  DMINQ (idFlag);
  return dMin;
}

float ShipRigDf (vec3 p, float dMin)
{
  vec3 q;
  float rRig, d, fz, gz, s;
  rRig = 0.02;
  fz = 1. - 0.14 * step (1., abs (p.z));
  q = p;
  d = abs (p.z) - 4.5;
  gz = (q.z - 0.5) / 5. + 0.3;
  gz *= gz;
  gz = 1.05 * (1. - 0.45 * gz * gz);
  q.x = abs (q.x);
  q.z = mod (q.z + 1.4, 2.8) - 1.4;
  d = max (d, min (PrEECapsDf (q, vec3 (1.05 * gz, -3.25, -0.5),
     vec3 (1.4 * fz, -2.95, -0.05), 0.7 * rRig),
     PrEECapsDf (vec3 (q.xy, abs (q.z + 0.2) - 0.01 * (0.3 - 2. * q.y)), vec3 (gz, -3.2, 0.),
     vec3 (0.05, -0.9 + 2. * (fz - 1.), 0.), rRig)));
  q = p;
  d = min (d, PrEVCapsDf (q - vir[0], vur[0], 0.8 * rRig));
  d = min (min (d, min (PrEVCapsDf (q - vir[1], vur[1], rRig),
     PrEVCapsDf (q - vir[2], vur[2], rRig))), PrEVCapsDf (q - vir[3], vur[3], rRig));
  q.x = abs (q.x);
  d = min (d, PrEVCapsDf (q - vir[4], vur[4], rRig));
  s = step (1.8, q.y) - step (q.y, -0.2);
  d = min (min (d, min (PrEECapsDf (q, vec3 (0.95, 0.4, 2.7) + vec3 (-0.1, 1.7, 0.) * s,
     vec3 (0.05, 1.1, -0.15) + vec3 (0., 2., 0.) * s, rRig),
     PrEECapsDf (q, vec3 (1.05, 1., -0.1) + vec3 (-0.1, 2., 0.) * s,
     vec3 (0.05, 0.5, -2.95) + vec3 (0., 1.7, 0.) * s, rRig))),
     PrEECapsDf (q, vec3 (0.95, 0.4, -2.9) + vec3 (-0.1, 1.7, 0.) * s,
     vec3 (0.05, 0.9, -0.25) + vec3 (0., 2., 0.) * s, rRig));
  DMINQ (idRig);
  return dMin;
}

float ShipDf (vec3 p)
{
  vec3 q;
  float dMin;
  q = p;
  q -= shipConf;
  q /= szFac;
  dMin = dstFar / szFac;
  dMin = ShipHullDf (q, dMin);
  dMin = ShipMastDf (q, dMin);
  dMin = ShipSailDf (q, dMin);
  dMin = ShipRigDf (q, dMin);
  return 0.7 * szFac * dMin;
}

float ShipRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
    d = ShipDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ShipNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.001, -0.001);
  v = vec4 (- ShipDf (p + e.xxx), ShipDf (p + e.xyy), ShipDf (p + e.yxy), ShipDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

void EvalShipConf ()
{
  vec3 vd;
  shipConf = vec3 (0., 4.8 * szFac - 0.9 * rBot, -0.5 * szFac);
  vim[0] = vec3 (0., -3.5, 4.3);   vd = vec3 (0., -2.6, 6.7) - vim[0];   vum[0] = vec4 (normalize (vd), length (vd));
  vim[1] = vec3 (0., -4., 4.1);    vd = vec3 (0., -2.9, 6.) - vim[1];    vum[1] = vec4 (normalize (vd), length (vd));
  vim[2] = vec3 (0., -1.2, -3.);   vd = vec3 (0., -0.5, -4.5) - vim[2];  vum[2] = vec4 (normalize (vd), length (vd));
  vim[3] = vec3 (0., -2.7, -3.);   vd = vec3 (0., -2.7, -4.5) - vim[3];  vum[3] = vec4 (normalize (vd), length (vd));
  vir[0] = vec3 (0., -3., -4.45);  vd = vec3 (0., -2.7, -4.5) - vir[0];  vur[0] = vec4 (normalize (vd), length (vd));
  vir[1] = vec3 (0., 2.45, 2.65);  vd = vec3 (0., -2.7, 6.5) - vir[1];   vur[1] = vec4 (normalize (vd), length (vd));
  vir[2] = vec3 (0., 2.5, 2.65);   vd = vec3 (0., -3.2, 4.9) - vir[2];   vur[2] = vec4 (normalize (vd), length (vd));
  vir[3] = vec3 (0., 2.6, -3.);    vd = vec3 (0., -0.5, -4.5) - vir[3];  vur[3] = vec4 (normalize (vd), length (vd));
  vir[4] = vec3 (0.65, -3.5, 3.5); vd = vec3 (0.05, -2.7, 6.4) - vir[4]; vur[4] = vec4 (normalize (vd), length (vd));
}

float ShipSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 30; j ++) {
    h = ShipDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.03 * d, h));
    d += clamp (h, 0.02, 0.3);
    if (sh < 0.05) break;
  }
  return 0.5  + 0.5 * sh;
}

void ShipCol (out vec4 col4, out vec2 vf)
{
  vec2 cg;
  vf = vec2 (0.);
  if (idObj == idHull) {
    if (abs (qHit.x) < bDeck.x - 0.08 && qHit.y > -3.6 && qHit.z > - bDeck.z + 0.62) {
      col4 = vec4 (0.5, 0.3, 0., 0.1) * (0.5 +
         0.5 * SmoothBump (0.05, 0.95, 0.02, mod (8. * qHit.x, 1.)));
    } else if (qHit.y > -4.) {
      col4 = vec4 (0.7, 0.5, 0.1, 0.1);
      if (abs (qHit.z - 4.) < 0.25 && abs (qHit.y + 3.55) < 0.05) col4 *= 1.2;
      else if (qHit.z < -4. && abs (qHit.x) < 0.84 && abs (qHit.y + 3.62) < 0.125) {
        cg = step (0.1, abs (fract (vec2 (6. * qHit.x, 8. * (qHit.y + 3.62)) + 0.5) - 0.5));
        if (cg.x * cg.y == 1.) col4 = vec4 (0.8, 0.8, 0.2, 1.);
        else col4 *= 0.8;
      } else {
        col4 *= 0.7 + 0.3 * SmoothBump (0.05, 0.95, 0.02, mod (8. * qHit.y, 1.));
        vf = vec2 (64., 0.3);
      } 
    } else if (qHit.y > -4.05) {
      col4 = vec4 (0.8, 0.8, 0.8, 0.1);
    } else if (qHit.y < -4.7) {
      col4 = vec4 (0.8, 0., 0., 0.1);
      vf = vec2 (64., 2.);
    } else {
      col4 = vec4 (0.3, 0.2, 0.1, 0.);
      vf = vec2 (64., 2.);
    }
  } else if (idObj == idRud) {
    col4 = vec4 (0.5, 0.3, 0., 0.);
  } else if (idObj == idStruc) {
    col4 = vec4 (0.4, 0.3, 0.1, 0.1);
    if (max (abs (qHit.x), abs (qHit.z + 0.22)) < 0.2) {
      cg = step (0.1, abs (fract (vec2 (10. * vec2 (qHit.x, qHit.z + 0.22)) + 0.5) - 0.5));
      if (cg.x * cg.y == 1.) col4 = vec4 (0.8, 0.8, 0.2, 1.);
    }
  } else if (idObj == idSailT) {
    qHit.x *= (1. + 0.07 * qHit.y) * (1. + 0.14 * step (1., abs (qHit.z)));
    col4 = vec4 (1., 1., 1., 0.) * (0.7 + 0.3 * SmoothBump (0.05, 0.95, 0.02, mod (4. * qHit.x, 1.)));
    if (abs (qHit.z) < 0.2 && abs (abs (length (qHit.xy - vec2 (0., 0.3)) - 0.35) - 0.15) < 0.07)
       col4 *= vec4 (0.2, 1., 0.2, 1.);
  } else if (idObj == idSailA) {
    col4 = vec4 (1., 1., 1., 0.) * (0.7 + 0.3 * SmoothBump (0.05, 0.95, 0.02, mod (5. * qHit.z, 1.)));
  } else if (idObj == idSailF) {
    col4 = vec4 (1., 1., 1., 0.) * (0.7 + 0.3 * SmoothBump (0.05, 0.95, 0.02,
       mod (2.95 * qHit.y + 4. * qHit.z - 0.5, 1.)));
  } else if (idObj == idFlag) {
    col4 = vec4 (1., 1., 0.5, 0.1);
    if (abs (abs (length (qHit.yz) - 0.1) - 0.04) < 0.02) col4 *= vec4 (0.2, 1., 0.2, 1.);
  } else if (idObj == idMast) {
    col4 = vec4 (0.7, 0.4, 0., 0.1);
    if (length (qHit.xz) < 0.16 * (1. - 0.07 * qHit.y))
       col4 *= 0.6 + 0.4 * SmoothBump (0.03, 0.97, 0.01, mod (2. * qHit.y /
       (1. + 0.14 * step (1., abs (qHit.z))), 1.));
  } else if (idObj == idSparT) {
    qHit.x *= (1. + 0.07 * qHit.y) * (1. + 0.14 * step (1., abs (qHit.z)));
    col4 = vec4 (0.7, 0.4, 0., 0.1) *  (0.6 + 0.4 * SmoothBump (0.08, 0.92, 0.01,
       mod (4. * qHit.x, 1.)));
  } else if (idObj == idSparL) {
    col4 = vec4 (0.7, 0.4, 0., 0.1);
  } else if (idObj == idRig) {
    col4 = vec4 (0.2, 0.15, 0.1, 0.);
    vf = vec2 (32., 0.5);
  }
}

vec4 ObjCol (vec3 p)
{
  vec4 c;
  if (idObj == idCork) c = vec4 (0.5, 0.4, 0.3, 0.05);
  else if (idObj == idCap) c = vec4 (0.2, 0.1, 0.1, 0.2) * (0.8 + 
     0.2 * sin (32. * atan (p.y, - p.x) / 2. * pi) * step (1.5, length (p.xy)));
  return c;
}

vec3 BgCol (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 c, u, uu;
  vec2 f;
  float t;
  col4 = vec4 (0.);
  uu = normalize (ro + 200. * rd);
  for (int ky = -1; ky <= 1; ky ++) {
    for (int kx = -1; kx <= 1; kx ++) {
      u = uu;
      f = vec2 (kx, ky);
      u.yz = Rot2D (u.yz, 0.0025 * f.y);
      u.xz = Rot2D (u.xz, 0.0025 * f.x);
      t = max (SmoothBump (0.45, 0.55, 0.02, mod (64. * atan (u.z, - u.x) / pi, 1.)),
         SmoothBump (0.45, 0.55, 0.02, mod (64. * asin (u.y) / pi, 1.)));
      c = mix (vec3 (0.2, 0.3, 0.6), vec3 (0.7, 0.7, 0.4), t) * (0.6 + 0.4 * u.y);
      t = (u.y > 2. * max (abs (u.x), abs (u.z * 0.25))) ? 0.5 * min (2. * u.y, 1.) :
         0.05 * (1. + dot (u, sunDir));
      if (u.y > 0.) t += pow (clamp (1.05 - 0.5 *
         length (max (abs (u.xz / u.y) - 0.4 * vec2 (1., 4.), 0.)), 0., 1.), 8.);
      c += vec3 (0.5, 0.5, 1.) * t;
      col4 += vec4 (min (c, 1.), 1.) * (1. - 0.15 * dot (f, f));
    }
  }
  return col4.rgb / col4.w;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 roo, rdo, rdd, vn, vnW, col;
  vec2 vf;
  float dstShip, dstObj, dstBot, dstBotW, rdDotN, eta, sh;
  int idObjS;
  bool bWallHit;
  rBot = 6.;
  szFac = 1.2;
  EvalShipConf ();
  eta = 1.001;
  chkBot = true;
  inBot = false;
  dstBot = ObjRay (ro, rd);
  chkBot = false;
  dstObj = ObjRay (ro, rd);
  dstShip = dstFar;
  bWallHit = (dstBot < min (dstObj, dstFar));
  if (bWallHit) {
    dstBotW = dstBot;
    roo = ro;
    rdo = rd;
    ro += dstBot * rd;
    chkBot = true;
    vn = ObjNf (ro);
    vnW = vn;
    rdDotN = - dot (rd, vn);
    rd = refract (rd, vn, 1. / eta);
    ro += 0.1 * rd;
    inBot = true;
    dstBot = ObjRay (ro, rd);
    chkBot = false;
    dstShip = ShipRay (ro, rd);
    idObjS = idObj;
    dstObj = ObjRay (ro, rd);
    if (dstBot < min (min (dstShip, dstObj), dstFar)) {
      ro += dstBot * rd;
      chkBot = true;
      vn = ObjNf (ro);
      rdd = refract (rd, vn, eta);
      if (length (rdd) > 0.) {
        rd = rdd;
        ro += 0.01 * rd;
        chkBot = false;
        dstObj = ObjRay (ro, rd);
     } else {
        rd = reflect (rd, vn);
        dstObj = dstFar;
      }
    }
  }
  if (min (dstShip, dstObj) < dstFar) {
    if (dstShip < dstObj) {
      dstObj = dstShip;
      idObj = idObjS;
    }
    ro += dstObj * rd;
    if (idObj >= idHull && idObj <= idRig) {
      vn = ShipNf (ro);
      ShipCol (col4, vf);
      if (vf.x > 0.) vn = VaryNf (vf.x * qHit, vn, vf.y);
      sh = ShipSShadow (ro, sunDir);
    } else {
      chkBot = false;
      vn = ObjNf (ro);
      col4 = ObjCol (ro);
      sh = 1.;
    }
    col = col4.rgb * (0.2 + 0.8 * sh * max (dot (sunDir, vn), 0.)) +
       col4.a * step (0.95, sh) * pow (max (dot (normalize (sunDir - rd), vn), 0.), 32.);
  } else col = BgCol (ro, rd);
  if (bWallHit) {
    ro = roo + dstBotW * rdo;
    rd = reflect (rdo, vnW);
    col = mix (BgCol (ro, rd), col, 0.1 + 0.9 * smoothstep (0.4, 0.8, rdDotN));
  }
  return pow (clamp (col, 0., 1.), vec3 (0.8));
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse.x*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az += 0.03 * pi * tCur;
    el -= 0.05 * pi * sin (0.02 * pi * tCur);
  }
  el = clamp (el, -0.4 * pi, 0.05 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0.5, -50.);
  zmFac = 5.5;
  dstFar = 100.;
  sunDir = vuMat * normalize (vec3 (1., 1., -1.));
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
  glFragColor = vec4 (pow (col, vec3 (1.)), 1.);
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

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCylAnDf (vec3 p, float r, float w, float h)
{
  return max (abs (length (p.xy) - r) - w, abs (p.z) - h);
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
}

float PrEVCapsDf (vec3 p, vec4 u, float r)
{
  return length (p - clamp (dot (p, u.xyz), 0., u.w) * u.xyz) - r;
}

float PrEECapsDf (vec3 p, vec3 v1, vec3 v2, float r)
{
  return PrEVCapsDf (p - v1, vec4 (normalize (v2 - v1), length (v2 - v1)), r);
}

float PrCaps44Df (vec3 p, float r, float h)
{
  return Length44c (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
}

float PrCapsAn44Df (vec3 p, float r, float w, float h)
{
  p.z = abs (p.z);
  return max (Length44c (p - vec3 (0., 0., min (p.z, h + w))) - r,
     - Length44c (p - vec3 (0., 0., min (p.z, h - w))) + r) - w;
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

float Length44c (vec3 p)
{
  p.xy *= p.xy;
  return sqrt (length (vec2 (sqrt (dot (p.xy, p.xy)), p.z * p.z)));
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
