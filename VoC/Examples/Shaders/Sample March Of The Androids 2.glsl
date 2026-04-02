#version 420

// original https://www.shadertoy.com/view/WtlyR4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "March of the Androids 2" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrBoxDf (vec3 p, vec3 b);
float PrSphDf (vec3 p, float r);
float PrRoundCylDf (vec3 p, float r, float rt, float h);
vec2 Rot2D (vec2 q, float a);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

vec3 sunDir, qHit;
float tCur, dstFar, rAngH, rAngL, rAngA, gDisp;
int idObj;
bool walk;
const float pi = 3.1415927;

vec3 TrackPath (float t)
{
  vec3 p;
  vec2 tr;
  float ti[5], rPath, a, r, tC, tL, tWf, tWb, rDir;
  bool rotStep;
  rPath = 34.;
  tC = pi * rPath / 8.;
  tL = 2. * rPath / 5.;
  tWf = 4.;
  tWb = 2.;
  rotStep = false;
  ti[0] = 0.;
  ti[1] = ti[0] + tWf;
  ti[2] = ti[1] + tL;
  ti[3] = ti[2] + tWb;
  ti[4] = ti[3] + tC;
  p.y = 1.;
  rDir = 2. * floor (mod (t / ti[4], 2.)) - 1.;
  t = mod (t, ti[4]);
  tr = vec2 (0.);
  if (t < ti[1]) {
    tr.y = rPath;
  } else if (t < ti[2]) {
    tr.y = rPath - 2. * rPath * (t - ti[1]) / (ti[2] - ti[1]);
  } else if (t < ti[3]) {
    tr.y = - rPath;
  } else {
    rotStep = true;
    a = 1.5 - rDir * (t - ti[3]) / (ti[4] - ti[3]);
    r = rPath;
  }
  if (rotStep) {
    a *= pi;
    p.xz = r * vec2 (cos (a), sin (a));
  } else {
    p.xz = tr;
  }
  p.xz -= 2.5;
  return p;
}

