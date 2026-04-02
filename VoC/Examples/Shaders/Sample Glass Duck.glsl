#version 420

// original https://www.shadertoy.com/view/XslBR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Glass Duck" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrSphDf (vec3 p, float s);
float PrEllipsDf (vec3 p, vec3 r);
float PrEllCylDf (vec3 p, vec2 r, float h);
float SmoothMin (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec3 VaryNf (vec3 p, vec3 n, float f);
vec2 Rot2Cs (vec2 q, vec2 cs);
vec3 HsvToRgb (vec3 c);

vec3 ltDir;
float dstFar, tCur;
int idObj;
const int idBdy = 1, idWng = 2, idHead = 3, idBk = 4, idEye = 5;
const float pi = 3.14159;

float ObjDf (vec3 p)
{
  vec3 q;
  vec2 r;
  const vec2 cs = vec2 (cos (0.3), sin (0.3));
  float dMin, d, h, s;
  dMin = dstFar;
  h = 0.5;
  r = vec2 (0.2, 0.3 + 0.05 * clamp (p.z, -2., 2.));
  s = (length (p.xz / r) - 1.) * min (r.x, r.y);
  d = min (max (s, abs (p.y) - h), length (vec2 (s, p.y)) - h);
  if (d < dMin) { dMin = d;  idObj = idBdy; }
  q = p;
  q.x = abs (q.x);
  q -= vec3 (0.5, 0.3, 0.6);
  q.yz = Rot2Cs (q.yz, cs);
  q.xy = Rot2Cs (q.xy, vec2 (cs.x, - cs.y));
  q.xz = Rot2Cs (q.xz, vec2 (cs.x, - cs.y));
  r = vec2 (0.3, 0.5 + 0.08 * clamp (q.z, -2., 2.));
  h = 0.07;
  s = (length (q.yz / r) - 1.) * min (r.x, r.y);
  d = SmoothMin (min (max (s, abs (q.x) - h), length (vec2 (s, q.x)) - h), dMin, 0.05);
  if (d < dMin) { dMin = d;  idObj = idWng; }
  d = SmoothMin (PrEllipsDf (p - vec3 (0., 0.75, -0.4), vec3 (0.4, 0.35, 0.5)),
     dMin, 0.1);
  if (d < dMin) { dMin = d;  idObj = idHead; }
  q = p - vec3 (0., 0.65, -0.9);
  q.zy = Rot2Cs (q.zy, vec2 (cs.x, - cs.y));
  h = 0.15;
  r = vec2 (0.15, 0.04) * (1. - 0.1 * min (2., max (0., 1. - q.z / h)));
  d = PrEllCylDf (q, r, h);
  q.z -= 0.9 * h;
  d = SmoothMin (max (d, - PrEllCylDf (q, r - 0.02, 2. * h)), dMin, 0.01);
  if (d < dMin) { dMin = d;  idObj = idBk; }
  q = p;
  q.x = abs (q.x);
  d = PrSphDf (q - vec3 (0.245, 0.825, -0.6), 0.125);
  if (d < dMin) { dMin = d;  idObj = idEye; }
  return 0.9 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  const vec3 e = vec3 (0.0001, -0.0001, 0.);
  vec4 v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float MarbVol (vec3 p)
{
  vec3 q;
  float f;
  f = 0.;
  q = p;
  for (int j = 0; j < 5; j ++) {
    q = abs (q) / dot (q, q) - 0.89;
    f += 1. / (1. + abs (dot (p, q)));
  }
  return f;
}

vec3 DukMarb (vec3 ro, vec3 rd)
{
  vec3 col;
  float t;
  col = vec3 (0.);
  t = 0.;
  for (int j = 0; j < 32; j ++) {
    t += 0.02;
    col = mix (HsvToRgb (vec3 (mod (MarbVol (ro + t * rd), 1.), 1., 1. / (1. + t))),
       col, 0.95);  
  }
  return clamp (col, 0., 1.);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.0005;
  for (int j = 0; j < 50; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += 0.01;
    if (sh < 0.03) break;
  }
  return sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 q, vn, vnp, col;
  const vec2 cs = vec2 (cos (0.3), sin (0.3));
  float dstObj, ltDotVn, sh, glit, fr;
  dstFar = 30.;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += rd * dstObj;
    vn = ObjNf (ro);
    q = ro;
    if (idObj != idEye) { 
      col = DukMarb (ro, refract (rd, vn, 0.75));
      if (idObj == idBdy) {
        col *= 1. - smoothstep (0.1, 0.3, ro.y) * smoothstep (0., 0.7, ro.z) * 0.1 *
           SmoothBump (0.3, 0.5, 0.05, mod (20. * ro.x, 1.));
      } else if (idObj == idWng) {
        q.x = abs (q.x);
        q -= vec3 (0.5, 0.3, 0.6);
        q.yz = Rot2Cs (q.yz, cs);
        q.xy = Rot2Cs (q.xy, vec2 (cs.x, - cs.y));
        q.xz = Rot2Cs (q.xz, vec2 (cs.x, - cs.y));
        col *= 1. - step (0.02, q.x) * smoothstep (0., 0.2, q.z) * 0.2 *
           SmoothBump (0.3, 0.5, 0.05, mod (30. * q.y, 1.));
      } else if (idObj == idBk) {
        col = mix (vec3 (0.6, 0.6, 0.9) * max (0.7 - 0.3 * dot (rd, vn), 0.), col,
          smoothstep (-1.1, -0.97, ro.z));
      }
    } else {
       col = mix (vec3 (0.1), vec3 (0.8, 0.7, 0.2) * max (0.7 - 0.3 * dot (rd, vn), 0.),
         smoothstep (0.02, 0.04, length (q.yz - vec2 (0.875, -0.65))));
    }
    sh = ObjSShadow (ro, ltDir);
    ltDotVn = max (0., dot (vn, ltDir));
    vnp = VaryNf (1000. * ro, vn, 2.);
    glit = 500. * step (0.01, ltDotVn) *
       pow (max (0., dot (ltDir, reflect (rd, vn))), 16.) *
       pow (1. - 0.6 * abs (dot (normalize (ltDir - rd), vnp)), 8.);
    col += sh * vec3 (1., 1., 0.5) * (glit +
       0.3 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 256.));
    fr = pow (1. - abs (dot (rd, vn)), 5.);
    col = mix (col, vec3 (0.5) * (0.7 + 0.3 * reflect (rd, vn).y), fr);
  } else {
    col = vec3 (0.5) * (0.7 + 0.3 * rd.y);
  }
  col = pow (clamp (col, 0., 1.), vec3 (0.9));
  return col;
}

