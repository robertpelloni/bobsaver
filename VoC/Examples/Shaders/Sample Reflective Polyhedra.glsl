#version 420

// original https://www.shadertoy.com/view/3ljSDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Reflective Polyhedra" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Partially reflective varying polyhedra (mouseable).

// Polyhedra based on knighty's "Polyhedron again" (https://www.shadertoy.com/view/XlX3zB)

float PrSphDf (vec3 p, float r);
float SmoothBump (float lo, float hi, float w, float x);
float Minv3 (vec3 p);
float Maxv3 (vec3 p);
vec2 Rot2D (vec2 q, float a);

vec3 ltDir, vc, pMid, vp[3];
float tCur, dstFar;
int idObj, pType;
bool showFace;
const int idFace = 1, idEdge = 2, idSph = 3;
const float pi = 3.14159, phi = 1.618034;

void PInit ()
{
  vec3 c;
  float cp, sp, t;
  t = 0.02 * tCur;
  pType = int (mod (t, 3.)) + 3;
  c = 0.5 * (1. + sin (vec3 (1., 2., 4.) * 4. * pi * t));
  cp = cos (pi / float (pType));
  sp = sqrt (0.75 - cp * cp);
  vc = vec3 (-0.5, - cp, sp);
  vp[0] = vec3 (0., 0., 1.);
  vp[1] = vec3 (sp, 0., 0.5);
  vp[2] = vec3 (0., sp, cp);
  pMid = (length (c) > 0.) ? normalize ((c.x * vp[0] + c.y * vp[1] + c.z * vp[2])) : vec3 (0.);
  vp[1] = normalize (vp[1]);
  vp[2] = normalize (vp[2]);
}

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float ObjDf (vec3 p)
{
  vec3 q, dv;
  float dMin, d;
  dMin = dstFar;
  if (! showFace) {
    d = PrSphDf (p, 0.25);
    DMIN (idSph);
  }
  for (int k = 0; k < 5; k ++) {
    p.xy = abs (p.xy);
    p -= 2. * min (0., dot (p, vc)) * vc;
    if (k == pType - 1) break;
  }
  q = p - pMid;
  if (showFace) {
    dv = vec3 (dot (q, vp[0]), dot (q, vp[1]), dot (q, vp[2]));
    d = Maxv3 (dv);
    DMIN (idFace);
  }
  dv = vec3 (length (q - min (0., q.x) * vec3 (1., 0., 0.)), 
     length (q - min (0., q.y) * vec3 (0., 1., 0.)),
     length (q - min (0., dot (q, vc)) * vc));
  d = Minv3 (dv) - 0.01;
  DMIN (idEdge);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 80; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.001 || dHit > dstFar) break;
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

vec4 SphFib (vec3 v, float n)
{   // Keinert et al's inverse spherical Fibonacci mapping
  vec4 b;
  vec3 vf, vfMin;
  vec2 ff, c;
  float fk, ddMin, dd, a, aMin, z, ni;
  ni = 1. / n;
  fk = pow (phi, max (2., floor (log (n * pi * sqrt (5.) * dot (v.xy, v.xy)) /
     log (phi + 1.)))) / sqrt (5.);
  ff = vec2 (floor (fk + 0.5), floor (fk * phi + 0.5));
  b = vec4 (ff * ni, pi * (fract ((ff + 1.) * phi) - (phi - 1.)));
  c = floor ((0.5 * mat2 (b.y, - b.x, b.w, - b.z) / (b.y * b.z - b.x * b.w)) *
     vec2 (atan (v.y, v.x), v.z - (1. - ni)));
  ddMin = 4.1;
  for (int j = 0; j < 4; j ++) {
    a = dot (ff, vec2 (j - 2 * (j / 2), j / 2) + c);
    z = 1. - (2. * a + 1.) * ni;
    vf = vec3 (sin (2. * pi * fract (phi * a) + vec2 (0.5 * pi, 0.)) * sqrt (1. - z * z), z);
    dd = dot (vf - v, vf - v);
    if (dd < ddMin) {
      ddMin = dd;
      vfMin = vf;
      aMin = a;
    }
  }
  return vec4 (aMin, vfMin);
}

vec3 BgCol (vec3 rd)
{
  vec3 c;
  vec2 f;
  f = mod (64. * vec2 (atan (rd.z, - rd.x), asin (rd.y)) / pi, 1.);
  c = 0.5 * mix (vec3 (0.2, 0.3, 0.6), vec3 (0.7, 0.7, 0.4),
     max (SmoothBump (0.47, 0.53, 0.01, f.x), SmoothBump (0.47, 0.53, 0.01, f.y))) *
     (0.7 + 0.3 * rd.y);
  c = max (c, 0.5 * vec3 (1., 1., 0.) * (1. - smoothstep (0.01, 0.015,
     length (SphFib (rd, 2048.).yzw - rd))));
  return c;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj, nDotL;
  showFace = false;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    vn = ObjNf (ro + dstObj * rd);
    nDotL = max (dot (vn, ltDir), 0.);
    if (idObj == idEdge) {
      nDotL *= nDotL;
      nDotL *= nDotL;
      col = vec3 (0.5, 0.3, 0.1);
    } else if (idObj == idSph) {
      col = vec3 (0.5, 0.7, 0.7);
    }
    col = col * (0.2 + 0.8 * nDotL) +
       0.2 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
  } else col = BgCol (rd);
  showFace = true;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    vn = ObjNf (ro + dstObj * rd);
    if (idObj == idFace) {
      col = mix (col * vec3 (0.5, 1., 0.5), BgCol (reflect (rd, vn)),
         1. - pow (max (- dot (rd, vn), 0.), 5.));
    } else if (idObj == idEdge) {
      nDotL = max (dot (vn, ltDir), 0.);
      nDotL *= nDotL;
      col = vec3 (0.5, 0.3, 0.1) * (0.2 + 0.8 * nDotL * nDotL) +
         0.2 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    }
  } else col = BgCol (rd);
  return pow (clamp (col, 0., 1.), vec3 (0.8));
}

#define AA  1

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az += 0.03 * pi * tCur;
    el -= 0.1 * pi * sin (0.02 * pi * tCur);
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -8.);
  zmFac = 6.5;
  dstFar = 20.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
  PInit ();
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
  glFragColor = vec4 (pow (col, vec3 (0.9)), 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
}

float Maxv3 (vec3 p)
{
  return max (p.x, max (p.y, p.z));
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}
