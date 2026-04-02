#version 420

// original https://www.shadertoy.com/view/lscBRB

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Ozymandias Redux" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  0   // optional antialiasing

float PrSphDf (vec3 p, float r);
float PrRoundCylDf (vec3 p, float r, float rt, float h);
float Minv3 (vec3 p);
vec2 Rot2D (vec2 q, float a);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
mat3 QtToRMat (vec4 q);
vec4 EulToQt (vec3 e);
vec4 Hashv4v2 (vec2 p);
float Noisefv2 (vec2 p);
float Fbm2 (vec2 p);
float Fbm2s (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

mat3 orMat;
vec4 dateCur;
vec3 sunDir, qHit, rPos;
vec2 gId;
float tCur, dstFar, hgSize, rAngA, gFac, hFac, fWav, aWav, szFac;
int idObj;
const float pi = 3.14159, sqrt3 = 1.732051;

float GrndHt (vec2 p)
{
  mat2 qRot;
  vec2 q;
  float f, wAmp;
  qRot = mat2 (0.8, -0.6, 0.6, 0.8) * fWav;
  q = gFac * p;
  wAmp = 4. * hFac;
  f = 0.;
  for (int j = 0; j < 4; j ++) {
    f += wAmp * Noisefv2 (q);
    wAmp *= aWav;
    q *= qRot;
  }
  return f;
}

float GrndRay (vec3 ro, vec3 rd, float dstMax)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = 0; j < 120; j ++) {
    p = ro + s * rd;
    h = p.y - GrndHt (p.xz);
    if (h < 0. || s > dstMax) break;
    sLo = s;
    s += max (0.5, 0.8 * h);
  }
  if (h < 0.) {
    sHi = s;
    for (int j = 0; j < 5; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      if (p.y > GrndHt (p.xz)) sLo = s;
      else sHi = s;
    }
    dHit = 0.5 * (sLo + sHi);
  }
  return dHit;
}

vec3 GrndNf (vec3 p)
{
  vec2 e = vec2 (0.01, 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy),
     GrndHt (p.xz + e.yx)), e.x).xzy);
}

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  p.xz -= HexToPix (gId * hgSize);
  p -= rPos;
  p = orMat * p;
  p /= szFac;
  dMin /= szFac;
  p.yz = p.zy;
  p.z -= -1.6;
  q = p;  q.z -= 2.3;
  d = max (PrSphDf (q, 0.85), - q.z - 0.2);
  q = p;  q.z -= 1.55;
  d = min (d, PrRoundCylDf (q, 0.9, 0.28, 0.7));
  DMINQ (1);
  q = p;  q.y = abs (q.y) - 0.3;  q.z -= 3.1;
  q.yz = Rot2D (q.yz, 0.2 * pi);
  q.z -= 0.25;
  d = PrRoundCylDf (q, 0.06, 0.04, 0.3);
  DMINQ (1);
  q = p;  q.y = abs (q.y) - 1.08;  q.z -= 2.;
  q.zx = Rot2D (q.zx, rAngA);
  q.z -= -0.5;
  d = PrRoundCylDf (q, 0.2, 0.15, 0.6);
  DMINQ (1);
  q = p;  q.y = abs (q.y) - 0.4;  q.z -= 0.475;
  d = PrRoundCylDf (q, 0.25, 0.15, 0.55);
  DMINQ (1);
  q = p;  q.y = abs (q.y) - 0.4;  q.zx -= vec2 (2.7, 0.7);
  d = PrSphDf (q, 0.15);
  DMINQ (2);
  dMin *= szFac;
  return dMin;
}