float ObjDf (vec3 p)
{
  vec3 q, pp;
  vec2 ip;
  float dMin, d, bf, hGap, bFac, ah;
  int objType;
  hGap = 2.5;
  bf = PrBoxDf (p, vec3 (9. * hGap, 6., 9. * hGap));
  pp = p;
  ip = floor ((pp.xz + hGap) / (2. * hGap));
  pp.xz = pp.xz - 2. * hGap * ip;
  objType = (ip.x == 0. && ip.y == 4.) ? 20 : 10;
  bFac = (objType == 20) ? 1.6 : 1.;
  ah = rAngH * (walk ? sign (1.1 - bFac) : - step (1.1, bFac));
  dMin = dstFar;
  q = p;
  d = q.y + 1.;
  DMINQ (1);
  q = pp;
  q.y -= 1.2;
  d = max (PrSphDf (q, 0.85), - q.y);
  d = max (d, bf);
  DMINQ (objType + 1);
  q = pp;
  q.y -= 0.55;
  d = PrRoundCylDf (q.xzy, 0.9, 0.28, 0.7);
  d = max (d, bf);
  DMINQ (objType + 1);
  q = pp;
  q.x = abs (q.x) - 0.4;
  q.yz = Rot2D (q.yz, - rAngL * sign (pp.x));
  q.y -= -0.525;
  d = PrRoundCylDf (q.xzy, 0.25, 0.15, 0.55);
  d = max (d, bf);
  DMINQ (objType + 1);
  q = pp;
  q.xz = Rot2D (q.xz, ah);
  if (bFac > 1.) {
    q.xz = Rot2D (q.xz, 2. * pi * floor (6. * atan (q.z, - q.x) / (2. * pi) + 0.5) / 6.);
    q.x += 0.4;
  } else {
    q.x = abs (q.x) - 0.4;
  }
  q.y -= 2.;
  q.xy = Rot2D (q.xy, -0.2 * pi * sign (bFac - 1.1));
  q.y -= 0.2 * (2. * bFac - 1.);
  d = PrRoundCylDf (q.xzy, 0.06, 0.04, 0.4 * (2. * bFac - 1.));
  d = max (d, bf);
  DMINQ (objType + 2);
  q = pp;
  q.x = abs (q.x) - 1.05;
  q.y -= 1.1;
  q.yz = Rot2D (q.yz, rAngA * (walk ? sign (pp.x) : 1.));
  q.y -= -0.6;
  d = PrRoundCylDf (q.xzy, 0.2, 0.15, 0.6);
  d = max (d, bf);
  DMINQ (objType + 3);
  q = pp;
  q.xz = Rot2D (q.xz, ah);
  q.x = abs (q.x) - 0.4;
  q -= vec3 (0., 1.6 + 0.3 * (bFac - 1.), 0.7 - 0.3 * (bFac - 1.));
  d = PrSphDf (q, 0.15 * bFac);
  d = max (d, bf);
  DMINQ (objType + 4);
  return 0.9 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
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

float ChqPat (vec3 p, float dHit)
{
  vec2 q, iq;
  float f, s;
  p.z += gDisp;
  q = p.xz + vec2 (0.5, 0.25);
  iq = floor (q);
  s = 0.5 + 0.5 * Noisefv2 (q * 107.);
  if (2. * floor (iq.x / 2.) != iq.x) q.y += 0.5;
  q = smoothstep (0., 0.02, abs (fract (q + 0.5) - 0.5));
  f = dHit / dstFar;
  return s * (1. - 0.9 * exp (-2. * f * f) * (1. - q.x * q.y));
}

vec3 ObjCol (vec3 rd, vec3 vn, float dHit)
{
  vec3 col;
  int idObjP;
  idObjP = idObj;
  if (idObjP == 1) {
    col = mix (vec3 (0.2, 0.3, 0.2), vec3 (0.3, 0.3, 0.35),
       (0.5 + 0.5 * ChqPat (qHit / 5., dHit)));
  } else if (idObjP > 20) {
    idObjP -= 20;
    if (idObjP == 1 || idObjP == 2 || idObjP == 3) col = vec3 (1., 0.7, 0.1);
    else if (idObjP == 4) col = vec3 (0.3, 1., 0.1);
  } else if (idObjP > 10) {
    idObjP -= 10;
    if (idObjP == 1) col = vec3 (0.05);
    else if (idObjP == 2) col = (qHit.y > 0.) ? vec3 (1.) : vec3 (0.05);
    else if (idObjP == 3) col = (qHit.y < 0.) ? vec3 (1.) : vec3 (0.05);
    else if (idObjP == 4) col = vec3 (1., 0.1, 0.1);
  }
  return col * (0.3 + 0.7 * max (dot (vn, sunDir), 0.)) +
     0.3 * pow (max (0., dot (sunDir, reflect (rd, vn))), 32.);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = 0; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.1 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.7 + 0.3 * sh;
}

vec3 BgCol (vec3 ro, vec3 rd)
{
  vec3 col;
  if (rd.y > 0.) {
    ro.xz += 2. * tCur;
    col = vec3 (0.1) + 0.2 * pow (1. - max (rd.y, 0.), 8.);
    col = mix (col, vec3 (1.), clamp (0.1 + 1.5 * Fbm2 (0.05 * (ro.xz +
       rd.xz * (50. - ro.y) / rd.y)) * rd.y, 0., 1.));
  } else {
    col = mix (vec3 (0.6, 0.5, 0.3), 0.9 * (vec3 (0.1) + 0.2) + 0.1, pow (1. + rd.y, 5.));
  }
  col *= vec3 (1., 0.7, 0.7);
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 vn, col, c;
  float dstHit, tCyc, refl, spd;
  spd = 0.7;
  tCyc = mod (spd * tCur, 7.);
  if (tCyc < 4.) {
    walk = true;
    tCyc = mod (tCyc, 1.);
    gDisp = mod (spd * tCur, 1.);
    rAngH = -0.7 * sin (2. * pi * tCyc);
    rAngA = 1.1 * sin (2. * pi * tCyc);
    rAngL = 0.6 * sin (2. * pi * tCyc);
  } else {
    walk = false;
    tCyc = mod (tCyc, 1.);
    gDisp = 0.;
    rAngH = 0.4 * sin (2. * pi * tCyc);
    rAngA = 2. * pi * (0.5 - abs (tCyc - 0.5)); 
    rAngL = 0.;
  }
  dstHit = ObjRay (ro, rd);
  if (dstHit < dstFar) {
    ro += rd * dstHit;
    vn = ObjNf (ro);
    col = ObjCol (rd, vn, dstHit);
    if (idObj != 1) {
      rd = reflect (rd, vn);
      ro += 0.01 * rd;
      refl = 0.2 + 0.3 * pow (1. - dot (vn, rd), 4.);
      dstHit = ObjRay (ro, rd);
      if (dstHit < dstFar) {
        ro += rd * dstHit;
        c = ObjCol (rd, ObjNf (ro), dstHit);
      } else {
        c = BgCol (ro, rd);
      }
      col = mix (col, c, refl);
    }
    col *= ObjSShadow (ro, sunDir);
  } else {
    col = BgCol (ro, rd);
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec3 col, ro, rd, vd, u;
  vec2 canvas, uv;
  float f;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  ro = TrackPath (tCur);
  vd = normalize (vec3 (0., 2., 0.) - ro);
  u = - vd.y * vd;
  f = 1. / sqrt (1. - vd.y * vd.y);
  vuMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd);
  rd = vuMat * normalize (vec3 (uv, 2.2));
  dstFar = 150.;
  sunDir = normalize (vec3 (1., 2., 1.));
  col = ShowScene (ro, rd);
  glFragColor = vec4 (pow (col, vec3 (0.8)), 1.);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrRoundCylDf (vec3 p, float r, float rt, float h)
{
  float s, hz;
  s = length (p.xy) - r;
  hz = abs (p.z) - h;
  return min (min (max (s + rt, hz), max (s, hz + rt)), length (vec2 (s, hz) + rt) - rt);
}

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
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
