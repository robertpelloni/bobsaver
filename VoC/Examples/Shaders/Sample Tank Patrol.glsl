#version 420

// original https://www.shadertoy.com/view/WsjXRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Tank Patrol" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1   // optional antialiasing

float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrCylAnDf (vec3 p, float r, float w, float h);
float PrFlatCylDf (vec3 p, float rhi, float rlo, float h);
float PrFlatCylAnDf (vec3 p, float rhi, float rlo, float w, float h);
float PrTorusDf (vec3 p, float ri, float rc);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
float Fbm1 (float p);
float Fbm2 (vec2 p);
float Fbm3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 sunDir, qHit;
float tCur, dstFar, canEl, canAz, canLen, smkRadEx, smkRadIn, smkPhs, flmLen, whlSpc, whlRad,
   bltThk, bltWid, veGap;
int idObj;
const float pi = 3.14159;
const int idBelt = 1, idWhl = 2, idAxl = 3, idBase = 4, idTur = 5, idCan = 6;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, qx, qz, r, xLim;
  dMin = dstFar;
  xLim = abs (p.x) - 1.5 * veGap;
  p.x = mod (p.x + 0.5 * veGap, veGap) - 0.5 * veGap;
  q = p;
  q.y -= whlRad + 2. * bltThk;
  qx = q.x;
  q.x = abs (q.x) - 0.8 * whlSpc;
  d = PrFlatCylAnDf (q.zyx, whlSpc, whlRad + bltThk, bltThk, bltWid);
  DMINQ (idBelt);
  qz = q.z;
  q.z = mod (q.z + 0.5 * whlSpc, whlSpc) - 0.5 * whlSpc;
  d = max (min (PrCylAnDf (q.yzx, 0.9 * whlRad, 0.1 * whlRad, 1.2 * bltWid),
     PrCylDf (q.yzx, 0.8 * whlRad, 0.5 * bltWid)), abs (qz) - whlSpc - whlRad);
  DMINQ (idWhl);
  q.x = qx;
  d = max (PrCylDf (q.yzx, 0.2 * whlRad, 0.9 * whlSpc), abs (qz) - whlSpc - whlRad);
  DMINQ (idAxl);
  q = p;
  q.y -= 1.4 * whlRad + 2. * bltThk;
  d = 0.8 * PrFlatCylDf (q.zyx, whlSpc + whlRad, 0.9 * whlRad * (1. - 0.5 * q.x * q.x),
     0.8 * whlSpc - 1.5 * bltWid);
  DMINQ (idBase);
  r = 1.1 * (0.8 * whlSpc - 1.5 * bltWid);
  q.xz = Rot2D (q.xz, canAz);
  q.y -= 0.9 * whlRad - 0.5 * r;
  d = max (PrSphDf (q, r), - (q.y - 0.5 * r));
  DMINQ (idTur);
  q.y -= 0.58 * r;
  q.yz = Rot2D (q.yz, canEl);
  q.z -= canLen;
  d = PrCylAnDf (q, 0.12 * whlRad, 0.04 * whlRad, canLen);
  DMINQ (idCan);
  dMin = max (0.9 * dMin, xLim);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
    p = ro + dHit * rd;
    d = ObjDf (p);
    if (d < 0.0005 || dHit > dstFar || p.y < 0.) break;
    dHit += d;
  }
  if (p.y < 0.) dHit = dstFar;
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0002, -0.0002);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float SmokeDens (vec3 p)
{
  mat2 rMat;
  vec3 q, u;
  float f;
  f = PrTorusDf (p.xzy, smkRadIn, smkRadEx);
  if (f < 0.) {
    q = p.xzy / smkRadEx;
    u = normalize (vec3 (q.xy, 0.));
    q -= u;
    rMat = mat2 (vec2 (u.x, - u.y), u.yx);
    q.xy = rMat * q.xy;
    q.xz = Rot2D (q.xz, 2.5 * tCur);
    q.xy = q.xy * rMat;
    q += u;
    q.xy = Rot2D (q.xy, 0.2 * tCur);
    f = smoothstep (0., smkRadIn, - f) * Fbm3 (16. * q);
  } else f = 0.;
  return f;
}

