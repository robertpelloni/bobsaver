#version 420

// original https://www.shadertoy.com/view/4dBfzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Canal Ruins" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrBoxDf (vec3 p, vec3 b);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
float PrRCylDf (vec3 p, float r, float rt, float h);
vec2 Rot2D (vec2 q, float a);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
float Fbm1 (float p);
float Fbm2 (vec2 p);
float Fbm3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

#define SQRT3 1.73205

mat3 bMat, boatMat[3];
vec3 bPos, boatPos[3], qHit, trkF, trkA, vuPos, sunDir, cHit, cHitP, qnHit;
float boatAng[3], bAng, tCur, dstFar;
int idObj, idObjGrp;
const float hcScale = 1.8;
const vec3 hcSize = vec3 (0.5 * SQRT3, 1., 1.8);
const float pi = 3.14159;

vec3 TrackPath (float t)
{
  return vec3 (dot (trkA, sin (trkF * t)), 0., t);
}

vec3 TrackVel (float t)
{
  return vec3 (dot (trkF * trkA, cos (trkF * t)), 0., 1.);
}

vec2 PixToHex (vec2 p)
{
  vec2 c, r, dr;
  c = vec2 ((2. / SQRT3) * p.x, p.y);
  r = floor (c);
  r += mod (vec2 (r.x, r.y + step (2., mod (r.x + 1., 4.))), 2.);
  dr = c - r;
  r += step (1., 0.5 * dot (abs (dr), vec2 (SQRT3, 1.))) * sign (dr) * vec2 (2., 1.);
  return r;
}

bool HexCellFull (vec3 p)
{
  float hs, hb;
  p = (p * hcSize).yzx / hcScale;
  p.xy -= TrackPath (p.z).xy;
  hs = - SmoothMin (length (p.xy * vec2 (0.9 - 0.35 * cos (p.z * pi / 20.), 0.3)) - 4.,
    6.5 + 4.5 * dot (sin (p * pi / 16. - cos (p.yzx * pi / 12.)), vec3 (1.)) - p.y, 2.);
  return (hs < 0.);
}

float HexVolRay (vec3 ro, vec3 rd)
{
  vec3 ht, htt, w;
  vec2 hv[3], ve;
  float dHit, ty, dy;
  ro *= hcScale;
  cHit = vec3 (PixToHex (ro.zx), floor (ro.y / hcSize.z + 0.5));
  hv[0] = vec2 (0., 1.);
  hv[1] = vec2 (1., 0.5);
  hv[2] = vec2 (1., -0.5);
  for (int k = 0; k < 3; k ++)
     hv[k] *= sign (dot (hv[k], vec2 (0.5 * SQRT3 * rd.z, rd.x)));
  if (rd.y == 0.) rd.y = 0.0001;
  dy = sign (rd.y);
  qnHit = vec3 (0.);
  dHit = dstFar * hcScale + 0.01;
  for (int j = 0; j < 300; j ++) {
    w = ro - (cHit * hcSize).yzx;
    ht.z = 1e6;
    for (int k = 0; k < 3; k ++) {
      ve = vec2 (0.5 * SQRT3 * hv[k].x, hv[k].y);
      htt = vec3 (hv[k], (1. - dot (ve, w.zx)) / dot (ve, rd.zx));
      if (htt.z < ht.z) ht = htt;
    }
    ty = (0.5 * dy * hcSize.z - w.y) / rd.y;
    cHitP = cHit;
    if (ht.z < ty) cHit.xy += 2. * ht.xy;
    else cHit.z += dy;
    if (HexCellFull (cHit)) {
      if (ht.z < ty) {
        qnHit = - vec3 (0.5 * SQRT3 * ht.x, ht.y, 0.);
        dHit = ht.z;
      } else {
        qnHit = - vec3 (0., 0., dy);
        dHit = ty;
      }
      break;
    }
  }
  return dHit / hcScale;
}

float HexFaceDist (vec3 p)
{
  vec4 h[4];
  vec3 cNeb, vh;
  float d;
  p = p.zxy * hcScale - cHitP * hcSize;
  p.z *= 2. / hcSize.z;
  h[0] = vec4 (0., 1., 0., 1.);
  h[1] = vec4 (1., 0.5, 0., 1.);
  h[2] = vec4 (1., -0.5, 0., 1.);
  h[3] = vec4 (0., 0., 0.5, 0.5 * hcSize.z);
  d = 1e5;
  for (int k = 0; k < 4; k ++) {
    vh = h[k].xyz;
    cNeb = cHitP + 2. * vh;
    if (cNeb != cHit && HexCellFull (cNeb))
    d = min (d, h[k].w - dot (vh * hcSize, p));
    cNeb = cHitP - 2. * vh;
    if (cNeb != cHit && HexCellFull (cNeb))
    d = min (d, h[k].w + dot (vh * hcSize, p));
  }
  return d;
}

