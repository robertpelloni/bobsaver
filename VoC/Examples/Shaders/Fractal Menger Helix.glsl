#version 420

// original https://www.shadertoy.com/view/4sVyDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Menger Helix" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Twisted fractal helix (mouseable, Moebius ring and antialiasing options)

#define MOB 0   // optional Moebius ring
#define AA  1   // optional antialiasing

float PrBoxDf (vec3 p, vec3 b);
vec2 Rot2D (vec2 q, float a);

vec3 ltDir;
float tCur, dstFar;
const float pi = 3.14159;

float ObjDf (vec3 p)
{
  vec3 b;
  float r, a;
  const float nIt = 5., sclFac = 2.4;
  b = (sclFac - 1.) * vec3 (1., 1.125, 0.625);
  p.xz = Rot2D (p.xz, 0.05 * tCur);
  r = length (p.xz);
  a = (r > 0.) ? atan (p.z, - p.x) / (2. * pi) : 0.;
#if ! MOB
  p.y = mod (p.y - 4. * a + 2., 4.) - 2.;
#endif
  p.x = mod (16. * a + 1., 2.) - 1.;
  p.z = r - 32. / (2. * pi);
#if ! MOB
  p.yz = Rot2D (p.yz, 2. * pi * a);
#else
  p.yz = Rot2D (p.yz, pi * a);
#endif
  for (float n = 0.; n < nIt; n ++) {
    p = abs (p);
    p.xy = (p.x > p.y) ? p.xy : p.yx;
    p.xz = (p.x > p.z) ? p.xz : p.zx;
    p.yz = (p.y > p.z) ? p.yz : p.zy;
    p = sclFac * p - b;
    p.z += b.z * step (p.z, -0.5 * b.z);
  }
  return 0.8 * PrBoxDf (p, vec3 (1.)) / pow (sclFac, nIt);
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
  d = 0.1;
  for (int j = 0; j < 30; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += min (0.2, 3. * h);
    if (sh < 0.001) break;
  }
  return 0.7 + 0.3 * sh;
}

vec3 BgCol (vec3 rd)
{
  float t, gd, b;
  t = tCur * 3.;
  b = dot (vec2 (atan (rd.x, rd.z), 0.5 * pi - acos (rd.y)), vec2 (2., sin (rd.x)));
  gd = clamp (sin (5. * b + t), 0., 1.) * clamp (sin (3.5 * b - t), 0., 1.) +
     clamp (sin (21. * b - t), 0., 1.) * clamp (sin (17. * b + t), 0., 1.);
  return mix (vec3 (0.25, 0.5, 1.), vec3 (0., 0.4, 0.3), 0.5 * (1. - rd.y)) *
     (0.24 + 0.44 * (rd.y + 1.) * (rd.y + 1.)) * (1. + 0.25 * gd);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj, sh;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    sh = ObjSShadow (ro, ltDir);
    col = mix (vec3 (0.2, 0.4, 0.8), BgCol (reflect (rd, vn)), 0.8);
    col = sh * col * (0.4 + 0.2 * max (vn.y, 0.) + 0.5 * max (dot (vn, ltDir), 0.)) +
       0.1 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
  } else col = BgCol (rd);
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
  mPtr = vec4(0.0);// mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 3. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    el = -0.25 * pi * sin (0.02 * pi * tCur);
  }
  el = clamp (el, -0.4 * pi, 0.4 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -30.);
  zmFac = 6. + 2. * sin  (0.07 * pi * tCur);;
  ltDir = normalize (vec3 (1., 1., -1.));
  dstFar = 100.;
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
  glFragColor = vec4 (pow (col, vec3 (0.8)), 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}
