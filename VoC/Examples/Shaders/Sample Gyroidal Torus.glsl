#version 420

// original https://www.shadertoy.com/view/WsjXDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Gyroidal Torus" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1   // optional antialiasing

float PrTorusDf (vec3 p, float ri, float rc);
float Minv3 (vec3 p);
float SmoothMax (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);

vec3 ltDir;
float dstFar;
int idObj;
const float pi = 3.14159;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, rt, rg, tt, ws;
  dMin = dstFar;
  rt = 20.;
  rg = 6.;
  tt = 0.5 * pi;
  ws = 0.2;
  q = p;
  d = PrTorusDf (q.xzy, 1., rt);
  DMIN (1);
  q.xz = vec2 (rt * atan (q.z, - q.x), length (q.xz) - rt);
  q.yz = vec2 (rg * atan (q.z, - q.y), length (q.yz) - rg);
  d = 0.6 * SmoothMax (abs (dot (sin (q), cos (q).yzx)) - ws, abs (q.z) - tt, 0.2);
  DMIN (2);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0002, -0.0002);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.1;
  for (int j = 0; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += clamp (h, 0.1, 0.5);
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, w;
  float dstObj, sh, nDotL;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == 1) col4 = vec4 (1., 0.5, 1., 0.5);
    else if (idObj == 2) {
      col4 = vec4 (1., 0.7, 0.1, 0.3);
      w = mod (8. * ro / pi, 1.);
      col4 *= 0.8 + 0.2 * Minv3 (vec3 (SmoothBump (0.05, 0.95, 0.01, w.x), SmoothBump (0.05, 0.95, 0.01, w.y),
         SmoothBump (0.05, 0.95, 0.01, w.z)));
    }
    sh = ObjSShadow (ro, ltDir);
    nDotL = max (dot (vn, ltDir), 0.);
    col = col4.rgb * (0.2 + 0.8 * sh * nDotL * nDotL) +
       col4.a * step (0.95, sh) * sh * pow (max (dot (normalize (ltDir - rd), vn), 0.), 64.);
  } else col = vec3 (0.6, 0.6, 1.) * (0.2 + 0.2 * (rd.y + 1.) * (rd.y + 1.));
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float tCur, el, az, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0);
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0;
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az += 0.3 * pi * sin (0.1 * pi * tCur);
    el += 0.1 * pi * sin (0.3 * pi * tCur);
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -60.);
  dstFar = 150.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), 2.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrTorusDf (vec3 p, float ri, float rc)
{
  return length (vec2 (length (p.xy) - rc, p.z)) - ri;
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
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

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}