vec3 HexVolCol (vec3 p, float edgDist, float dHit)
{
  vec3 col;
  col = vec3 (0.9, 0.85, 0.75);
  col *= 0.8 + 0.2 * smoothstep (0., 0.05, abs (edgDist));
  if (qnHit.z != 0.) col *= 0.7 + 0.3 * smoothstep (0., 0.7, abs (edgDist));
  if (qnHit.z == 1.) col *= vec3 (0.4, 0.7, 0.4);
  col *= (1.2 - 0.2 * smoothstep (0., 0.06 * sqrt (dHit), abs (edgDist) - 0.03)) *
     (0.5 + 0.5 * smoothstep (0., 0.03 * sqrt (dHit), abs (edgDist) - 0.01));
  return col;
}

float EdgeDist (vec3 p)
{
  vec2 dh;
  float d;
  p *= hcScale;
  dh = p.zx - cHit.xy * vec2 (0.5 * SQRT3, 1.);
  if (qnHit.z == 0.) {
    d = abs (fract (p.y / hcSize.z) - 0.5) * hcSize.z;
    dh -= qnHit.xy * dot (dh, qnHit.xy);
    d = min (d, abs (length (dh) - 1. / SQRT3));
  } else {
    dh = abs (dh);
    d = max (0.5 * dot (dh, vec2 (SQRT3, 1.)), dh.y) - 1.;
  }
  return d;
}

float BoatDf (vec3 p, float dMin)
{
  vec3 q;
  float d;
  p.y -= 0.7;
  q = p;
  d = max (max (PrRCylDf (q, 1.2, 2., 3.5),
     - max (PrRCylDf (q - vec3 (0., 0.1, 0.), 1.15, 2., 3.5),
     max (q.y - 0.1, - q.y - 0.1))), max (q.y - 0., - q.y - 0.2));
  q.y -= -0.2;
  d = max (SmoothMin (d, max (PrRCylDf (q, 1., 2., 3.3), q.y), 0.1), q.z - 2.);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 1;  qHit = q; }
  q = p;
  q.yz -= vec2 (-0.5, -0.2);
  d = max (PrRCylDf (q, 1., 1.1, 2.3), max (0.4 - q.y, q.z - 1.2));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 2;  qHit = q; }
  q = p;
  q.yz -= vec2 (1.3, -0.6);
  d = PrCylDf (q.xzy, 0.04, 0.8);
  q.y -= 0.2;
  d = min (d, PrCylDf (q.yzx, 0.02, 0.2));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 3; }
  q.y -= 0.6;
  d = PrCylDf (q.xzy, 0.15, 0.02);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 4; }
  q = p;
  q.x = abs (q.x);
  q -= vec3 (0.3, -0.9, 2.);
  d = PrRoundBoxDf (q, vec3 (0.02, 0.2, 0.1), 0.03);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 5; }
  q.y -= -0.4;
  d = PrCylAnDf (q, 0.1, 0.02, 0.2);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 6; }
  q = p;
  q.yz -= vec2 (-1., 2.);
  d = PrCylDf (q, 0.1, 0.2);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 6; }
  q = p;
  q.yz -= vec2 (0.3, 1.9);
  d = PrCylDf (q.xzy, 0.015, 0.5);
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 7; }
  q.yz -= vec2 (0.38, 0.15);
  d = PrBoxDf (q, vec3 (0.01, 0.1, 0.15));
  if (d < dMin) { dMin = d;  idObj = idObjGrp + 8; }
  return dMin;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, dLim;
  const float szFac = 2.;
  dLim = 0.2;
  dMin = dstFar;
  dMin *= szFac;
  for (int k = 0; k < 3; k ++) {
    q = szFac * (p - boatPos[k]);
    idObjGrp = (k + 1) * 256;
    d = PrCylDf (q.xzy, 3.5, 3.);
    dMin = (d < dLim) ? BoatDf (boatMat[k] * q, dMin) : min (dMin, d);
  }
  return dMin / szFac;
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
  const vec3 e = vec3 (0.001, -0.001, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy),
     ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec4 BoatCol (vec3 n)
{
  vec3 col, nn, cc;
  float spec;
  int ig, id;
  ig = idObj / 256;
  id = idObj - 256 * ig;
  if (ig == 1) nn = boatMat[0] * n;
  else if (ig == 2) nn = boatMat[1] * n;
  else nn = boatMat[2] * n;
  spec = 0.3;
  if (id == 1) {
    if (qHit.y < 0.1 && nn.y > 0.99) {
      col = vec3 (0.8, 0.5, 0.3) *
         (1. - 0.4 * SmoothBump (0.42, 0.58, 0.05, mod (7. * qHit.x, 1.)));
      spec = 0.1;
    } else {
      cc = vec3 (0.9, 0.3, 0.3);
      if (qHit.y > -0.2) col = (ig == 1) ? cc :
         ((ig == 2) ? cc.yzx : cc.zxy);
      else col = vec3 (0.7, 0.7, 0.8);
      spec = 0.7;
    }
  } else if (id == 2) {
    if (abs (abs (qHit.x) - 0.24) < 0.22 && abs (qHit.y - 0.7) < 0.15 ||
       abs (abs (qHit.z + 0.2) - 0.5) < 0.4 && abs (qHit.y - 0.7) < 0.15) {
       col = vec3 (0., 0., 0.1);
       spec = 1.;
     } else col = vec3 (1.);
  } else if (id == 3) col = vec3 (1., 1., 1.);
  else if (id == 4) col = vec3 (1., 1., 0.4);
  else if (id == 5) col = vec3 (0.4, 1., 0.4);
  else if (id == 6) col = vec3 (1., 0.2, 0.);
  else if (id == 7) col = vec3 (1., 1., 1.);
  else if (id == 8) col = (ig == 1) ? vec3 (1., 0.4, 0.4) : vec3 (0.4, 1., 0.4);
  return vec4 (col, spec);
}

