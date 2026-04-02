#version 420

// original https://www.shadertoy.com/view/MsGcWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Polyhedral Menger" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  0   // optional antialiasing (0/1 - off/on)

float PrBoxDf (vec3 p, vec3 b);
vec3 HsvToRgb (vec3 c);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);

vec2 csD, csD2;
float tCur, dstFar;
const float pi = 3.14159;

vec3 DodecSym (vec3 p)
{
  float a, w;
  w = 2. * pi / 5.;
  p.xz = Rot2Cs (vec2 (p.x, abs (p.z)), vec2 (csD.x, - csD.y));
  p.xy = Rot2D (p.xy, - 0.25 * w);
  p.x = - abs (p.x);
  for (int k = 0; k < 3; k ++) {
    if (dot (p.yz, csD) > 0.) p.zy = Rot2Cs (p.zy, csD2) * vec2 (1., -1.);
    p.xy = Rot2D (p.xy, - w);
  }
  if (dot (p.yz, csD) > 0.) p.zy = Rot2Cs (p.zy, csD2) * vec2 (1., -1.);
  a = mod (atan (p.x, p.y) + 0.5 * w, w) - 0.5 * w;
  p.yx = vec2 (cos (a), sin (a)) * length (p.xy);
  p.xz = - vec2 (abs (p.x), p.z);
  return p;
}

float ObjDf (vec3 p)
{
  vec3 b;
  const float nIt = 5., sclFac = 2.4;
  b = (sclFac - 1.) * vec3 (0.8, 1., 0.5) * (1. + 0.03 * sin (vec3 (1.23, 1., 1.43) * tCur));
  p = DodecSym (p);
  p.z += 0.6 * (1. + b.z);
  p.xy /= 1. - 0.2 * p.z;
  for (float n = 0.; n < nIt; n ++) {
    p = abs (p);
    p.xy = (p.x > p.y) ? p.xy : p.yx;
    p.xz = (p.x > p.z) ? p.xz : p.zx;
    p.yz = (p.y > p.z) ? p.yz : p.zy;
    p = sclFac * p - b;
    p.z += b.z * step (p.z, -0.5 * b.z);
  }
  return 0.9 * PrBoxDf (p, vec3 (1.)) / pow (sclFac, nIt);
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
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
    d += min (0.08, 3. * h);
    if (sh < 0.001) break;
  }
  return 0.3 + 0.7 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 ltPos[4], ltDir, col, vn;
  float dstObj, dfTot, spTot, at, sh;
  float dihedDodec, h;
  dihedDodec = 0.5 * atan (2.);
  csD = vec2 (cos (dihedDodec), - sin (dihedDodec));
  csD2 = vec2 (cos (2. * dihedDodec), - sin (2. * dihedDodec));
  for (int k = 0; k < 3; k ++) {
    ltPos[k] = vec3 (0., 4., 6.);
    ltPos[k].xz = Rot2D (ltPos[k].xz, float (k) * 2. * pi / 3. -0.1 * pi * tCur);
  }
  ltPos[3] = vec3 (0., 6., 0.);
  ltPos[3].xy = Rot2D (ltPos[3].xy, pi * (0.05 + 0.04 * sin (0.14 * pi * tCur)));
  ltPos[3].xz = Rot2D (ltPos[3].xz, 0.1 * pi * tCur);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    dfTot = 0.;
    spTot = 0.;
    for (int k = 0; k < 4; k ++) {
      ltDir = normalize (ltPos[k]);
      at = smoothstep (0., 0.3, dot (normalize (ltPos[k] - ro), ltDir));
      sh = ObjSShadow (ro, ltDir);
      dfTot = max (dfTot, at * sh * max (dot (vn, ltDir), 0.));
      spTot = max (spTot, at * smoothstep (0.5, 0.8, sh) * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.));
    }
    h = mod (length (ro) - 0.03 * tCur, 1.);
    col = HsvToRgb (vec3 (h, 0.5, 0.8)) * (0.2 + 0.8 * dfTot) +
       HsvToRgb (vec3 (mod (h + 0.5, 1.), 1., 0.4)) * spTot;
  } else {
    col = vec3 (0.6, 1., 1.) * (0.2 + 0.2 * (rd.y + 1.) * (rd.y + 1.));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.2 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.5 * pi * mPtr.y;
  } else {
    az = 0.03 * pi * tCur;
    el = - pi * (0.2 + 0.25 * sin (0.02 * pi * tCur));
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -12.);
  zmFac = 8. + 4. * sin (0.05 * pi * tCur);
  dstFar = 20.;
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

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
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
