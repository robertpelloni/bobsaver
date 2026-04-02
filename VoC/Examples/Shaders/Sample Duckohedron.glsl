#version 420

// original https://www.shadertoy.com/view/MslBDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Duckohedron" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrEllipsDf (vec3 p, vec3 r);
float PrEllCylDf (vec3 p, vec2 r, float h);
float SmoothBump (float lo, float hi, float w, float x);
float SmoothMin (float a, float b, float r);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);

vec3 ltDir, qHit;
float dstFar, tCur;
int idObj;
const int idBdy = 1, idWng = 2, idHead = 3, idBk = 4, idPol = 5;
const float pi = 3.14159;

vec3 IcosSym (vec3 p)
{
  const float dihedIcos = 0.5 * acos (sqrt (5.) / 3.);
  float a, w;
  w = 2. * pi / 3.;
  p.z = abs (p.z);
  p.yz = Rot2D (p.yz, - dihedIcos);
  p.x = - abs (p.x);
  for (int k = 0; k < 4; k ++) {
    p.zy = Rot2D (p.zy, - dihedIcos);
    p.y = - abs (p.y);
    p.zy = Rot2D (p.zy, dihedIcos);
    if (k < 3) p.xy = Rot2D (p.xy, - w);
  }
  p.z = - p.z;
  a = mod (atan (p.x, p.y) + 0.5 * w, w) - 0.5 * w;
  p.yx = vec2 (cos (a), sin (a)) * length (p.xy);
  p.x -= 2. * p.x * step (0., p.x);
  return p;
}

float DukDf (vec3 p)
{
  vec3 q;
  vec2 r, cs;
  float dMin, d, szFac, h, s;
  szFac = 1.2;
  dMin = dstFar / szFac;
  p /= szFac;
  q = p;
  r = vec2 (0.04, 0.06 + 0.01 * clamp (q.z, -0.4, 0.4));
  h = 0.1;
  s = (length (q.xz / r) - 1.) * min (r.x, r.y);
  d = min (max (s, abs (q.y) - h), length (vec2 (s, q.y)) - h);
  if (d < dMin) { dMin = d;  idObj = idBdy;  qHit = q; }
  q = p;
  q.x = abs (q.x);
  q -= vec3 (0.1, 0.06, 0.12);
  cs = vec2 (cos (0.3), sin (0.3));
  q.yz = Rot2Cs (q.yz, cs);
  cs.y = - cs.y;
  q.xy = Rot2Cs (q.xy, cs);
  q.xz = Rot2Cs (q.xz, cs);
  q = q.yxz;
  r = vec2 (0.06, 0.1 + 0.016 * clamp (q.z, -0.4, 0.4));
  h = 0.014;
  s = (length (q.xz / r) - 1.) * min (r.x, r.y);
  d = min (max (s, abs (q.y) - h), length (vec2 (s, q.y)) - h);
  d = SmoothMin (d, dMin, 0.01);
  if (d < dMin) { dMin = d;  idObj = idWng;  qHit = q; }
  q = p;
  q.yz -= vec2 (0.15, -0.08);
  d = PrEllipsDf (q, vec3 (0.08, 0.07, 0.1));
  d = SmoothMin (d, dMin, 0.02);
  if (d < dMin) { dMin = d;  idObj = idHead;  qHit = q; }
  q = p;
  q.yz -= vec2 (0.14, -0.19);
  r = vec2 (0.03, 0.008);
  h = 0.02;
  d = max (PrEllCylDf (q, r, h), - PrEllCylDf (q - vec3 (0., 0., h),
     r - 0.004, 2. * h));
  if (d < dMin) { dMin = d;  idObj = idBk;  qHit = q; }
  return 0.9 * dMin * szFac;
}

float ObjDf (vec3 p)
{
  vec3 pIco, q;
  const vec3 vIco = normalize (vec3 (sqrt(3.), -1., 0.5 * (3. + sqrt(5.))));
  float dMin, d;
  pIco = IcosSym (p);
  q = pIco;
  q.xy += 1.8 * vIco.xy;
  q.xz -= vec2 (0.7, -2.45);
  dMin = DukDf (- q.xzy);
  d = - SmoothMin (0.05 - abs (pIco.z + 2.3), 0.85 - pIco.y, 0.02);
  if (d < dMin) { dMin = d;  idObj = idPol;  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = ObjDf (ro + rd * dHit);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec3 e = vec3 (0.0001, -0.0001, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.01;
  for (int j = 0; j < 30; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += 0.03;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 ObjCol ()
{
  vec3 col, cBdy;
  float s;
  cBdy = vec3 (0.5, 1., 1.);
  if (idObj == idBdy) {
    col = cBdy * (1. - smoothstep (0.02, 0.06, qHit.y) *
       smoothstep (0., 0.14, qHit.z) * 0.1 * SmoothBump (0.3, 0.5, 0.05,
       mod (50. * qHit.x, 1.)));
  } else if (idObj == idWng) {
    col = cBdy * (1. - step (0.004, qHit.y) *
       smoothstep (0., 0.04, qHit.z) * 0.2 * SmoothBump (0.3, 0.5, 0.05,
       mod (100. * qHit.x, 1.)));
  } else if (idObj == idHead) {
    s = length (qHit.yz - vec2 (0.02, -0.05));
    if (s > 0.02) col = cBdy;
    else col = (abs (s - 0.01) < 0.003) ? vec3 (1., 1., 1.) : vec3 (0.3, 0.3, 1.);
  } else if (idObj == idBk) col = vec3 (1., 0.5, 0.);
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 vn, col;
  float dstObj, vDotL, sh;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += rd * dstObj;
    vn = ObjNf (ro);
    if (idObj != idPol) col = ObjCol ();
    else col = (dot (ro, vn) < 0.) ? vec3 (0.7, 0.2, 0.2) : vec3 (0.9, 0.9, 1.);
    vDotL = dot (ltDir, vn);
    sh = ObjSShadow (ro, ltDir);
    col = col * (0.1 + 0.1 * max (- vDotL, 0.) + 0.8 * sh * max (vDotL, 0.)) +
       0.3 * sh * pow (max (dot (normalize (ltDir - rd), vn), 0.), 256.);
  } else col = vec3 (0., 0., 0.2);
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd;
  vec2 canvas, uv, ori, ca, sa;
  float az, el;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0,0.0,0.0,0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  if (mPtr.z > 0.) {
    az = 3. * pi * mPtr.x;
    el = -0.1 * pi + pi * mPtr.y;
  } else {
    az = -0.03 * pi * tCur;
    el = 0.1 * pi * sin (0.05 * pi * tCur);
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = vuMat * normalize (vec3 (uv, 3.));
  ro = vuMat * vec3 (0., 0., -10.);
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
  dstFar = 20.;
  glFragColor = vec4 (ShowScene (ro, rd), 1.);
}

float PrEllipsDf (vec3 p, vec3 r)
{
  return (length (p / r) - 1.) * min (r.x, min (r.y, r.z));
}

float PrEllCylDf (vec3 p, vec2 r, float h)
{
  return max ((length (p.xy / r) - 1.) * min (r.x, r.y), abs (p.z) - h);
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}
