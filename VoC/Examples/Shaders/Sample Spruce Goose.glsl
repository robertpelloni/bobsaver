#version 420

// original https://www.shadertoy.com/view/fdy3DW

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Spruce Goose" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  0   // (= 0/1) optional antialiasing

#if 0
#define VAR_ZERO min (frames, 0)
#else
#define VAR_ZERO 0
#endif

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrBox2Df (vec2 p, vec2 b);
float PrRoundBox2Df (vec2 p, vec2 b, float r);
float PrCylDf (vec3 p, float r, float h);
float PrCapsDf (vec3 p, float r, float h);
float PrCaps2Df (vec2 p, float r, float h);
float SmoothMin (float a, float b, float r);
float SmoothMax (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
mat3 DirVuMat (vec3 vd);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
vec2 Noisev2v4 (vec4 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 sunDir, qHit, flyPos, flyVel;
float tCur, dstFar, flyRol, wkFac;
int idObj;
const int idFus = 1, idCkp = 2, idEng = 3, idHul = 4, idWngM = 5, idWngT = 6, idTail = 7,
   idFlt = 8, idLeg = 9, idAnt = 10;
const float pi = 3.1415927;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, wsp, wcr, s, w, t, dy;
  dMin = dstFar;
  p -= flyPos;
  p.xy = Rot2D (p.xy, flyRol);
  q = p;
  w = 1.;
  dy = 0.;
  if (q.z < -1.5) {
    s = q.z + 1.5;
    s *= s;
    w *= 1. - 0.025 * s;
    dy = 0.02 * s;
  } else if (q.z > 3.5) {
    s = q.z - 3.5;
    s *= s;
    w *= 1. - 0.04 * s;
    dy = -0.02 * s;
  }
  d = PrCapsDf (q - vec3 (0., dy, 0.), w, 7.);
  DMINQ (idFus);
  q = p;
  q.yz -= vec2 (0.4, 3.7);
  d = PrCapsDf (q, 0.6, 1.5);
  DMINQ (idCkp);
  wsp = 5.;
  wcr = 1.4;
  q = p;
  q.x = abs (q.x);
  t = wcr * (1. - 0.25 * q.x / wsp);
  q -= vec3 (wsp, 0.8, 1.);
  s = (q.z - 0.3) / wcr;
  d = min (wsp - q.x, abs (PrBox2Df (vec2 (abs (q.x - 0.45) - 2.15, q.z - 0.065 * q.x + 1.),
     vec2 (2., 0.2))));
  d = SmoothMax (PrCaps2Df (q.yz, 0.12 * (t - s * s), t), - d, 0.05);
  DMINQ (idWngM);
  wsp = 2.4;
  wcr = 0.65;
  q = p;
  q.x = abs (q.x);
  t = wcr * (1. - 0.25 * q.x / wsp);
  q -= vec3 (0., 1.4, -6.2);
  s = (q.z - 0.1) / wcr;
  d = min (wsp - q.x, abs (PrBox2Df (vec2 (q.x - 1.4, q.z - 0.03 * q.x + 0.35),
     vec2 (0.8, 0.15))));
  d = SmoothMax (PrCaps2Df (q.yz, 0.12 * (t - s * s), t), - d, 0.05);
  DMINQ (idWngT);
  wsp = 1.3;
  wcr = 1.;
  q = p;
  t = wcr * (1. - 0.25 * q.y / wsp);
  q.yz -= vec2 (1.6, -6.3);
  s = (q.z + 0.2 * q.y / wsp - 0.1) / wcr;
  d = min (wsp - abs (q.y), abs (PrBox2Df (vec2 (q.y - 0.25, q.z + (0.2 / wsp - 0.19) * q.y + 0.57),
     vec2 (0.75, 0.17))));
  d = SmoothMax (PrCaps2Df (vec2 (q.x, q.z + 0.2 * q.y / wsp), 0.12 * (t - s * s), t), - d, 0.05);
  DMINQ (idTail);
  q = p;
  q.x = abs (abs (abs (q.x) - 3.5) - 1.2);
  q -= vec3 (0.6, 0.8, 2.1);
  w = 0.2 * (1. - 0.5 * q.z * q.z);
  d = min (max (PrCapsDf (q, w, 0.9), q.z - 0.5), PrCapsDf (q, 0.13, 0.55));
  DMINQ (idEng);
  q = p;
  q.yz -= vec2 (-0.8, 4.);
  w = 0.55;
  t = 0.3;
  s = q.z * q.z;
  if (q.z > 0.) {
    w *= 1. - 0.1 * s;
    q.y -= 0.025 * s;
    t -= 0.05 * s;
  } else {
    w *= 1. - 0.01 * s;
  }
  w *= 1. + q.y;
  d = PrRoundBoxDf (q, vec3 (w, t, 5.5 + 0.1 * q.y), 0.1);
  DMINQ (idHul);
  q = p;
  q.x = abs (q.x);
  q.xz -= vec2 (6.5, 1.1);
  q.z = dot (vec2 (abs (q.z) - 0.3, q.y), sin (0.03 * pi * sign (q.z) + vec2 (0.5 * pi, 0.)));
  d = max (PrCaps2Df (q.xz, 0.03, 0.12), abs (q.y) - 0.75);
  DMINQ (idLeg);
  q.yz -= vec2 (-0.83, 0.1);
  d = max (PrCapsDf (q, 0.25, 0.5), q.y - 0.13);
  DMINQ (idFlt);
  q = p;
  q.x = abs (q.x);
  q -= vec3 (0.1, 1.1, 3.);
  d = PrCapsDf (q.xzy, 0.03, 0.15);
  DMINQ (idAnt);
  return 0.6 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 220; j ++) {
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
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float TrObjDf (vec3 p)
{
  vec3 q;
  float d;
  p -= flyPos;
  p.xy = Rot2D (p.xy, flyRol);
  q = p;
  q.x = abs (abs (abs (q.x) - 3.5) - 1.2);
  q -= vec3 (0.6, 0.8, 2.65);
  d = PrCylDf (q, 0.55, 0.02);
  qHit = q;
  return d;
}

float TrObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 60; j ++) {
    d = TrObjDf (ro + dHit * rd);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec4 FlyerCol ()
{
  vec4 col4, gCol4;
  float s;
  col4 = vec4 (0.9, 0.9, 0.95, 0.2);
  gCol4 = vec4 (0.9, 0.5, 0.2, 0.2);
  if (idObj == idFus) {
    col4 *= 0.7 + 0.3 * smoothstep (0., 0.025, abs (PrRoundBox2Df (vec2 (qHit.y - 0.2,
       abs (qHit.z - 1.) - 2.5), vec2 (0.35, 0.12), 0.05)));
    if (PrRoundBox2Df (vec2 (qHit.y - 0.3, mod (qHit.z + 0.5, 1.) - 0.5),
       vec2 (0.15, 0.08), 0.05) < 0. && abs (qHit.z) < 4.5) col4 = vec4 (0., 0., 0., -2.);
    col4 = mix (gCol4, col4, smoothstep (0., 0.025, abs (abs (qHit.y + 0.4) - 0.04)));
  } else if (idObj == idCkp) {
    if (qHit.z > 0.5 && qHit.y < 0.53 && abs (abs (qHit.x) - 0.2) > 0.03 &&
       abs (abs (qHit.z - 1.25) - 0.25) > 0.03) col4 = vec4 (0., 0., 0., -2.);
  } else if (idObj == idWngM) {
    col4 = mix (gCol4, col4, smoothstep (0., 0.025,
       abs (abs (length (vec2 (qHit.x - 2., qHit.z - 0.1)) - 0.4) - 0.1) - 0.02));
    if (length (vec2 (abs (qHit.x - 5.), qHit.z - 0.8)) < 0.1) col4 = vec4 (0.8, 0., 0., -1.);
  } else if (idObj == idTail) {
    col4 = mix (gCol4, col4, smoothstep (0., 0.025,
       abs (abs (length (vec2 (qHit.y - 0.5, qHit.z - 0.05)) - 0.2) - 0.05) - 0.02));
    if (length (vec2 (qHit.y - 1.3, qHit.z + 0.65)) < 0.12) col4 = vec4 (0.9, 0.9, 0.3, -1.);       
  } else if (idObj == idEng) {
     col4 *= 0.7 + 0.3 * smoothstep (0., 0.025, abs (qHit.z - 0.35) - 0.03);
     col4 = mix (col4, gCol4, step (0.52, qHit.z));
  } else if (idObj == idHul || idObj == idFlt) {
    col4 *= 0.93 + 0.07 * sin (128. * sin (qHit.y));
  } else if (idObj == idLeg) {
    col4 = mix (gCol4, col4, smoothstep (0., 0.025, abs (qHit.z) - 0.01));
  }
  return col4;
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.01;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

float WaveHt (vec2 p, float d)
{
  mat2 qRot;
  vec4 t4, v4;
  vec2 q, t, tw, cs;
  float wFreq, wAmp, h;
  h = 0.;
  if (d < 0.3 * dstFar) {
    qRot = mat2 (0.8, -0.6, 0.6, 0.8);
    wFreq = 0.4;
    wAmp = 0.1;
    tw = 0.5 * tCur * vec2 (1., -1.);
    q = p;
    q += flyVel.xz * tCur;
    for (int j = 0; j < 5; j ++) {
      q *= qRot;
      t4 = abs (sin (wFreq * (q.xyxy + tw.xxyy) + 2. * Noisev2v4 (t4).xxyy - 1.));
      v4 = (1. - t4) * (t4 + sqrt (1. - t4 * t4));
      t = 1. - sqrt (v4.xz * v4.yw);
      t *= t;
      t *= t;
      h += wAmp * (t.x + t.y);
      wFreq *= 2.;
      wAmp *= 0.5;
    }
    h += 0.3 * wkFac * (1. - smoothstep (0.3, 1.5, length (vec2 (abs (p.x) - 1.3, 0.1 * p.y + 1.1))));
    h *= 1. - smoothstep (0.1, 0.3, d / dstFar);
  }
  return h;
}

float WaveRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = VAR_ZERO; j < 60; j ++) {
    p = ro + s * rd;
    h = p.y - WaveHt (p.xz, s);
    if (h < 0.) break;
    sLo = s;
    s += max (0.5, h) + 0.01 * s;
    if (s > dstFar) break;
  }
  if (h < 0.) {
    sHi = s;
    for (int j = VAR_ZERO; j < 5; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      if (p.y > WaveHt (p.xz, s)) sLo = s;
      else sHi = s;
    }
    dHit = sHi;
  }
  return dHit;
}

vec4 WaveNf (vec3 p, float d)
{
  vec2 e;
  float h;
  e = vec2 (max (0.1, 1e-4 * d * d), 0.);
  h = WaveHt (p.xz, d);
  return vec4 (normalize (vec3 (h - vec2 (WaveHt (p.xz + e.xy, d),
     WaveHt (p.xz + e.yx, d)), e.x)).xzy, h);
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  rd.y = abs (rd.y);
  return mix (vec3 (0.2, 0.4, 1.) + 0.2 * pow (1. - rd.y, 5.),
     vec3 (0.9), clamp (Fbm2 (0.05 * (rd.xz * (100. - ro.y) / rd.y + ro.xz +
     0.5 * tCur)) * rd.y + 0.2, 0., 1.));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4, vh4;
  vec3 col, vn, rw, vnw, row, rdw, roo, rdo, watCol, c;
  float dstObj, dstWat, f, sh, hw, wkFacF, nDotL;
  bool waterRefl;
  flyVel = vec3 (0., 0., 7.);
  flyRol = 0.005 * pi * sin (0.1 * pi * tCur);
  wkFac = 1. - smoothstep (0., 0.5, flyPos.y - 1.2);
  wkFacF = 0.7 * (1. - smoothstep (0., 0.5, flyPos.y - 0.95));
  roo = ro;
  rdo = rd;
  if (rd.y < 0.) {
    dstWat = - ro.y / rd.y;
    if (dstWat < 0.3 * dstFar) dstWat = WaveRay (ro, rd);
  } else dstWat = dstFar;
  for (int k = VAR_ZERO; k < 2; k ++) {
    if (k == 0 || waterRefl) dstObj = ObjRay (ro, rd);
    if (k == 0) {
      waterRefl = (dstWat < min (dstFar, dstObj));
      if (waterRefl) {
        ro += dstWat * rd;
        vh4 = WaveNf (ro, dstWat);
        vnw = vh4.xyz;
        hw = vh4.w;
        row = ro;
        rdw = rd;
        rd = reflect (rd, vnw);
        ro += 0.01 * rd;
      }
    }
  }
  if (dstObj < min (dstWat, dstFar)) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col4 = FlyerCol ();
    if (col4.a >= 0.) {
      sh = waterRefl ? 1. : ObjSShadow (ro + 0.01 * vn, sunDir);
      nDotL = max (dot (vn, sunDir), 0.);
      col = col4.rgb * (0.2 + 0.1 * max (dot (vn, normalize (vec3 (- sunDir.xz, 0.)).xzy), 0.) +
         0.8 * sh * nDotL * nDotL) + col4.a * step (0.95, sh) * pow (max (0.,
         dot (sunDir, reflect (rd, vn))), 32.);
    } else if (col4.a == -1.) {
      col = col4.rgb * (0.7 + 0.3 * max (- dot (rd, vn), 0.));
    }
    if (col4.a == -2. || col4.a >= 0.) {
      rd = reflect (rd, vn);
      c = SkyCol (ro, rd);
      if (col4.a == -2.) col = 0.4 * (c * c + 0.5);
      else if (rd.y > 0.) col = mix (col, c, 0.05);
    }
  } else {
    col = SkyCol (ro, rd);
  }
  if (waterRefl) {
    f = (1. - smoothstep (0.1, 1.5, length (vec2 (0.3 * row.x, 0.06 * row.z + 1.)))) * wkFac;
    f = max (f, (1. - smoothstep (0.1, 1., length (vec2 (0.8 * (abs (row.x) - 6.5),
       0.1 * row.z + 0.5)))) * wkFacF);
    rw = row + flyVel * tCur;
    vnw = VaryNf (rw, vnw, (1. + 5. * f) * (1. - smoothstep (0.1, 0.4, dstWat / dstFar)));
    watCol = mix (vec3 (0.1, 0.35, 0.4), vec3 (0.1, 0.3, 0.25),
       smoothstep (0.4, 0.6, Fbm2 (0.25 * rw.xz))) *
       (0.3 + 0.7 * (max (vnw.y, 0.) + 0.1 * pow (max (0., dot (sunDir, reflect (rdw, vnw))), 32.)));
    col = mix (watCol, 0.8 * col, 0.2 + 0.8 * pow (1. - abs (dot (rdw, vnw)), 4.));
    col = mix (col, vec3 (1.), 0.5 * (1. - smoothstep (0., 0.1, f)) * pow (clamp (0.1 * hw +
         Fbm2 (0.5 * rw.xz), 0., 1.), 8.));
    col = mix (col, vec3 (1.) * (0.7 + 0.3 * Fbm2 (64. * rw.xz)), f);
    col = mix (col, SkyCol (row, rdw), smoothstep (0.6, 0.95, dstWat / dstFar));
  }
  if (TrObjRay (roo, rdo) < min (min (dstObj, dstWat), dstFar)) col = mix (col,
     mix (vec3 (1., 0.6, 0.3), vec3 (1.), step (0.05, abs (length (qHit.xy) - 0.45))), 0.2);
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
  el = 0.12 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.4 * pi * mPtr.y;
  } else {
    az -= 0.025 * pi * tCur;
    el -= 0.05 * pi * sin (0.04 * pi * tCur);
  }
  el = clamp (el, 0.07 * pi, 0.3 * pi);
  flyPos = vec3 (0., 1.2 + 4. * SmoothBump (0.25, 0.75, 0.15, mod (0.02 * tCur, 1.)), 0.);
  ro = 35. * sin (el + vec2 (0.5 * pi, 0.)).xyx * vec3 (sin (az + vec2 (0.5 * pi, 0.)), 1.).xzy;
  vuMat = DirVuMat (normalize (flyPos - ro));
  zmFac = 5.5;
  dstFar = 250.;
  sunDir = normalize (vec3 (1., 1.5, 1.));
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

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d;
  d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
}