float WakeFac (vec3 p)
{
  vec3 twa;
  vec2 tw[3];
  float twLen[3], wkFac;
  for (int k = 0; k < 3; k ++) {
    tw[k] = p.xz - (boatPos[k].xz - Rot2D (vec2 (0., 0.12), boatAng[k]));
    twLen[k] = length (tw[k]);
  }
  if (twLen[0] < min (twLen[1], twLen[2])) twa = vec3 (tw[0], boatAng[0]);
  else if (twLen[1] < twLen[2]) twa = vec3 (tw[1], boatAng[1]);
  else twa = vec3 (tw[2], boatAng[2]);
  twa.xy = Rot2D (twa.xy, - twa.z);
  wkFac = clamp (1. - 2.5 * abs (twa.x), 0., 1.) * clamp (1. - 2. * twa.y, 0., 0.2) *
     smoothstep (-5., -2., twa.y);
  return wkFac;
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  vec3 col;
  float sd, f;
  rd.y = abs (rd.y);
  sd = max (dot (rd, sunDir), 0.);
  ro.x += 0.5 * tCur;
  f = Fbm2 (0.05 * (rd.xz * (50. - ro.y) / (rd.y + 0.0001) + ro.xz));
  col = vec3 (0., 0.2, 0.7) + vec3 (1., 1., 0.9) * (0.3 * pow (sd, 32.) +
     0.2 * pow (sd, 512.));
  return mix (col, vec3 (0.9), clamp ((f - 0.05) * rd.y + 0.3, 0., 1.));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, bgCol, vn, row, rdw;
  float dstObj, dstWat, dstBlk, dEdge, diff, h, sh, reflCol, wkFac;
  int idObjT;
  reflCol = 1.;
  dstBlk = HexVolRay (ro, rd);
  dstObj = ObjRay (ro, rd);
  dstWat = - (ro.y + 2.) / rd.y;
  if (rd.y * (min (dstBlk, dstObj) - dstWat) < 0.) {
    ro += dstWat * rd;
    row = ro;
    wkFac = WakeFac (row);
    vn = vec3 (0., 1., 0.);
    if (wkFac > 0.) vn = VaryNf (100. * ro, vec3 (0., 1., 0.), 10. * wkFac);
    else vn = VaryNf (2. * ro, vec3 (0., 1., 0.), 0.2);
    rd = reflect (rd, vn);
    rdw = rd;
    dstBlk = HexVolRay (ro, rd);
    dstObj = ObjRay (ro, rd);
    reflCol = 0.8;
  }
  bgCol = vec3 (0.2, 0.2, 0.3) * (1. + 0.2 * rd.y);
  if (min (dstBlk, dstObj) < dstFar) {
    if (dstBlk < dstObj) {
      ro += rd * dstBlk;
      vn = qnHit.yzx;
      dEdge = EdgeDist (ro);
      h = smoothstep (0., 0.1, HexFaceDist (ro));
      col = HexVolCol (ro, dEdge, dstBlk) * (0.7 + 0.3 * h) *
         (1. - 0.2 * Fbm3 (30. * ro));
      col = mix (vec3 (0., 0.2, 0.), col, 0.5 + 0.5 * smoothstep (-2., -1.8, ro.y));
      vn = VaryNf (5. * ro, vn, 2.);
      diff = max (dot (sunDir, vn), 0.);
      sh = (diff > 0. && HexVolRay (ro + 0.001 * vn, sunDir) < dstFar) ? 0.5 : 1.;
      col = col * (0.2 + sh * (0.1 * max (vn.y, 0.) + 0.8 * diff)) + 0.2 * sh *
         pow (max (dot (normalize (sunDir - rd), vn), 0.), 128.);        
      col = mix (col, bgCol, smoothstep (0.2 * dstFar, 0.85 * dstFar, dstBlk));
    } else {
      ro += rd * dstObj;
      idObjT = idObj;
      vn = ObjNf (ro);
      idObj = idObjT;
      col4 = BoatCol (vn);
      diff = max (dot (sunDir, vn), 0.);
      sh = (diff > 0. && HexVolRay (ro + 0.001 * vn, sunDir) < dstFar) ? 0.5 : 1.;
      col = col4.rgb * (0.3 + 0.7 * sh * diff) +
         col4.a * sh * pow (max (dot (normalize (sunDir - rd), vn), 0.), 128.);
    }
  } else col = SkyCol (ro, rd);
  col *= reflCol;
  if (reflCol < 1. && wkFac > 0.) col = mix (col, vec3 (0.9),
     10. * wkFac * clamp (0.1 + 0.5 * Fbm3 (23. * row), 0., 1.));
  return col;
}