void SetGrdConf ()
{
  vec4 h4;
  float a, phi, theta, psi;
  h4 = Hashv4v2 (17.1 * gId + 0.3);
  a = smoothstep (-0.7, 0.7, 2. * h4.x - 1.);
  psi = pi * (a - 0.5);
  a = h4.y - 0.5;
  theta = 0.2 * pi * tCur * max (0.2, abs (a)) * sign (a);
  phi = 0.5 * pi * (2. * step (0.5, h4.z) - 1.);
  orMat = QtToRMat (EulToQt (vec3 (phi, theta, psi)));
  rAngA = pi * h4.w;
  a = 2. * pi * (h4.x + h4.y);
  rPos.xz = 0.5 * hgSize * sin (a + vec2 (0.5 * pi, 0.));
  szFac = 1.2 - 0.2 * (h4.z + h4.w);
  rPos.y = GrndHt (HexToPix (gId * hgSize) + rPos.xz) + 0.1 * sign (phi) * sign (psi);
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM, gIdP;
  float dHit, d, s;
  if (rd.x == 0.) rd.x = 0.0001;
  if (rd.y == 0.) rd.y = 0.0001;
  if (rd.z == 0.) rd.z = 0.0001;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSize / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]),
     dot (ro.xz, edN[2])) / hgSize;
  pM = HexToPix (PixToHex (ro.xz / hgSize));
  hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
  s = Minv3 (hv);
  gIdP = vec2 (-999.);
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
    p = ro + dHit * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId.x != gIdP.x || gId.y != gIdP.y) {
      gIdP = gId;
      SetGrdConf ();
    }
    d = ObjDf (p);
    if (dHit + d < s) dHit += d;
    else {
      dHit = s + 0.001;
      pM += sqrt3 * ((s == hv.x) ? edN[0] : ((s == hv.y) ? edN[1] : edN[2]));
      hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
      s = Minv3 (hv);
    }
    if (d < 0.0005 || dHit > dstFar || p.y < 0.) break;
  }
  if (d >= 0.0005) dHit = dstFar;
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0001, -0.0001);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 gIdP;
  float sh, d, h;
  sh = 1.;
  gIdP = vec2 (-999.);
  d = 0.03;
  for (int j = 0; j < 24; j ++) {
    p = ro + d * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId.x != gIdP.x || gId.y != gIdP.y) {
      gIdP = gId;
      SetGrdConf ();
    }
    h = ObjDf (p);
    sh = min (sh, smoothstep (0., 0.03 * d, h));
    d += min (0.05, 3. * h);
    if (h < 0.005) break;
  }
  return 0.6 + 0.4 * sh;
}

float RippleHt (vec2 p)
{
  vec2 q;
  float s1, s2;
  q = Rot2D (p, -0.02 * pi);
  s1 = abs (sin (4. * pi * abs (q.y + 1.5 * Fbm2s (0.7 * q))));
  s1 = (1. - s1) * (s1 + sqrt (1. - s1 * s1));
  q = Rot2D (p, 0.01 * pi);
  s2 = abs (sin (3.1 * pi * abs (q.y + 1.9 * Fbm2s (0.5 * q))));
  s2 = (1. - s2) * (s2 + sqrt (1. - s2 * s2));
  return mix (s1, s2, 0.1 + 0.8 * smoothstep (0.3, 0.7, Fbm2 (2. * p)));
}

vec4 RippleNorm (vec2 p, vec3 vn, float f)
{
  vec2 e = vec2 (0.002, 0.);
  float h;
  h = RippleHt (p);
  vn.xy = Rot2D (vn.xy, f * (RippleHt (p + e) - h));
  vn.zy = Rot2D (vn.zy, f * (RippleHt (p + e.yx) - h));
  return vec4 (vn, h);
}

vec3 SkyBg (vec3 rd)
{
  return mix (vec3 (0.2, 0.3, 0.7), vec3 (0.45, 0.45, 0.5), pow (1. - max (rd.y, 0.), 8.));
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  float sd, f;
  ro.x -= tCur;
  sd = max (dot (rd, sunDir), 0.);
  f = Fbm2s (0.1 * (ro + rd * (100. - ro.y) / (rd.y + 0.0001)).xz);
  return mix (SkyBg (rd) + vec3 (1., 1., 0.9) * (0.3 * pow (sd, 32.) + 0.2 * pow (sd, 512.)),
     vec3 (1., 1., 0.95) * (1. - 0.1 * smoothstep (0.8, 0.95, f)), clamp (0.9 * f * rd.y, 0., 1.));
}