float PrRoundBox2Df (vec2 p, vec2 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
}

float PrCaps2Df (vec2 p, float r, float h)
{
  return length (p - vec2 (0., clamp (p.y, - h, h))) - r;
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b - h * r, a, h);
}

float SmoothMax (float a, float b, float r)
{
  return - SmoothMin (- a, - b, r);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

mat3 DirVuMat (vec3 vd)
{
  float s;
  s = sqrt (max (1. - vd.y * vd.y, 1e-6));
  return mat3 (vec3 (vd.z, 0., - vd.x) / s, vec3 (- vd.y * vd.x, 1. - vd.y * vd.y,
     - vd.y * vd.z) / s, vd);
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

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + vec4 (0., 1., 57., 58.)) * cHashM);
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

vec2 Noisev2v4 (vec4 p)
{
  vec4 ip, fp, t1, t2;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t1 = Hashv4f (dot (ip.xy, vec2 (1., 57.)));
  t2 = Hashv4f (dot (ip.zw, vec2 (1., 57.)));
  return vec2 (mix (mix (t1.x, t1.y, fp.x), mix (t1.z, t1.w, fp.x), fp.y),
               mix (mix (t2.x, t2.y, fp.z), mix (t2.z, t2.w, fp.z), fp.w));
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
  vec4 v;
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  for (int j = VAR_ZERO; j < 4; j ++)
     v[j] = Fbmn (p + ((j < 2) ? ((j == 0) ? e.xyy : e.yxy) : ((j == 2) ? e.yyx : e.yyy)), n);
  g = v.xyz - v.w;
  return normalize (n + f * (g - n * dot (n, g)));
}
