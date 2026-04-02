#version 420

// original https://www.shadertoy.com/view/WdKcz1

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Gliders Over Voropolis" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  0  // (=0/1) optional antialiasing (recommended if not fullscreen)

vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
void HexVorInit ();
vec4 HexVor (vec2 p);
float SmoothMin (float a, float b, float r);
float SmoothMax (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec3 HsvToRgb (vec3 c);
float Hashfv2 (vec2 p);
vec2 Hashv2v2 (vec2 p);
float Fbm2 (vec2 p);

mat3 flyerMat[3], flMat;
vec3 flyerPos[3], flPos, trkF, trkA, sunDir, qHit;
float tCur, dstFar, dstBld, hBase, vorScl;
int idObj;
const float pi = 3.1415927, sqrt3 = 1.732051;

#define VAR_ZERO min (frames, 0)

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float FlyerDf (vec3 p)
{
  vec3 q, qq;
  float dMin, d, a;
  dMin = dstFar;
  for (int k = VAR_ZERO; k < 3; k ++) {
    q = flyerMat[k] * (p - flyerPos[k]);
    q.x = abs (q.x);
    a = 0.22 * pi;
    q.z += 0.25;
    qq = q;
    qq.xy = Rot2D (vec2 (abs (qq.x), qq.y), - a);
    qq.xz = Rot2D (vec2 (qq.x, qq.z - 1.1), -0.012 * pi);
    qq.xy = Rot2D (vec2 (abs (qq.x), qq.y), a);
    d = abs (max (max (abs (qq.y) - 0.002, 0.), max (dot (q.xz, sin (0.15 * pi +
       vec2 (0.5 * pi, 0.))) - 0.5, - q.z - 0.5))) - 0.002;
    DMINQ (1 + k);
  }
  return dMin;
}

float FlyerRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    d = FlyerDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 FlyerNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.0002, -0.0002);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = FlyerDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float BldDf (vec3 p)
{
  vec4 vc;
  float h;
  vc = HexVor (vorScl * p.xz);
  h = 0.5 * (floor (16. * vc.w) + 2.) + 0.04 * dstBld *
     smoothstep (0.8, 1., dstBld / dstFar);
  return min (0.2 * SmoothMax (0.75 - vc.x, p.y - h, 0.03), p.y + hBase);
}

float BldRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  if (rd.y < 0.) {
    dHit = - (ro.y - 9.) / rd.y;
    for (int j = VAR_ZERO; j < 320; j ++) {
      dstBld = dHit;
      d = BldDf (ro + dHit * rd);
      dHit += d;
      if (d < 0.001 || dHit > dstFar) break;
    }
  } else dHit = dstFar;
  return dHit;
}

vec3 BldNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = BldDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  vec3 col;
  float sd, f;
  rd.y = abs (rd.y);
  sd = max (dot (rd, sunDir), 0.);
  ro.x += 0.5 * tCur;
  f = Fbm2 (0.05 * (rd.xz * (50. - ro.y) / (rd.y + 0.0001) + ro.xz));
  col = vec3 (0.1, 0.3, 0.5) + 0.3 * pow (1. - max (rd.y, 0.), 4.);
  col += vec3 (1., 1., 0.9) * (0.3 * pow (sd, 32.) + 0.2 * pow (sd, 512.));
  return mix (col, vec3 (0.9), clamp ((f - 0.2) * rd.y + 0.3, 0., 1.));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 vc;
  vec3 col, vn;
  float dstBld, dstFlyer, c, hw;
  HexVorInit ();
  vorScl = 0.3;
  hBase = 5.;
  dstBld = BldRay (ro, rd);
  dstFlyer = FlyerRay (ro, rd);
  if (min (dstFlyer, dstBld) < dstFar) {
    if (dstFlyer < dstBld) {
      ro += dstFlyer * rd;
      col = (idObj == 1) ? vec3 (1., 0., 0.) : ((idObj == 2) ? vec3 (0., 1., 0.) :
         vec3 (0., 0., 1.));
      col = mix (col, vec3 (1., 1., 0.), smoothstep (0.02, 0.03,
         abs (abs (qHit.x - 0.3) - 0.05)) * (1. - smoothstep (0.95, 0.97, qHit.z)));
      vn = FlyerNf (ro);
      col = col * (0.3 + 0.1 * max (- dot (vn, sunDir), 0.) +
         0.7 * max (dot (vn, sunDir), 0.)) +
         0.2 * pow (max (dot (normalize (sunDir - rd), vn), 0.), 32.);
    } else {
      ro += dstBld * rd;
      vc = HexVor (vorScl * ro.xz);
      vn = BldNf (ro);
      hw = mod (ro.y + 0.5, 1.) - 0.5;
      if (abs (hw) < 0.18 && vn.y < 0.01) col = 0.7 * SkyCol (ro, reflect (rd, vn));
      else {
        c = 0.1 * floor (73. * mod (vc.w, 1.) + 0.5);
        col = HsvToRgb (vec3 (0.1 + 0.8 * c, 0.3 + 0.5 * mod (25. * c, 1.), 1.));
        if (ro.y > 0.1 - hBase) col *= (0.5 + 0.3 * mod (37. * c, 1.)) *
           ((vn.y > 0.99) ? 1.2 : (1. - 0.5 * step (abs (hw), 0.25) * sign (hw)));
        else col = mix (col, vec3 (1.) * (0.1 +
           0.9 * step (abs (vc.x - 0.04), 0.02)), step (vc.x, 0.4));
        col = col * (0.2 + 0.8 * max (0., max (dot (vn, sunDir), 0.))) +
           0.05 * pow (max (dot (normalize (sunDir - rd), vn), 0.), 32.);
      }
      col *= 1. + 0.6 * min (ro.y / hBase, 0.);
      col = mix (col, 0.8 * SkyCol (ro, rd), smoothstep (0.4, 0.95, dstBld / dstFar));
    }
  } else col = SkyCol (ro, rd);
  return clamp (col, 0., 1.);
}