float ObjGrndMix (vec3 p)
{
  gId = PixToHex (p.xz / hgSize);
  SetGrdConf ();
  return smoothstep (1., 1.3, length (p.xz - HexToPix (gId * hgSize) - rPos.xz) / szFac);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 vn4;
  vec3 col, vn;
  float dstGrnd, dstObj, sh, spec, f, dFac;
  bool isBg;
  dstObj = ObjRay (ro, rd);
  dstGrnd = GrndRay (ro, rd, dstObj);
  if (min (dstObj, dstGrnd) < dstFar) {
    dFac = 1. - smoothstep (0.15, 0.35, min (dstObj, dstGrnd) / dstFar);
    if (dstObj < dstGrnd) {
      ro += dstObj * rd;
      gId = PixToHex (ro.xz / hgSize);
      vn = ObjNf (ro);
      if (idObj == 1) vn = VaryNf (8. * qHit.xzy, orMat * vn, 4. * dFac) * orMat;
      col = vec3 (0.7, 0.75, 0.8);
      spec = (idObj == 2) ? 0.2 : 0.05;
      sh = 1.;
    } else {
      ro += dstGrnd * rd;
      vn = GrndNf (ro);
      col = mix (vec3 (0.65, 0.45, 0.1), vec3 (0.9, 0.7, 0.4), smoothstep (1., 3., ro.y));
      col *= 1. - 0.3 * dFac * Fbm2s (128. * ro.xz);
      if (dFac > 0. && vn.y > 0.85) {
        f = smoothstep (0.5, 2., ro.y) * smoothstep (0.85, 0.9, vn.y) * dFac;
        vn4 = RippleNorm (ro.xz, vn, 8. * f * (1. - smoothstep (-0.4, -0.2, dot (rd, vn))));
        vn = vn4.xyz;
        col *= mix (1., 0.9 + 0.1 * smoothstep (0.1, 0.3, vn4.w), f);
      }
      if (dFac > 0.) {
        f = ObjGrndMix (ro);
        vn = VaryNf (8. * ro, vn, dFac * (3. - 2. * f));
        col *= 0.8 + 0.2 * f;
      }
      spec = 0.01;
      sh = ObjSShadow (ro, sunDir);
    }
    sh = min (sh, 1. - 0.5 * smoothstep (0.3, 0.7, Fbm2s (0.05 * ro.xz - tCur * vec2 (0.15, 0.))));
    col *= 0.2 + sh * (0.1 * vn.y + 0.7 * max (0., dot (vn, sunDir)) +
       0.1 * max (0., dot (vn, normalize (vec3 (- sunDir.xz, 0.)).xzy)) +
       spec * pow (max (0., dot (sunDir, reflect (rd, vn))), 32.));
    col *= 0.7 + 0.3 * dFac;
    col = mix (col, SkyBg (rd), pow (min (dstObj, dstGrnd) / dstFar, 4.));
  } else col = SkyCol (ro, rd);
  return clamp (col, 0., 1.);
}

mat3 EvalOri (vec3 v, vec3 a)
{
  vec3 w;
  vec2 cs;
  v = normalize (v);
  cs = sin (clamp (2. * (v.z * a.x - v.x * a.z), -0.2 * pi, 0.2 * pi) + vec2 (0.5 * pi, 0.));
  w = normalize (vec3 (v.z, 0., - v.x));
  return mat3 (w, cross (v, w), v) * mat3 (cs.x, - cs.y, 0., cs.y, cs.x, 0., 0., 0., 1.);
}

