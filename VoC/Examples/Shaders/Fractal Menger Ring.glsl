#version 420

// original https://www.shadertoy.com/view/ldVcDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Menger Ring" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1   // optional antialiasing (0/1 - off/on)

float PrBoxDf (vec3 p, vec3 b);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
float Noisefv3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

float tCur, dstFar;
const float pi = 3.14159;

float ObjDf (vec3 p)
{
  vec3 b;
  float r, a;
  const float nIt = 5., sclFac = 2.4;
  b = (sclFac - 1.) * vec3 (1., 1.125, 0.625);
  r = length (p.xz);
  a = (r > 0.) ? atan (p.z, - p.x) / (2. * pi) : 0.;
  p.x = mod (16. * a + 1., 2.) - 1.;
  p.z = r - 32. / (2. * pi);
  for (float n = 0.; n < nIt; n ++) {
    p = abs (p);
    p.xy = (p.x > p.y) ? p.xy : p.yx;
    p.xz = (p.x > p.z) ? p.xz : p.zx;
    p.yz = (p.y > p.z) ? p.yz : p.zy;
    p = sclFac * p - b;
    p.z += b.z * step (p.z, -0.5 * b.z);
  }
  return PrBoxDf (p, vec3 (1.)) / pow (sclFac, nIt);
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
    d = ObjDf (ro + rd * dHit);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
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
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 24; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += min (0.05, 3. * h);
    if (sh < 0.001) break;
  }
  return 0.3 + 0.7 * sh;
}

float ObjAO (vec3 ro, vec3 rd)
{
  float ao, d;
  ao = 0.;
  for (int j = 0; j < 8; j ++) {
    d = 0.1 + float (j) / 16.;
    ao += max (0., d - 3. * ObjDf (ro + d * rd));
  }
  return 0.5 + 0.5 * clamp (1. - 0.2 * ao, 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 ltPos[4], ltDir, col, vn, rds;
  float dstObj, dfTot, spTot, at, ao, sh, ul;
  for (int k = 0; k < 4; k ++) {
    ul = (k < 2) ? 1. : - 1.;
    ltPos[k] = vec3 (0., 20. * ul, 20.);
    ltPos[k].xz = Rot2D (ltPos[k].xz, float (k) * pi + 0.1 * ul * pi * tCur);
  }
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    vn = VaryNf (256. * ro, vn, 1.);
    dfTot = 0.;
    spTot = 0.;
    for (int k = 0; k < 4; k ++) {
      ltDir = normalize (ltPos[k]);
      at = smoothstep (0., 0.3, dot (normalize (ltPos[k] - ro), ltDir));
      sh = ObjSShadow (ro, ltDir);
      dfTot = max (dfTot, at * sh * max (dot (vn, ltDir), 0.));
      spTot = max (spTot, at * smoothstep (0.5, 0.8, sh) *
         pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.));
    }
    ao = ObjAO (ro, vn);
    col = ao * (vec3 (0.75, 0.8, 0.75) * (0.2 + 0.8 * dfTot) + 0.3 * vec3 (1., 1., 0.) * spTot);
  } else {
    col = vec3 (0.02, 0.02, 0.04);
    if (rd.y < 0.) {
      rd.y = - rd.y;
      rd.xz = vec2 (- rd.z, rd.x);
    }
    rds = floor (2000. * rd);
    rds = 0.00015 * rds + 0.1 * Noisefv3 (0.0005 * rds.yzx);
    for (int j = 0; j < 19; j ++) rds = abs (rds) / dot (rds, rds) - 0.9;
    col += vec3 (1., 1., 0.5) * min (1., 0.5e-3 * pow (min (6., length (rds)), 5.));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, vd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac, t, tt, ph;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  t = 0.05 * tCur;
  tt = t - floor (t);
  ph = mod (floor (t), 3.);
  if (tt > 0.95 && 0.5 * uv.x * canvas.y / canvas.x + 0.5 < (tt - 0.95) / 0.05)
     ph = mod (ph + 1., 3.);
  az = 0.;
  el = 0.;
  if (ph == 0.) {
    if (mPtr.z > 0.) {
      az += 2. * pi * mPtr.x;
      el += 0.5 * pi * mPtr.y;
    } else {
      az = 0.03 * pi * tCur;
      el = -0.25 * pi * cos (0.02 * pi * tCur);
    }
    zmFac = 4.;
  } else if (ph == 1.) {
    if (mPtr.z > 0.) {
      az -= 2. * pi * mPtr.x;
    } else {
      az = 0.5 * pi * (1. - 2. * SmoothBump (0.25, 0.75, 0.2, mod (0.02 * tCur, 1.)));
      el = 0.15 * pi * (1. - 2. * SmoothBump (0.25, 0.75, 0.2, mod (0.017 * tCur, 1.)));
    }
    t = 0.03 * tCur;
    ro = (32. / (2. * pi)) * vec3 (cos (t), 0., sin (t));
    vd = normalize (- ro);
    zmFac = 1.8;
  } else if (ph == 2.) {
    t = 0.043 * tCur;
    tt = mod (t, 1.);
    ro.xz = 8. * ((mod (t, 2.) < 1.) ? vec2 (- cos (2. * pi * tt) + 1., sin (2. * pi * tt)) :
       vec2 (cos (2. * pi * tt) - 1., sin (2. * pi * tt)));
    ro.y = 5. * (0.5 - SmoothBump (0.3, 0.7, 0.15, tt));
    vd = normalize (vec3 (1., 0., 1.) - ro);
    zmFac = 2.4;
  }
  if (ph == 0.) {
    ori = vec2 (el, az);
    ca = cos (ori);
    sa = sin (ori);
    vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
            mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
    ro = vuMat * vec3 (0., 0., -25.);
  } else {
    vd.yz = Rot2D (vd.yz, - el);
    vd.xz = Rot2D (vd.xz, az);
    vuMat = mat3 (vec3 (vd.z, 0., - vd.x) / sqrt (1. - vd.y * vd.y),
       vec3 (- vd.y * vd.x, 1. - vd.y * vd.y, - vd.y * vd.z) / sqrt (1. - vd.y * vd.y), vd);
  }
  dstFar = 60.;
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.),
       0.5 * pi * (a + 0.5)), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
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
