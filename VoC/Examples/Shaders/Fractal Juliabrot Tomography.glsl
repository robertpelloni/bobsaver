#version 420

// original https://www.shadertoy.com/view/ttsyWf

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Juliabrot Tomography" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
 Inside and outside views of the quaternion Julia set for f(q) = q^3 + c
 Mousing recommended
 Based on "Fractal Tomography", with fractal from iq's "Julia - Quaternion 3"
*/

#define AA   0  // optional antialiasing

float Maxv3 (vec3 p);
float Minv3 (vec3 p);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
mat3 StdVuMat (float el, float az);

vec3 ltDir, slBox, slPos;
float dstFar, tCur, nHit;
const float pi = 3.1415927;

#define VAR_ZERO min (frames, 0)

vec4 QtSqr (vec4 q)
{
  return vec4 (2. * q.w * q.xyz, q.w * q.w - dot (q.xyz, q.xyz));
}

vec4 QtCub (vec4 q)
{
  float b;
  b = dot (q.xyz, q.xyz);
  return vec4 (q.xyz * (3. * q.w * q.w - b), q.w * (q.w * q.w - 3. * b));
}

float ObjDf (vec3 p)
{
  vec4 q, qq, c;
  vec2 b;
  float s, ss, ot;
  q = vec4 (p, 0.).yzwx;
  c = vec4 (0.2727, 0.6818, -0.2727, -0.0909);
  b = vec2 (0.45, 0.55);
  s = 0.;
  ss = 1.;
  ot = 100.;
  nHit = 0.;
  for (int j = VAR_ZERO; j < 256; j ++) {
    ++ nHit;
    qq = QtSqr (q);
    ss *= 9. * dot (qq, qq);
    q = QtCub (q) + c;
    ot = min (ot, length (q.wy - b) - 0.1);
    s = dot (q, q);
    if (s > 32.) break;
  }
  return min (ot, max (0.25 * log (s) * sqrt (s / ss) - 0.001, 0.));
}

vec2 BlkHit (vec3 ro, vec3 rd, vec3 bSize)
{
  vec3 v, tm, tp;
  float dMin, dn, df;
  v = ro / rd;
  tp = bSize / abs (rd) - v;
  tm = - tp - 2. * v;
  dn = Maxv3 (tm);
  df = Minv3 (tp);
  dMin = dstFar;
  if (df > 0. && dn < df) dMin = dn;
  return vec2 (dMin, df);
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec2 d2;
  float dHit, h;
  d2 = BlkHit (ro - slPos, rd, slBox);
  dHit = d2.x;
  if (dHit < dstFar) {
    for (int j = VAR_ZERO; j < 1024; j ++) {
      h = ObjDf (ro + dHit * rd);
      dHit += min (h, 0.005);
      if (h < 0.0002 || dHit > d2.y) break;
    }
  }
  if (dHit > d2.y) dHit = dstFar;
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

vec3 ColFun ()
{
  return (0.6 + 0.4 * cos (log2 (nHit) + 0.1 * tCur + pi * vec3 (0., 0.33, 0.66))) *
     mix (vec3 (0.6, 0.6, 0.3), vec3 (1.), smoothstep (5., 10., nHit));
}

vec3 Illum (vec3 col, vec3 rd, vec3 vn)
{
  return col * (0.1 + 0.1 * max (- dot (vn, ltDir), 0.) + 0.7 * max (dot (vn, ltDir), 0.) +
     0.2 * vec3 (1., 1., 0.5) * pow (max (dot (normalize (ltDir - rd), vn), 0.), 64.));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, colT;
  float dstObj, dstObjT, c, t;
  slBox = vec3 (2., 0.03, 2.);
  t = 50. * mod (0.02 * tCur, 1.);
  t = (1./50.) * (floor (t) + smoothstep (0.9, 1., mod (t, 1.)));
  slPos = vec3 (0., 0.5 - SmoothBump (0.25, 0.75, 0.25, t), 0.);
  dstObj = ObjRay (ro, rd);
  col = (dstObj < dstFar && nHit > 1.) ? Illum (2. * ColFun (), rd, ObjNf (ro + dstObj * rd)) :
     vec3 (0.);
  c = length (col);
  if (c == 0.) dstObj = dstFar;
  slBox = vec3 (2.);
  slPos = vec3 (0.);
  dstObjT = ObjRay (ro, rd);
  if (dstObjT < min (dstObj, dstFar) && nHit > 1.) {
    colT = Illum (0.5 + 1.5 * ColFun (), rd, ObjNf (ro + dstObjT * rd));
    col = (c > 0.) ? mix (col, colT, 0.25) : 0.4 * colT;
  }
  return pow (clamp (col, 0., 1.), vec3 (0.8));
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr, t;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.2 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    t = floor (tCur / 7.) + smoothstep (0.9, 1., mod (tCur / 7., 1.));
    az -= 0.22 * pi * t;
    el -= 0.12 * pi * sin (0.02 * pi * t);
  }
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -6.);
  zmFac = 5.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
  dstFar = 10.;
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

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
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

mat3 StdVuMat (float el, float az)
{
  vec2 ori, ca, sa;
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  return mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
         mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
}
