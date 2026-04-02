#version 420

// original https://www.shadertoy.com/view/WsGfWd

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Decalled Floppy Tube 2" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Surface coordinates; updated to allow variable bend axis direction (using 
// two planar rotations).

/*
  Tube now has squarer shape (original circular tube is an option).

  From the original: "Provides coordinates useful for flexible shapes based on
  generalized toroidal sections (e.g. fish bodies, snakes, wings); preferable
  to sheared coordinates or multiple linear segments."

  Examples include:
    "Decalled Floppy Tube"      https://www.shadertoy.com/view/3l3GD7
    "Planet Reboot 2"           https://www.shadertoy.com/view/Wtc3Rf
    "Multisegment Floppy Tube"  https://www.shadertoy.com/view/tlcGRB
    "Snake Worship"             https://www.shadertoy.com/view/wtyGRD
*/

// #define IS_CIRC

float PrSphDf (vec3 p, float r);
float PrRound4BoxDf (vec3 p, vec3 b, float r);
float PrRound4Box2Df (vec2 p, vec2 b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float SmoothBump (float lo, float hi, float w, float x);

vec3 ltDir, qHit;
float tCur, dstFar, dLoop, sLoop, rCyl, tubRot;
int idObj;
bool isCirc;
const int idTube = 1, idBase = 2, idGrnd = 3;
const float pi = 3.14159, sqrt3 = 1.73205;

#define VAR_ZERO min (frames, 0)

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float ObjDf (vec3 p)
{
  vec3 q;
  vec2 b, c;
  float dMin, d, hBase, aLoop, lb, s, rc;
  dMin = dstFar;
  hBase = 1.6;
  aLoop = 0.25 * pi / sLoop;
  rc = 0.5;
  q = p;
  q.y -= 2. * hBase;
  q.xz = Rot2D (q.xz, tubRot);
  q.xy = Rot2D (q.xy, 0.5 * pi);
  if (isCirc) d = PrSphDf (q, rCyl);
  else d = max (PrRound4BoxDf (vec3 (q.x, Rot2D (q.yz, - tubRot)), vec3 (rCyl - rc), rc),
     -0.01 - q.x);
  q.xy = Rot2D (vec2 (q.x, q.y - dLoop), aLoop - 0.5 * pi);
  b = vec2 (length (q.xy) - dLoop, q.z);
  b.xy = Rot2D (b.xy, tubRot);
  lb = length (b);
  if (isCirc) s = lb - rCyl;
  else s = PrRound4Box2Df (b, vec2 (rCyl - rc), rc);
  d = min (d, max (s, dot (vec2 (q.x, abs (q.y)), sin (aLoop + vec2 (0., 0.5 * pi)))));
  c = Rot2D (q.xy, aLoop) + vec2 (dLoop, 0.);
  if (isCirc) s = PrSphDf (vec3 (Rot2D (q.xy, aLoop) + vec2 (dLoop, 0.), q.z), rCyl);
  else s = max (PrRound4BoxDf (vec3 (Rot2D (vec2 (c.x, q.z), - tubRot), c.y).xzy,
     vec3 (rCyl - rc), rc), -0.01 - c.y);
  d = min (d, s);
  qHit = vec3 (vec2 (atan (q.y, - q.x) * dLoop / (0.25 * pi), atan (b.x, b.y)) / pi, lb);
  DMIN (idTube);
  q = p;
  q.y -= hBase - 0.5 * rCyl;
  d = PrRound4BoxDf (q, vec3 (0.8 * rCyl, hBase - 0.5 * rCyl, 0.8 * rCyl) - 0.05, 0.05);
  DMIN (idBase);
  d = p.y;
  DMIN (idGrnd);
  return 0.8 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 150; j ++) {
    p = ro + dHit * rd;
    d = ObjDf (p);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.005, -0.005);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = VAR_ZERO; j < 40; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
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

float HexEdgeDist (vec2 p)
{
  p = abs (p);
  return (sqrt3/2.) - p.x + 0.5 * min (p.x - sqrt3 * p.y, 0.);
}

vec3 ObjCol (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 vn;
  vec2 p, ip;
  float nDotL, sh, c;
  vn = ObjNf (ro);
  nDotL = max (dot (vn, ltDir), 0.);
  if (idObj == idTube) {
    if (qHit.z < (isCirc ? 0.7 : 0.2) * rCyl) {
      col4 = vec4 (1., 1., 0., 0.2) * (0.2 + 0.8 * smoothstep (0.1, 0.2, qHit.z / rCyl));
    } else {
      p = qHit.xy * vec2 (2. * sqrt3, 3.);
      ip = PixToHex (p);
      c = mod (dot (mod (2. * ip + ip.yx, 3.), vec2 (1., 2.)), 3.);
      if (isCirc) {
        col4 = vec4 (1., 0., 0., 0.2);
        if (c == 1.) col4.rgb = col4.gbr;
        else if (c == 2.) col4.rgb = col4.brg;
        col4 = mix (vec4 (1., 1., 0., 0.2), col4, smoothstep (0.05, 0.1,
           HexEdgeDist (p - HexToPix (ip))));
      } else {
        col4 = (c == 0.) ? vec4 (0.7, 0.6, 0., 0.2) : ((c == 1.) ? vec4 (0.8, 0.8, 0.4, 0.2) :
           vec4 (0.4, 0.2, 0., 0.2));
        col4 *= 0.3 + 0.7 * smoothstep (0.05, 0.07, HexEdgeDist (p - HexToPix (ip)));
      }
    }
    nDotL *= nDotL;
  } else if (idObj == idBase) {
    col4 = vec4 (0.8, 0.8, 0.7, 0.1);
  } else if (idObj == idGrnd) {
    col4 = vec4 (0.4, 0.45, 0.4, 0.);
  }
  sh = ObjSShadow (ro + 0.01 * ltDir, ltDir);
  col4.rgb = col4.rgb * (0.2 + 0.8 * sh * nDotL) +
     col4.a * step (0.95, sh) * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
  return col4.rgb;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col;
  float dstObj, tCyc, t;
#ifdef IS_CIRC
  isCirc = true;
#else
  isCirc = false;
#endif
  tCyc = 10.;
  t = tCur / tCyc;
  tubRot = - mod (15. * t, 2. * pi);
  sLoop = 1./3. + 50. * pow (1. - SmoothBump (0.25, 0.75, 0.24, mod (t, 1.)), 8.);
  dLoop = 6. * sLoop;
  rCyl = 0.8;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    col = ObjCol (ro, rd);
   } else {
    col = vec3 (0.5, 0.5, 0.6);
  }
  return pow (clamp (col, 0., 1.), vec3 (0.8));
}

#define AA  1

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
  el = 0.;
  az = 0.;
  if (mPtr.z > 0.) {
    az -= 2. * pi * mPtr.x;
    el -= pi * mPtr.y;
  } else {
    az -= 0.5 * tCur;
  }
  el = clamp (el, -0.3 * pi, 0.);
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 6., -25.);
  zmFac = 3.;
  rd = vuMat * normalize (vec3 (uv, zmFac));
  dstFar = 70.;
  ltDir = vuMat * normalize (vec3 (0.7, 1., -1.));
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

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float Length4 (vec2 p)
{
  p *= p;
  return pow (dot (p * p, vec2 (1.)), 1./4.);
}

float Length4 (vec3 p)
{
  p *= p;
  return pow (dot (p * p, vec3 (1.)), 1./4.);
}

float PrRound4BoxDf (vec3 p, vec3 b, float r)
{
  return Length4 (max (abs (p) - b, 0.)) - r;
}

float PrRound4Box2Df (vec2 p, vec2 b, float r)
{
  return Length4 (max (abs (p) - b, 0.)) - r;
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

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