void main(void)
{
  mat3 vuMat;
  vec2 mPtr;
  vec3 ro, rd;
  vec2 canvas, uv, ori, ca, sa;
  float az, el;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = mouse.xy*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.15 * pi;
  //if (mPtr.z > 0.) {
  //  az += 2.5 * pi * mPtr.x;
  //  el += 0.3 * pi * mPtr.y;
  //  el = clamp (el, -0.27 * pi, -0.03 * pi);
  //} else {
    az += 3.5 * pi * sin (0.014 * pi * tCur);
    el += 0.12 * pi * sin (0.2 * pi * tCur);
  //}
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = vuMat * normalize (vec3 (uv, 4.));
  ro = vuMat * vec3 (0., 0., -5.);
  ro.y += 0.15;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
  glFragColor = vec4 (ShowScene (ro, rd), 1);
}

float PrSphDf (vec3 p, float s)
{
  return length (p) - s;
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

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + cHashA4) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec4 t;
  vec2 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv4f (dot (ip, cHashA3.xy));
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
}

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int i = 0; i < 3; i ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec3 g;
  float s;
  const vec3 e = vec3 (0.1, 0., 0.);
  s = Fbmn (p, n);
  g = vec3 (Fbmn (p + e.xyy, n) - s, Fbmn (p + e.yxy, n) - s,
     Fbmn (p + e.yyx, n) - s);
  return normalize (n + f * (g - n * dot (n, g)));
}
