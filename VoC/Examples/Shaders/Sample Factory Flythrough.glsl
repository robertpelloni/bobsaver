#version 420

// original https://www.shadertoy.com/view/4ttSWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Factory Flythrough" by dr2 - 2016
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  Building model based on imaginative "Industrial Complex" by Shane; use
  mouse to look around.
*/

const float pi = 3.14159;

float PrSphDf (vec3 p, float s);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
float PrRCylDf (vec3 p, float r, float rt, float h);
float PrRoundBoxDf (vec3 p, vec3 b, float r);
vec2 Rot2D (vec2 q, float a);
float Fbm1 (float p);
float Fbm3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 dronePos, ltPos, ltAx;
vec2 aTilt;
float tCur, dstFar, bumpShd=0.0;
int idObj=0;
const int idBase = 1, idWall = 2, idFlCl = 3, idCyl = 4, idCol = 5, idRail = 6,
   idWire = 7, idLt = 8, idDrBod = 11, idDrLamp = 12, idDrCam = 13;

vec3 TrackPath (float t)
{
   return vec3 (cos (2. * t * pi / 64.) * 5.5, cos (0.5 * 2. * t * pi / 64.), t);
}

float DroneDf (vec3 p, float dMin)
{
  vec3 q, qq;
  float d;
  const float dSzFac = 6.;
  dMin *= dSzFac;
  qq = dSzFac * (p - dronePos);
  qq.yz = Rot2D (qq.yz, - aTilt.y);
  qq.yx = Rot2D (qq.yx, - aTilt.x);
  q = qq;
  q.y -= 0.05;
  d = PrRCylDf (q.xzy, 0.2, 0.03, 0.07);
  if (d < dMin) { dMin = d;  idObj = idDrBod; }
  q.y -= 0.07;
  d = PrRoundBoxDf (q, vec3 (0.06, 0.02, 0.12), 0.04);
  if (d < dMin) { dMin = d;  idObj = idDrLamp; }
  q = qq;
  q.y -= -0.05;
  d = PrSphDf (q, 0.17);
  if (d < dMin) { dMin = d;  idObj = idDrCam; }
  q = qq;
  q.xz = abs (q.xz) - 0.7;
  d = min (PrCylAnDf (q.xzy, 0.5, 0.05, 0.05), PrCylDf (q.xzy, 0.1, 0.03));
  q -= vec3 (-0.4, -0.15, -0.4);
  d = min (d, PrRCylDf (q.xzy, 0.05, 0.03, 0.2));
  q -= vec3 (-0.3, 0.2, -0.3);
  q.xz = Rot2D (q.xz, 0.25 * pi);
  d = min (d, min (PrRCylDf (q, 0.05, 0.02, 1.), PrRCylDf (q.zyx, 0.05, 0.02, 1.)));
  if (d < dMin) { dMin = d;  idObj = idDrBod; }
  return dMin / dSzFac;
}

