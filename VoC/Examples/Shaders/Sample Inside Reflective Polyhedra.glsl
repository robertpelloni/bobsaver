#version 420

// original https://www.shadertoy.com/view/3dd3zr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Inside Reflective Polyhedra" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Multiple reflections involving a sphere with viewpoint inside polyhedron
// Based on "Reflective Polyhedra"

float PrSphDf (vec3 p, float r);
float Minv3 (vec3 p);
float Maxv3 (vec3 p);
vec2 Rot2D (vec2 q, float a);

vec3 ltDir, vc, pMid, vp[3];
float tCur, dstFar;
int idObj, pType;
bool lastRef;
const int idFace = 1, idEdge = 2, idSph = 3;
const float pi = 3.14159;

void PInit ()
{
  vec3 c;
  float cp, sp, t;
  t = 0.02 * tCur;
  //c = vec3 (0., 1., 0.);  // alternatives
  //c = vec3 (0., 0., 1.);
  //pType = int (mod (t, 3.)) + 3;
  pType = 5;
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
  if (! lastRef) {
    d = PrSphDf (p, 0.15);
    DMIN (idSph);
  }
  for (int k = 0; k < 5; k ++) {
    p.xy = abs (p.xy);
    p -= 2. * min (0., dot (p, vc)) * vc;
    if (k == pType - 1) break;
  }
  q = p - pMid;
  dv = vec3 (dot (q, vp[0]), dot (q, vp[1]), dot (q, vp[2]));
  d = - Maxv3 (dv);
  DMIN (idFace);
  dv = vec3 (length (q - min (0., q.x) * vec3 (1., 0., 0.)), 
     length (q - min (0., q.y) * vec3 (0., 1., 0.)),
     length (q - min (0., dot (q, vc)) * vc));
  d = Minv3 (dv) - 0.015;
  DMIN (idEdge);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 50; j ++) {
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
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, bgCol, vn;
  float dstObj, nDotL;
  int nRef;
  const int maxRef = 7;
  bgCol = vec3 (0.25, 0.25, 0.3);
  col = bgCol;
  lastRef = false;
  dstObj = ObjRay (ro, rd);
  nRef = 0;
  for (int k = 0; k < maxRef; k ++) {
    lastRef = (k == maxRef - 1);
    if (dstObj < dstFar && (idObj == idFace || idObj == idSph)) {
      ro += dstObj * rd;
      rd = reflect (rd, ObjNf (ro));
      ro += 0.001 * rd;
      dstObj = ObjRay (ro, rd);
      nRef = k + 1;
    } else break;
  }
  if (dstObj < dstFar && ! (idObj == idFace || idObj == idSph)) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == idEdge) col = vec3 (0.8, 0.8, 0.95);
    nDotL = max (dot (vn, ltDir), 0.);
    col = col * (0.2 + 0.2 * max (- dot (vn, ltDir), 0.) + 0.7 * nDotL * nDotL) +
       0.2 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    col = mix (bgCol, col, pow (0.95, 10. * float (nRef) / float (maxRef)));
  }
  return clamp (col, 0., 1.);
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
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az -= 0.04 * pi * tCur;
    el -= 0.031 * pi * tCur;
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -0.3);
  zmFac = 1.5;
  dstFar = 10.;
  ltDir = normalize (vec3 (1., 1., -1.));
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