vec4 SmokeCol (vec3 ro, vec3 rd, float dstObj)
{
  vec4 col4;
  vec3 smkPos, p;
  float densFac, d, h, xLim;
  smkPos = vec3 (0., 0., 2. * canLen + smkPhs);
  smkPos.yz = Rot2D (smkPos.yz, - canEl);
  smkPos.xz = Rot2D (smkPos.xz, - canAz);
  smkPos.y += 1.4 * whlRad + 2. * bltThk + 0.58 * 1.1 * (0.8 * whlSpc - 1.5 * bltWid);
  smkRadIn = 0.005 + 0.045 * smoothstep (0.02, 0.15, smkPhs);
  smkRadEx = (2.5 + 3. * smoothstep (0.1, 0.4, smkPhs)) * smkRadIn;
  smkRadIn *= 1. - 0.3 * smoothstep (0.7, 1., smkPhs);
  d = 0.;
  for (int j = 0; j < 30; j ++) {
    p = ro + d * rd - smkPos;
    xLim = abs (p.x) - 1.5 * veGap;
    p.x = mod (p.x + 0.5 * veGap, veGap) - 0.5 * veGap;
    p.xz = Rot2D (p.xz, canAz);
    p.yz = Rot2D (p.yz, 0.5 * pi + canEl);
    h = max (PrTorusDf (p.xzy, smkRadIn, smkRadEx), xLim);
    d += h;
    if (h < 0.001 || d > dstFar) break;
  }
  col4 = vec4 (0.);
  if (d < min (dstObj, dstFar)) {
    densFac = 1.5 * max (1.1 - pow (smkPhs, 1.5), 0.);
    for (int j = 0; j < 16; j ++) {
      p = ro + d * rd - smkPos;
      p.x = mod (p.x + 0.5 * veGap, veGap) - 0.5 * veGap;
      p.xz = Rot2D (p.xz, canAz);
      p.yz = Rot2D (p.yz, 0.5 * pi + canEl);
      col4 += densFac * SmokeDens (p) * (1. - col4.w) * vec4 (vec3 (0.9) - col4.rgb, 0.1);
      d += 2.2 * smkRadIn / 16.;
      if (col4.w > 0.99 || d > dstFar) break;
    }
  }
  return col4;
}

