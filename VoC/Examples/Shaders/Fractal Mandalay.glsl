#version 420

// original https://www.shadertoy.com/view/wstXD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Mandalay Fractal" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
 Origin: DarkBeam in www.fractalforums.com
 (http://www.fractalforums.com/amazing-box-amazing-surf-and-variations/'new'-fractal-type-mandalay/).
 Basically, extra transformation is added to Mandelbox fractal;
 see also "Fractal Explorer Multi-res" by Dave_Hoskins (https://www.shadertoy.com/view/MdV3Wz).

 Here, the number of scaling parameters is reduced from 9 to 3, with other simplifications,
 resulting in cubic symmetry (so only need to view one cube face).
 Parameters vary with time (cycle period approx 2 min).
 Additional periodicity in horizontal plane, and original Mandelbox is optionally available.
 See also "Compleat Mandelbox", which focuses on the interior
 (https://www.shadertoy.com/view/ld3fDl).
*/

#define MTYPE  1  // = 0/1 for Mandelbox / Mandalay

#define AA    0   // optional antialiasing

vec3 HsvToRgb (vec3 c);
float Minv3 (vec3 p);
float Maxv3 (vec3 p);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
float ShowInt (vec2 q, vec2 cBox, float mxChar, float val);

vec3 ltDir, pFold;
float tCur, dstFar, mScale, hFold, tSmooth;
int mType;
const float pi = 3.14159;

const float itMax = 8.;

float PPFoldD (vec3 p)
{
  vec3 s;
  p.y = max (p.y, p.z);
  s = vec3 (p.x, max (abs (p.x - pFold.x) - pFold.x, p.y - 4. * pFold.x),
     max (p.x - 2. * pFold.x - pFold.y, p.y - pFold.z));
  return Minv3 (s);
}

vec3 PPFold (vec3 p)
{
  return vec3 (PPFoldD (p), PPFoldD (p.yzx), PPFoldD (p.zxy));
}

float ObjDf (vec3 p)
{
  vec4 p4;
  p.xz = mod (p.xz + 1., 2.) - 1.;
  p4 = vec4 (p, 1.);
  for (float j = 0.; j < itMax; j ++) {
    p4.xyz = 2. * clamp (p4.xyz, -1., 1.) - p4.xyz;
    if (mType == 1) p4.xyz = - sign (p4.xyz) * PPFold (abs (p4.xyz));
    p4 = mScale * p4 / clamp (dot (p4.xyz, p4.xyz), 0.25, 1.) + vec4 (p, 1.);
  }
  return length (p4.xyz) / p4.w;
}

vec3 ObjTDist (vec3 p)
{
  vec4 p4;
  vec3 pMin;
  p.xz = mod (p.xz + 1., 2.) - 1.;
  pMin = vec3 (1.);
  p4 = vec4 (p, 1.);
  for (float j = 0.; j < itMax; j ++) {
    p4.xyz = 2. * clamp (p4.xyz, -1., 1.) - p4.xyz;
    if (mType == 1) p4.xyz = - sign (p4.xyz) * PPFold (abs (p4.xyz));
    pMin = min (pMin, abs (p4.xyz));
    p4 = mScale * p4 / clamp (dot (p4.xyz, p4.xyz), 0.25, 1.) + vec4 (p, 1.);
  }
  return pMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.0005, -0.0005);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = 0; j < 40; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.03 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.3 + 0.7 * sh;
}

float ObjAO (vec3 ro, vec3 rd)
{
  float ao, d;
  ao = 0.;
  for (float j = 1.; j < 4.; j ++) {
    d = 0.01 * j;
    ao += max (0., d - ObjDf (ro + d * rd));
  }
  return 0.3 + 0.7 * clamp (1. - 5. * ao, 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, bgCol, vn;
  float dstObj, sh, ao;
  if (mType == 1) {
    hFold = mod (0.5 * tSmooth, 1.);
    pFold = HsvToRgb (vec3 (hFold, 0.2, 1.));
  }
  mScale = 3.;
  bgCol = vec3 (0.15, 0.15, 0.1);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col = HsvToRgb (vec3 (mod (0.05 + 0.15 * Maxv3 (abs (ObjTDist (ro))), 1.), 0.5, 1.));
    sh = ObjSShadow (ro, ltDir);
    ao = ObjAO (ro, vn);
    col = col * (0.2 + 0.1 * max (- dot (vn, ltDir), 0.) + 0.8 * sh * max (dot (vn, ltDir), 0.)) +
       0.5 * step (0.95, sh) * pow (max (0., dot (ltDir, reflect (rd, vn))), 4.);
    col *= ao;
    col = mix (col, bgCol, smoothstep (0.7, 1., dstObj / dstFar));
  } else col = bgCol;
  return col;
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac, sr, t, asp;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  mType = MTYPE;
  az = 0.25 * pi;
  el = -0.25 * pi;
  zmFac = (mType == 1) ? 20. : 30.;
  t = mod (0.015 * tCur, 2.);
  tSmooth = (floor (32. * t) + smoothstep (0.8, 1., mod (32. * t, 1.))) / 32.;
  if (mPtr.z > 0.) {
    az += pi * mPtr.x;
    zmFac = clamp (20. + 60. * mPtr.y, 4., 50.);
  } else {
    az = -0.5 * pi * (0.5 - abs (tSmooth - 1.));
  }
  el = clamp (el, -0.49 * pi, -0.06 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vec3 (1., 12., 1.);
  if (mType == 0) ro.xz += 1.;
  dstFar = 60.;
  ltDir = normalize (vec3 (1., 1.5, -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  if (false && mType == 1) {
    asp = canvas.x / canvas.y;
    col = mix (col, vec3 (1., 0.7, 0.7),
       ShowInt (vec2 (-0.4, 0.4) + 0.45 * uv / vec2 (asp, 1.),
       0.03 * vec2 (asp, 1.), 3., floor (1000. * hFold + 1e-4)));
  }
  glFragColor = vec4 (col, 1.);
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1., 0., 1.), c.y);
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
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

float DigSeg (vec2 q)
{
  return (1. - smoothstep (0.13, 0.17, abs (q.x))) *
     (1. - smoothstep (0.5, 0.57, abs (q.y)));
}

#define DSG(q) k = kk;  kk = k / 2;  if (kk * 2 != k) d += DigSeg (q)

float ShowDig (vec2 q, int iv)
{
  float d;
  int k, kk;
  const vec2 vp = vec2 (0.5, 0.5), vm = vec2 (-0.5, 0.5), vo = vec2 (1., 0.);
  if (iv == -1) k = 8;
  else if (iv < 2) k = (iv == 0) ? 119 : 36;
  else if (iv < 4) k = (iv == 2) ? 93 : 109;
  else if (iv < 6) k = (iv == 4) ? 46 : 107;
  else if (iv < 8) k = (iv == 6) ? 122 : 37;
  else             k = (iv == 8) ? 127 : 47;
  q = (q - 0.5) * vec2 (1.5, 2.2);
  d = 0.;
  kk = k;
  DSG (q.yx - vo);  DSG (q.xy - vp);  DSG (q.xy - vm);  DSG (q.yx);
  DSG (q.xy + vm);  DSG (q.xy + vp);  DSG (q.yx + vo);
  return d;
}

float ShowInt (vec2 q, vec2 cBox, float mxChar, float val)
{
  float nDig, idChar, s, sgn, v;
  q = vec2 (- q.x, q.y) / cBox;
  s = 0.;
  if (min (q.x, q.y) >= 0. && max (q.x, q.y) < 1.) {
    q.x *= mxChar;
    sgn = sign (val);
    val = abs (val);
    nDig = (val > 0.) ? floor (max (log (val) / log (10.), 0.) + 0.001) + 1. : 1.;
    idChar = mxChar - 1. - floor (q.x);
    q.x = fract (q.x);
    v = val / pow (10., mxChar - idChar - 1.);
    if (idChar == mxChar - nDig - 1. && sgn < 0.) s = ShowDig (q, -1);
    if (idChar >= mxChar - nDig) s = ShowDig (q, int (mod (floor (v), 10.)));
  }
  return clamp (s, 0., 1.);
}