float ObjDf (vec3 p)
{
  vec3 w, q, qq;
  float dMin, d, dm, dc;
  dMin = dstFar;
  w = vec3 (16., 8., 16.);
  q = abs (mod (p + vec3 (4., 0., 0.), 2. * w) - w);
  w = vec3 (16., 1., 8.);
  qq = abs (mod (p, 2. * w) - w);
  d = max (p.y + 3.5, 8. - max (qq.x + 0.35, q.z));
  if (d < dMin) { dMin = d;  idObj = idBase; }
  d = max (max (qq.x - 8., qq.z - 2.15),
     min (1.75 - abs (abs (qq.x - 8.) - 4.), 0.5 - abs (q.y - 8.)));
  if (d < dMin) { dMin = d;  idObj = idWall; }
  dm = 2.85 - min (max (2.1 - p.y, q.z - 2.), abs (mod (p.z + 16., 32.) - 16.));
  qq.x = abs (qq.x - 8.);
  d = max (dm, min (max (qq.x, qq.y), max (qq.x, abs (mod (qq.z, 2.) - 1.))) - 0.15);
  if (d < dMin) { dMin = d;  idObj = idRail; }
  qq.y = abs (mod (qq.y + 0.1667, 0.333) - 0.1667);
  d = max (dm, max (length (qq.xy) - 0.025, - p.y - 3.));
  if (d < dMin) { dMin = d;  idObj = idWire; }
  q.xz = abs (q.xz - vec2 (8.));
  q.x = abs (q.x - 4.);
  qq = abs (mod (q, 2.) - 1.);
  dm = min (qq.x, min (qq.y, qq.z));
  dc = max (max (q.x, q.y) - 3., - p.y);
  d = max (dm, min (dc, max (q.y, q.z) * 0.55 + length (q.yz) * 0.45 - 5.1)) - 0.15;
  if (d < dMin) { dMin = d;  idObj = idFlCl; }
  d = max (dm, min (dc, max (q.x, q.z) - 2.)) - 0.15;
  if (d < dMin)  { dMin = d;  idObj = idCol; }
  d = length (vec2 (q.xz) * vec2 (0.7, 0.4)) - 1.;
  if (d < dMin) { dMin = d;  idObj = idCyl; }
  w = vec3 (16., 8., 8.);
  qq = mod (p + vec3 (16., 0., 0.), 2. * w) - w;
  qq.xz = abs (qq.xz);
  qq.x = abs (qq.x - 4.);
  qq.y += 5.2;
  d = PrCylDf (qq.xzy, 0.3, 0.1);
  if (d < dMin) { dMin = d;  idObj = idLt; }
  dMin = DroneDf (p, dMin);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 80; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

float MengFun (vec3 p)
{
  vec3 q, qm;
  float s, d, dd;
  s = 16.;
  p *= 4.;
  q = abs (mod (p, s) - 0.5 * s);
  qm = max (q.yzx, q.zxy);
  d = max (0., min (qm.x, min (qm.y, qm.z)) - s / 3. + 1.);
  s /= 3.;
  q = abs (mod (p, s) - 0.5 * s);
  qm = max (q.yzx, q.zxy);
  d = max (d, min (qm.x, min (qm.y, qm.z)) - s / 3.);
  s /= 3.;
  q = abs (mod (p, s) - 0.5 * s);
  qm = max (q.yzx, q.zxy);
  dd = min (qm.x, min (qm.y, qm.z)) - s / 3.;
  bumpShd = step (d, dd);
  d = min (abs (max (d, dd)) * 1.6, 1.);
  return d;
}

vec3 MengSurf (vec3 p, vec3 n, float f)
{
  vec3 g;
  vec2 e = vec2 (0.001, 0);
  g = vec3 (MengFun (p + e.xyy), MengFun (p + e.yxy), MengFun (p + e.yyx)) -
     MengFun (p);
  return normalize (n + f * (g - n * dot (n, g)));
}

float TileFun (vec2 p)
{
  p = abs (fract (4. * p) - 0.5);
  return smoothstep (0., 0.3, max (p.x, p.y));
}

vec3 TileFloor (vec3 p, float f)
{
  vec2 g;
  vec2 e = vec2 (0.001, 0);
  g = f * (vec2 (TileFun (p.xz + e.xy), TileFun (p.xz + e.yx)) - TileFun (p.xz));
  return normalize (vec3 (g.x, 1., g.y));
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec3 e = vec3 (0.001, -0.001, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

vec4 DroneCol ()
{
  vec4 objCol;
  if (idObj == idDrBod) objCol = vec4 (0.2, 0.9, 0.2, 1.);
  else if (idObj == idDrLamp) objCol = mix (vec4 (0.3, 0.3, 1., -2.),
     vec4 (2., 0., 0., 0.2), step (0., sin (10. * tCur)));
  else if (idObj == idDrCam) objCol = vec4 (0.1, 0.1, 0.1, 1.);
  return objCol;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, ltDir;
  vec2 pb;
  float dHit, f, ltDist, atten, brt;
  int idObjT;
  dHit = ObjRay (ro, rd);
  if (dHit < dstFar) {
    ro += rd * dHit;
    idObjT = idObj;
    vn = ObjNf (ro);
    idObj = idObjT;
    ltDir = ltPos - ro;
    ltDist = length (ltDir);
    ltDir /= ltDist;
    atten = 1.2 * smoothstep (0.55, 0.65, dot (ltAx, - ltDir)) /
       pow (max (ltDist, 1.), 1.2);
    pb = abs (mod (ro.xz + vec2 (16., 0.), 2. * vec2 (16., 8.)) - vec2 (16., 8.));
    pb.x = abs (pb.x - 4.);
    brt = (ro.y < 2. && length (pb) < 0.7) ? 0.2 : 0.;
    if (idObj == idLt) {
      col = vec3 (1., 1., 0.3) * (0.9 - 0.1 * vn.y);
    } else if (idObj >= idDrBod) {
      col4 = DroneCol ();
      col = col4.xyz;
      if (col4.a >= 0.)
        col = col * (0.2 + 0.8 * atten * max (dot (ltDir, vn), 0.)) +
           atten * pow (max (dot (reflect (rd, vn), ltDir), 0.), 64.);
    } else {
      if (idObj == idBase) vn = TileFloor (ro, 150.);
      else if (idObj != idRail && idObj != idWire)
         vn = MengSurf (ro, vn, 150.);
      if (idObj != idWire) {
        vn = VaryNf (32. * ro, vn, 3.);
        col = 1.5 * mix (vec3 (0.1, 0.2, 0.25), vec3 (0.2, 0.1, 0.05),
           Fbm3 (3. * ro));
      } else col = vec3 (0.5, 0.5, 0.6);
      if (idObj == idBase) col *= TileFun (ro.xz);
      else if (bumpShd > 0.) col *= 0.7;
      col = col * (0.2 + 10. * atten * max (dot (ltDir, vn), 0.)) +
         2. * atten * pow (max (dot (reflect (rd, vn), ltDir), 0.), 32.);
      col = mix (col, vec3 (1., 1., 0.5), brt);
      col = mix (col, vec3 (0.6, 0., 0.) * (0.3 + 0.7 * Fbm1 (5. * tCur)),
         1. - smoothstep (-10., -4.2, ro.y));
    }
  } else col = vec3 (0.);
  f = dHit / dstFar;
  col = mix (col, 0.3 * vec3 (0.7, 0.9, 1.), smoothstep (0.4, 1., f * f));
  return col;
}

void main(void)
{
  mat3 vuMat;
  vec2 mPtr;
  vec3 ro, rd, vd;
  vec2 canvas, uv, ori, ca, sa, aa;
  float el, az, t;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = mouse.xy*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  t = 4. * tCur;
  ro = TrackPath (t);
  ltPos = ro;
  ltPos.y += 0.1;
  dronePos = TrackPath (t + 1.);
  aTilt = vec2 (6. * (TrackPath (t + 1.1).x - dronePos.x), 0.2);
  vd = normalize (TrackPath (t + 0.1) - ro);
  az = 1.2 * (0.5 * pi + atan (- vd.z, vd.x));
  el = 0.;
  //if (mPtr.z > 0.) {
  //  az += 2.1 * pi * mPtr.x;
  //  el += pi * mPtr.y;
  //}
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  aa = atan (uv / 1.2);
  rd = vuMat * normalize (vec3 (1.5 * sin (aa) / (0.5 + cos (aa)), 1.));
  ltAx = vuMat * vec3 (0., 0., 1.);
  dstFar = 80.;
  glFragColor = vec4 (pow (clamp (ShowScene (ro, rd), 0., 1.), vec3 (0.8)), 1.0);
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

float PrRCylDf (vec3 p, float r, float rt, float h)
{
  vec2 dc;
  float dxy, dz;
  dxy = length (p.xy) - r;
  dz = abs (p.z) - h;
  dc = vec2 (dxy, dz) + rt;
  return min (min (max (dc.x, dz), max (dc.y, dxy)), length (dc) - rt);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec2 Hashv2f (float p)
{
  return fract (sin (p + cHashA4.xy) * cHashM);
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
  float s;
  const vec3 e = vec3 (0.1, 0., 0.);
  s = Fbmn (p, n);
  g = vec3 (Fbmn (p + e.xyy, n) - s, Fbmn (p + e.yxy, n) - s,
     Fbmn (p + e.yyx, n) - s);
  return normalize (n + f * (g - n * dot (n, g)));
}
