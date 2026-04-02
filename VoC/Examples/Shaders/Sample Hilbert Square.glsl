#version 420

// original https://www.shadertoy.com/view/MsGyDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Hilbert Square" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Four Hilbert curves; algorithm adapted from FabriceNeyret2's Hilbert curve generator
// (https://www.shadertoy.com/view/XljSW3)

#define AA  1   // optional antialiasing (0/1 - off/on)

float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);

vec3 ltDir;
float tCur, dstFar, lWid;
const float maxIter = 5.;
const float pi = 3.14159;

vec4 BlkHit (vec3 ro, vec3 rd, vec3 bSize)
{
  vec3 v, tm, tp, qnBlk;
  float dMin, dn, df;
  if (rd.x == 0.) rd.x = 0.001;
  if (rd.y == 0.) rd.y = 0.001;
  if (rd.z == 0.) rd.z = 0.001;
  v = ro / rd;
  tp = bSize / abs (rd) - v;
  tm = - tp - 2. * v;
  dn = max (max (tm.x, tm.y), tm.z);
  df = min (min (tp.x, tp.y), tp.z);
  dMin = dstFar;
  if (df > 0. && dn < df) {
    dMin = dn;
    qnBlk = - sign (rd) * step (tm.zxy, tm) * step (tm.yzx, tm);
  }
  return vec4 (dMin, qnBlk);
}

float LineDrw (vec2 p, vec2 v)
{
  return (dot (p, v) > 0.) ? smoothstep (0.1, 1., abs (dot (p, vec2 (- v.y, v.x)))) : 1.;
}

float HilbDrw (vec2 p, float nIter)
{
  vec4 lr;
  vec2 sp, e;
  e = vec2 (1., 0.);
  lr.xy = e.yx;
  for (float i = 0.; i < maxIter; i ++) {
    sp = step (0.5, p);
    p = 2. * p - sp;
    lr = vec4 ((sp.x > 0.) ? ((sp.y > 0.) ? - e.yx : - e) : ((sp.y > 0.) ? lr.xy : e.yx),
       (sp.x == sp.y) ? e : ((sp.y > 0.) ? - e.yx : e.yx));
    if (sp.x > 0.) {
      p.x = 1. - p.x;
      lr.xz = - lr.xz;
      lr = lr.zwxy;
    }
    if (sp.y > 0.) {
      p = 1. - p.yx;
      lr = - lr.yxwz;
    }
    if (i == nIter - 1.) break;
  }
  p = (p - 0.5) / lWid;
  return min (LineDrw (p, lr.xy), LineDrw (p, lr.zw));
}

float DotDrw (vec2 p, float nIter)
{
  p = mod (pow (2., nIter - 1.) * (2. * p - 1.), 1.) - 0.5;
  return smoothstep (0.1, 1., length (p) / lWid);
}

float MixDrw (vec2 p, float nIter)
{
  return min (HilbDrw (p, nIter), DotDrw (p, nIter));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 bb;
  vec3 col, vn;
  vec2 w, dw;
  float dstBlk, nIter, t, h;
  bb = BlkHit (ro, rd, vec3 (2., 0.01, 2.));
  dstBlk = bb.x;
  if (dstBlk < dstFar) {
    vn = bb.yzw;
    ro += dstBlk * rd;
    col = vec3 (0., 0., 0.2);
    if (vn.y > 0.99) {
      w = 1. - 0.5 * abs (ro.xz);
      t = mod (0.5 * tCur, 2. * maxIter);
      if (t >= maxIter) t = 2. * maxIter - t;
      h = SmoothBump (0.1, 0.9, 0.1, fract (t));
      nIter = 1. + floor (t);
      lWid = 0.02 * pow (1.7, nIter);
      col = mix (vec3 (0.9, 0.9, 1.), mix (vec3 (0.8, 0.8, 0.), vec3 (0.9, 0.9, 1.),
         smoothstep (0.9, 0.91, MixDrw (w, nIter))), h);
      dw = 0.01 * vec2 (sqrt (lWid), 0.);
      vn.xz = vec2 (MixDrw (w - dw, nIter) - MixDrw (w + dw, nIter),
                    MixDrw (w - dw.yx, nIter) - MixDrw (w + dw.yx, nIter));
      vn = normalize (vec3 (h * vn.xz * sign (ro.xz), 250. * dw.x).xzy);
    }
    col = col * (0.2 + 0.8 * max (dot (vn, ltDir), 0.)) +
       0.2 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 64.);
  } else {
    col = vec3 (0.6, 0.6, 1.) * (0.2 + 0.2 * (rd.y + 1.) * (rd.y + 1.));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse.xy*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.2 * pi;
  if (mPtr.z > 0.) {
    az = 2. * pi * mPtr.x;
    el = -0.2 * pi + 0.2 * pi * mPtr.y;
  } else {
    az += 0.03 * pi * tCur;
  }
  el = clamp (el, -0.3 * pi, -0.15 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., -0.3, -7.);
  dstFar = 20.;
  ltDir = vuMat * normalize (vec3 (1., 2., -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.),
       0.5 * pi * (a + 0.5)), 4.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
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