vec4 FlameCol (vec3 ro, vec3 rd, float dstObj)
{
  vec3 flmPos, p;
  float d, h, xLim;
  flmPos = vec3 (0., 0., 2. * canLen + flmLen);
  flmPos.yz = Rot2D (flmPos.yz, - canEl);
  flmPos.xz = Rot2D (flmPos.xz, - canAz);
  flmPos.y += 1.4 * whlRad + 2. * bltThk + 0.58 * 1.1 * (0.8 * whlSpc - 1.5 * bltWid);
  d = 0.;
  for (int j = 0; j < 50; j ++) {
    p = ro + d * rd - flmPos;
    xLim = abs (p.x) - 1.5 * veGap;
    p.x = mod (p.x + 0.5 * veGap, veGap) - 0.5 * veGap;
    p.xz = Rot2D (p.xz, canAz);
    p.yz = Rot2D (p.yz, 0.5 * pi + canEl);
    p.y -= flmLen;
    h = max (0.9 * PrCylDf (p.xzy, 0.12 * whlRad * clamp (0.7 + 0.3 * p.y / flmLen, 0., 1.),
       flmLen), xLim);
    d += h;
    if (h < 0.001 || d > dstFar) break;
  }
  return (d < min (dstObj, dstFar)) ? vec4 (1., 0.4, 0.1,
     1. - 0.9 * smoothstep (0.2, 0.25, smkPhs)) : vec4 (0.);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.01;
  for (int j = 0; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.3 + 0.7 * sh;
}

vec3 SkyBgCol (vec3 ro, vec3 rd)
{
  vec3 col, clCol, skCol;
  vec2 q;
  float f, fd, ff, sd;
  if (rd.y > -0.02 && rd.y < 0.03 * Fbm1 (16. * atan (rd.z, - rd.x))) {
    col = vec3 (0.3, 0.41, 0.55);
  } else {
    q = 0.02 * (ro.xz + 0.5 * tCur + ((100. - ro.y) / rd.y) * rd.xz);
    ff = Fbm2 (q);
    f = smoothstep (0.2, 0.8, ff);
    fd = smoothstep (0.2, 0.8, Fbm2 (q + 0.01 * sunDir.xz)) - f;
    clCol = (0.7 + 0.5 * ff) * (vec3 (0.7) - 0.7 * vec3 (0.3, 0.3, 0.2) * sign (fd) *
       smoothstep (0., 0.05, abs (fd)));
    sd = max (dot (rd, sunDir), 0.);
    skCol = vec3 (0.4, 0.5, 0.8) + step (0.1, sd) * vec3 (1., 1., 0.9) *
       min (0.3 * pow (sd, 64.) + 0.5 * pow (sd, 2048.), 1.);
    col = mix (skCol, clCol, 0.1 + 0.9 * f * smoothstep (0.01, 0.1, rd.y));
  }
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4, smkCol4, flmCol4;
  vec3 q, col, vn, gPos, roo;
  float dstObj, dstGrnd, tCyc, spd, dMove, s, t, f, nSegR, bGap, r, nDotS, sh;
  nSegR = 16.;
  whlRad = 0.29;
  bltWid = 0.1;
  bltThk = 0.03;
  bGap = 2. * pi * whlRad / nSegR;
  whlSpc = floor (0.8 / bGap) * bGap;
  canLen = 0.8 * whlSpc;
  veGap = 3.5 * whlSpc;
  tCyc = 8.;
  spd = 3.;
  t = mod (tCur / tCyc, 1.);
  dMove = spd * (floor (tCur / tCyc) + smoothstep (0.5, 1., t));
  canEl = pi * (0.05 + 0.15 * SmoothBump (0.1, 0.4, 0.1, t));
  s = floor (mod (tCur / tCyc, 4.));
  canAz = (mod (s, 2.) == 1.) ? pi * 0.2 * SmoothBump (0.1, 0.4, 0.1, t) * sign (s - 2.) : 0.;
  smkPhs = clamp (t, 0.15, 0.5) / 0.15 - 1.;
  dstObj = ObjRay (ro, rd);
  if (smkPhs > 0.) smkCol4 = SmokeCol (ro, rd, dstObj);
  flmLen = 0.7 * whlRad * SmoothBump (0.03, 0.32, 0.02, smkPhs);
  if (flmLen > 0.) flmCol4 = FlameCol (ro, rd, dstObj);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == idBase || idObj == idTur) {
      col4 = mix (vec4 (0.1, 0.4, 0.1, 0.1), vec4 (0.4, 0.4, 0.1, 0.05),
         smoothstep (0.45, 0.5, Fbm2 (8. * qHit.xz + 11. * floor (ro.x / veGap + 0.5))));
      r = abs (qHit.x) / (0.8 * whlSpc - 1.5 * bltWid);
      if (idObj == idBase) {
        col4 *= 1. - 0.5 * SmoothBump (0.8, 0.85, 0.01, r);
        if (r < 0.75) {
          if (qHit.z < -1.65 * whlSpc)
             col4 *= 1. - 0.7 * SmoothBump (0.3, 0.7, 0.02, mod (8. * r, 1.));
          else if (qHit.z > 1.6 * whlSpc)
             col4 *= 1. - 0.7 * SmoothBump (0.3, 0.7, 0.02, mod (16. * qHit.y, 1.));
        }
      } else if (idObj == idTur) {
        col4 *= 1. - 0.5 * SmoothBump (0.8, 0.85, 0.01, r);
        col4 *= 1. - 0.7 * SmoothBump (0.17, 0.2, 0.01, r);
        if (qHit.z > 0. && abs (qHit.y - 0.43) < 0.07) col4 *= 1. - 0.5 * step (r, 0.08);
      }
    } else if (idObj == idCan) {
      col4 = vec4 (0.3, 0.5, 0.3, 0.1) * (1. - 0.5 * SmoothBump (0.03, 0.06, 0.01,
         abs (qHit.z - 0.3))) * (1. - 0.8 * step (length (qHit.xy), 0.1 * whlRad));
    } else if (idObj == idWhl) {
      col4 = (abs (qHit.x) < bltWid) ? vec4 (0.2, 0.3, 0.2, 0.) : vec4 (0.1, 0.4, 0.1, 0.1);
      q = qHit;
      q.yz = Rot2D (q.yz, - dMove / whlRad);
      r = length (q.yz) / whlRad;
      col4.rgb *= 1. - 0.9 * max (step (0.5, r) * SmoothBump (0.45, 0.55, 0.03,
         mod (nSegR * atan (q.z, - q.y) / (2. * pi), 1.)),
         SmoothBump (0.48, 0.52, 0.01, abs (r)));
    } else if (idObj == idAxl) {
      col4 = vec4 (0.2, 0.3, 0.2, 0.05);
    } else if (idObj == idBelt) {
      col4 = vec4 (0.4, 0.3, 0.1, 0.);
      if (abs (qHit.z) < whlSpc) {
        col4.rgb *= 1. - 0.7 * SmoothBump (0.42, 0.58, 0.05,
           mod ((qHit.z - sign (qHit.y) * dMove) / bGap, 1.));
      } else {
        q = qHit;
        q.z -= sign (q.z) * whlSpc;
        q.yz = Rot2D (q.yz, - dMove / whlRad);
        col4.rgb *= 1. - 0.7 * SmoothBump (0.42, 0.58, 0.05,
           mod (nSegR * atan (q.z, - q.y) / (2. * pi), 1.));
      }
    }
    sh = ObjSShadow (ro, sunDir);
    nDotS = max (dot (vn, sunDir), 0.);
    if (idObj != idBelt) nDotS *= nDotS;
    col = col4.rgb * (0.3 + 0.7 * sh * nDotS) + smoothstep (0.8, 0.9, sh) * sh *
       col4.a * pow (max (dot (normalize (sunDir - rd), vn), 0.), 32.);
  } else if (rd.y < 0.) {
    roo = ro;
    dstGrnd = - ro.y / rd.y;
    ro += dstGrnd * rd;
    vn = vec3 (0., 1., 0.);
    sh = (dstGrnd < dstFar) ? ObjSShadow (ro, sunDir) : 1.;
    gPos = ro + vec3 (0., 0., dMove);
    r = (ro.z < whlSpc && abs (ro.x) < 1.5 * veGap) ? 1. - smoothstep (1., 1.8,
       abs (abs (mod (ro.x + 0.5 * veGap, veGap) - 0.5 * veGap) - 0.8 * whlSpc) / bltWid) : 0.;
    s = 1. - smoothstep (0.3, 0.8, dstGrnd / dstFar);
    f = 1. - Fbm2 (0.5 * gPos.xz);
    vn = VaryNf (4. * gPos, vn, (4. * f * f + 2. * r) * s);
    col = mix (vec3 (0.4, 0.5, 0.3), vec3 (0.4, 0.3, 0.2),
       smoothstep (0.2, 0.8, Fbm2 (2. * gPos.xz)));
    col = mix (vec3 (0.33, 0.45, 0.15), col, s);
    if (r > 0.) col *= 1. - (0.1 + 0.05 * sin ((2. * pi / bGap) * gPos.z)) * r * s;
    col *= sh * max (dot (vn, sunDir), 0.);
    col = mix (0.8 * col, vec3 (0.3, 0.41, 0.55), pow (1. + rd.y, 16.));
  } else {
    col = SkyBgCol (ro, rd);
  }
  if (flmLen > 0.) col = mix (col, flmCol4.rgb, flmCol4.a);
  if (smkPhs > 0.) col = mix (col, smkCol4.rgb, smkCol4.a);
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.15 * pi;
  if (mPtr.z > 0.) {
    az += 3. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az += 0.03 * pi * tCur;
    el += 0.12 * pi * sin (0.023 * pi * tCur);
  }
  el = clamp (el, -0.4 * pi, -0.03 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -18.);
  dstFar = 80.;
  sunDir = normalize (vec3 (0., 1., -0.7));
  sunDir.xz = Rot2D (sunDir.xz, 0.005 * pi * tCur);
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), 6.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (pow (col, vec3 (0.9)), 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCylAnDf (vec3 p, float r, float w, float h)
{
  return max (abs (length (p.xy) - r) - w, abs (p.z) - h);
}

float PrFlatCylDf (vec3 p, float rhi, float rlo, float h)
{
  float d;
  d = length (p.xy - vec2 (clamp (p.x, - rhi, rhi), 0.)) - rlo;
  if (h > 0.) d = max (d, abs (p.z) - h);
  return d;
}

float PrFlatCylAnDf (vec3 p, float rhi, float rlo, float w, float h)
{
  return max (abs (length (p.xy - vec2 (clamp (p.x, - rhi, rhi), 0.)) - rlo) - w, abs (p.z) - h);
}

float PrTorusDf (vec3 p, float ri, float rc)
{
  return length (vec2 (length (p.xy) - rc, p.z)) - ri;
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
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
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

float Noisefv3 (vec3 p)
{
  vec4 t;
  vec3 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp *= fp * (3. - 2. * fp);
  t = mix (Hashv4v3 (ip), Hashv4v3 (ip + vec3 (0., 0., 1.)), fp.z);
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
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

float Fbm3 (vec3 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
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
