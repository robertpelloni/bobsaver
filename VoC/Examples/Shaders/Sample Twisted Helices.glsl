#version 420

// original https://www.shadertoy.com/view/tdyfWt

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Twisted Helices" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);

vec3 ltDir;
float tCur, dstFar;
int idObj;
const float pi = 3.1415927;

#define VAR_ZERO min (frames, 0)

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float TwTorusDf (vec3 p, float cvOrd, float cvWrapI, float ri, float rc, float rt)
{
  vec2 u;
  float s;
  u = Rot2D (vec2 (length (p.xz) - rc, p.y), cvWrapI * atan (p.z, p.x));
  s = 2. * pi / cvOrd;
  u = Rot2D (u, - s * (floor ((0.5 * pi - atan (u.x, u.y)) / s + 0.5)));
  return 0.4 * (length (vec2 (u.x - ri, u.y)) - rt);
}

float ObjDf (vec3 p)
{
  float dMin, d;
  dMin = dstFar;
  d = TwTorusDf (p, 8., -1., 0.5, 2., 0.25);
  DMIN (1);
  d = TwTorusDf (p, 7., 5., 0.6, 2., 0.21);
  DMIN (2);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 160; j ++) {
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
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn;
  float dstObj, nDotL;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == 1) col4 = vec4 (0.9, 0.9, 0.95, 0.2);
    else if (idObj == 2) col4 = vec4 (0.7, 0.2, 0.1, 0.2);
    nDotL = max (dot (vn, ltDir), 0.);
    col = col4.rgb * (0.2 + 0.8 * nDotL * nDotL) +
       col4.a * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
  } else {
    col = vec3 (0.6, 0.6, 1.) * (0.2 + 0.2 * (rd.y + 1.) * (rd.y + 1.));
  }
  return clamp (col, 0., 1.);
}

#define AA  1   // optional antialiasing

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
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az += 0.03 * pi * tCur;
    el -= 0.05 * pi * sin (0.05 * pi * tCur);
  }
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -15.);
  zmFac = 6.;
  dstFar = 50.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
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
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}