vec3 TrkPath (float t)
{
  return vec3 (dot (trkA, sin (trkF * t)), 12., t);
}

vec3 TrkVel (float t)
{
  return vec3 (dot (trkF * trkA, cos (trkF * t)), 0., 1.);
}

vec3 TrkAcc (float t)
{
  return vec3 (dot (trkF * trkF * trkA, - sin (trkF * t)), 0., 0.);
}

vec3 GlareCol (vec3 rd, vec3 sd, vec2 uv)
{
  vec3 col;
  vec2 e;
  e = vec2 (1., 0.);
  if (sd.z > 0.) col = 0.05 * pow (abs (sd.z), 4.) *
     (4. * e.xyy * max (dot (normalize (rd + vec3 (0., 0.3, 0.)), sunDir), 0.) +
      e.xxy * SmoothBump (0.03, 0.05, 0.01, length (uv - 0.7 * sd.xy)) +
      e.yxx * SmoothBump (0.2, 0.23, 0.02, length (uv - 0.5 * sd.xy)) +
      e.xyx * SmoothBump (0.6, 0.65, 0.03, length (uv - 0.3 * sd.xy)));
  else col = vec3 (0.);
  return col;
}

void FlyerPM (float t, int isOb)
{
  vec3 vel, va, flVd;
  vec2 cs;
  float oRl;
  flPos = TrkPath (t);
  vel = TrkVel (t);
  va = cross (TrkAcc (t), vel) / length (vel);
  flVd = normalize (vel);
  oRl = ((isOb > 0) ? 10. : 20.) * length (va) * sign (va.y);
  cs = sin (oRl + vec2 (0.5 * pi, 0.));
  flMat = mat3 (cs.x, - cs.y, 0., cs.y, cs.x, 0., 0., 0., 1.) *
     mat3 (flVd.z, 0., flVd.x, 0., 1., 0., - flVd.x, 0., flVd.z);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, vd, col, gCol;
  vec2 canvas, uv;
  float az, el, zmFac, flyVel, vDir, sr, t;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.17 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.45 * pi * mPtr.y;
  }
  tCur += 50.;
  trkA = 0.2 * vec3 (1.9, 2.9, 4.3);
  trkF = vec3 (0.23, 0.17, 0.13);
  flyVel = 3.;
  vDir = sign (0.5 * pi - abs (az));
  for (int k = VAR_ZERO; k < 3; k ++) {
    t = flyVel * tCur + vDir * (3. + 5. * float (k));
    FlyerPM (t, 0);
    flyerMat[k] = flMat;
    flyerPos[k] = flPos;
    flyerPos[k].y += 0.8 * (2. * SmoothBump (0.25, 0.75, 0.25, mod (0.05 * t, 1.)) - 1.) - 1.;
  }
  t = flyVel * tCur;
  FlyerPM (t, 1);
  ro = flPos;
  vuMat = StdVuMat (el, az);
  zmFac = 2.;
  dstFar = 200.;
  sunDir = normalize (vec3 (sin (0.02 * pi * tCur), 0.2, cos (0.02 * pi * tCur)));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    rd = normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    rd = vuMat * (rd * flMat);
    col += (1. / naa) * ShowScene (ro, rd);
  }
  col += GlareCol (rd, flMat * sunDir * vuMat, uv);
  glFragColor = vec4 (col, 1.);
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

vec2 gVec[7], hVec[7];

void HexVorInit ()
{
  vec3 e = vec3 (1., 0., -1.);
  gVec[0] = e.yy;
  gVec[1] = e.xy;
  gVec[2] = e.yx;
  gVec[3] = e.xz;
  gVec[4] = e.zy;
  gVec[5] = e.yz;
  gVec[6] = e.zx;
  for (int k = 0; k < 7; k ++) hVec[k] = HexToPix (gVec[k]);
}

vec4 HexVor (vec2 p)
{
  vec4 sd, udm;
  vec2 ip, fp, d, u;
  float amp, a;
  amp = 0.5;
  ip = PixToHex (p);
  fp = p - HexToPix (ip);
  sd = vec4 (4.);
  udm = vec4 (4.);
  for (int k = 0; k < 7; k ++) {
    u = Hashv2v2 (ip + gVec[k]);
    a = 2. * pi * (u.y - 0.5);
    d = hVec[k] + amp * (0.4 + 0.6 * u.x) * vec2 (cos (a), sin (a)) - fp;
    sd.w = dot (d, d);
    if (sd.w < sd.x) {
      sd = sd.wxyw;
      udm = vec4 (d, u);
    } else sd = (sd.w < sd.y) ? sd.xwyw : ((sd.w < sd.z) ? sd.xyww : sd);
  }
  sd.xyz = sqrt (sd.xyz);
  return vec4 (SmoothMin (sd.y, sd.z, 0.05) - sd.x, udm.xy, Hashfv2 (udm.zw));
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothMax (float a, float b, float r)
{
  return - SmoothMin (- a, - b, r);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
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
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
}

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