void BoatPM (float t)
{
  vec3 v;
  float c, s, bAz;
  bPos = TrackPath (t);
  bPos.y = -1.9;
  bMat[2] = vec3 (1., 0., 0.);
  bMat[0] = normalize (vec3 (0., 0.1, 1.));
  bMat[1] = cross (bMat[0], bMat[2]);
  v = TrackVel (t);
  bAz = atan (v.z, - v.x);
  bAng = 0.5 * pi - bAz;
  c = cos (bAz);
  s = sin (bAz);
  bMat *= mat3 (c, 0., s, 0., 1., 0., - s, 0., c);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, vd;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, vMov, a;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  trkF = vec3 (0.029, 0.021, 0.016);
  trkA = vec3 (15., 23., 34.);
  vMov = 4.;
  for (int k = 0; k < 3; k ++) {
    BoatPM (vMov * tCur + 8. + 12. * float (k));
    boatPos[k] = bPos;  boatMat[k] = bMat;  boatAng[k] = bAng;
    boatPos[k].y += 0.1 * Fbm1 (5. * float (k) + tCur);
  }
  ro = TrackPath (vMov * tCur);
  ro.y += 0.2;
  vd = TrackVel (vMov * tCur);
  el = 0.;
  az = atan (vd.x, vd.z);
  if (mPtr.z > 0.) {   
    el += 0.7 * pi * mPtr.y;
    az += 2. * pi * mPtr.x;
  }
  ori = vec2 (clamp (el, -0.5 * pi, 0.45 * pi), az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = vuMat * normalize (vec3 (uv, 2.));
  dstFar = 250.;
  a = 0.3 * pi * sin (0.02 * pi * tCur);
  sunDir = normalize (vec3 (sin (a), 3., - cos (a)));
  glFragColor = vec4 (pow (clamp (ShowScene (ro, rd), 0., 1.), vec3 (0.8)), 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCylAnDf (vec3 p, float r, float w, float h)
{
  return max (abs (length (p.xy) - r) - w, abs (p.z) - h);
}

float PrRCylDf (vec3 p, float r, float rt, float h)
{
  vec2 dc;
  float dxy, dz;
  dxy = length (p.xy) - r;
  dz = abs (p.z) - h;
  dc = vec2 (dxy, dz) + rt;
  return min (min (max (dc.x, dz), max (dc.y, dxy)), length (dc) - rt);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
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

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, cHashA3.xy)) * cHashM);
}

vec2 Hashv2f (float p)
{
  return fract (sin (p + cHashA4.xy) * cHashM);
}

vec3 Hashv3f (float p)
{
  return fract (sin (vec3 (p, p + 1., p + 2.)) *
     vec3 (cHashM, cHashM * 0.43, cHashM * 0.37));
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
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
  vec4 t;
  vec2 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv4f (dot (ip, cHashA3.xy));
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
}

float Noisefv3 (vec3 p)
{
  vec4 t1, t2;
  vec3 ip, fp;
  float q;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  q = dot (ip, cHashA3);
  t1 = Hashv4f (q);
  t2 = Hashv4f (q + cHashA3.z);
  return mix (mix (mix (t1.x, t1.y, fp.x), mix (t1.z, t1.w, fp.x), fp.y),
              mix (mix (t2.x, t2.y, fp.x), mix (t2.z, t2.w, fp.x), fp.y), fp.z);
}

float Fbm1 (float p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
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
    p = 2. * p.yzx;
  }
  return f * (1. / 1.9375);
}

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  const vec3 e = vec3 (0.1, 0., 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) -
     Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