vec3 TrackPath (float t)
{
  return vec3 (20. * sin (0.07 * t) * sin (0.022 * t) * cos (0.018 * t) +
     13. * sin (0.0061 * t), 0., t);
}

void main(void)
{
  mat3 flMat, vuMat;
  vec4 mPtr, dateCur;
  vec3 ro, rd, col, fpF, fpB;
  vec2 canvas, uv, uvv, ori, ca, sa;
  float el, az, sunEl, sunAz, dt, flyVel, mvTot, hSum, nhSum;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  dateCur = date;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / resolution.xy - 0.5;
  tCur = mod (tCur + 30., 36000.) + 30. * floor (dateCur.w / 7200.);
  az = 0.;
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.6 * pi * mPtr.y;
  }
  hgSize = 10.;
  gFac = 0.07;
  hFac = 1.3;
  fWav = 1.9;
  aWav = 0.45;
  flyVel = 3.;
  dstFar = 150.;
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  mvTot = flyVel * tCur;
  ro = TrackPath (mvTot);
  dt = 1.;
  fpF = TrackPath (mvTot + dt);
  fpB = TrackPath (mvTot - dt);
  flMat = EvalOri ((fpF - fpB) / (2. * dt), (fpF - 2. * ro + fpB) / (dt * dt));
  hSum = 0.;
  nhSum = 0.;
  for (float fk = -1.; fk <= 5.; fk ++) {
    hSum += GrndHt (TrackPath (mvTot + 0.5 * fk).xz);
    ++ nhSum;
  }
  ro.y = 8. * hFac + hSum / nhSum;
  sunAz = 0.01 * 2. * pi * tCur;
  sunEl = pi * (0.25 + 0.1 * sin (0.35 * sunAz));
  sunDir = vec3 (cos (sunAz) * cos (sunEl), sin (sunEl), sin (sunAz) * cos (sunEl));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    uvv = uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.), 0.5 * pi * (a + 0.5));
    rd = normalize (vec3 (uvv, 2.5));
    rd = vuMat * rd;
    rd = flMat * rd;
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrRoundCylDf (vec3 p, float r, float rt, float h)
{
  float dxy, dz;
  dxy = length (p.xy) - r;
  dz = abs (p.z) - h;
  return min (min (max (dxy + rt, dz), max (dxy, dz + rt)), length (vec2 (dxy, dz) + rt) - rt);
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
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

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

mat3 QtToRMat (vec4 q) 
{
  mat3 m;
  float a1, a2, s;
  q = normalize (q);
  s = q.w * q.w - 0.5;
  m[0][0] = q.x * q.x + s;  m[1][1] = q.y * q.y + s;  m[2][2] = q.z * q.z + s;
  a1 = q.x * q.y;  a2 = q.z * q.w;  m[0][1] = a1 + a2;  m[1][0] = a1 - a2;
  a1 = q.x * q.z;  a2 = q.y * q.w;  m[2][0] = a1 + a2;  m[0][2] = a1 - a2;
  a1 = q.y * q.z;  a2 = q.x * q.w;  m[1][2] = a1 + a2;  m[2][1] = a1 - a2;
  return 2. * m;
}

vec4 EulToQt (vec3 e)
{
  float a1, a2, a3, c1, s1;
  a1 = 0.5 * e.y;  a2 = 0.5 * (e.x - e.z);  a3 = 0.5 * (e.x + e.z);
  s1 = sin (a1);  c1 = cos (a1);
  return normalize (vec4 (s1 * cos (a2), s1 * sin (a2), c1 * sin (a3),
     c1 * cos (a3)));
}

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

vec4 Hashv4v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p, cHashVA2), dot (p + e.xy, cHashVA2),
     dot (p + e.yx, cHashVA2), dot (p + e.xx, cHashVA2))) * cHashM);
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

float Fbm2s (vec2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 3; i ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.75);
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
