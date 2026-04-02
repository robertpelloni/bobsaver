#version 420

// original https://www.shadertoy.com/view/XslBW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Vinescape" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Endless vines - leon's "Strangler Fig" is too good an idea to pass up

float SmoothMin (float a, float b, float r);
vec2 Rot2D (vec2 q, float a);
float Hashfv2 (vec2 p);
float Noisefv3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 ltDir, qHit;
float dstFar;
int idObj;
const float pi = 3.14159;

vec3 TrackPath (float t)
{
  return vec3 (4. * sin (0.08 * t) + 1.5 * sin (0.11 * t),
     2. * sin (0.09 * t) + 0.4 * sin (0.13 * t), t);
}

float ObjDf (vec3 p)
{
  vec3 q;
  vec2 ip;
  float dMin, hRad, hp, br, tw, d, r, s, a;
  dMin = dstFar;
  p.xy -= TrackPath (p.z).xy;
  ip = floor (p.xz / 10. + 0.5);
  p.xz = p.xz - ip * 10.;
  r = Hashfv2 (vec2 (53., 71.) * ip);
  p.xz = Rot2D (p.xz, 2. * pi * r);
  hRad = 1.5 - 0.015 * p.y - 0.1 * sin (0.5 * pi * p.y);
  hp = 20. + 2. * r;
  a = 2. * pi * p.y / hp;
  p.xz = Rot2D (p.xz, sign (r - 0.5) * (a + 0.1 * r * sin (5. * a)));
  p.x -= 0.5 + 0.1 * r;
  tw = 1.;
  for (int k = 0; k < 8; k ++) {
    tw = - tw;
    s = float (k + 1) / 8.;
    hp = tw * (16. - 10. * s) + r - 0.5;
    br = 0.17 - 0.1 * s + 0.01 * (r - 0.5);
    q = p;
    q.y -= (0.7 * r + 1.3 * s) * hp;
    a = 2. * pi * q.y / hp;
    q.xz = Rot2D (q.xz, sign (r - 0.5) * a + (0.03 * r + 0.3 * s) * sin (3. * a));
    q.x -= hRad + br;
    dMin = SmoothMin (dMin, length (q.xz) - br, 0.2);
  }
  idObj = 1;
  d = length (p.xz) - hRad;
  if (d < dMin + 0.01) idObj = 2;
  dMin = SmoothMin (dMin, d, 0.05);
  dMin = max (dMin, abs (p.y) - dstFar);
  return 0.5 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 200; j ++) {
    d = ObjDf (ro + rd * dHit);
    if (d < 0.0005 || dHit > dstFar) break;
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

float ObjAO (vec3 ro, vec3 rd)
{
  float ao, d;
  ao = 0.;
  for (int j = 0; j < 8; j ++) {
    d = 0.1 + float (j) / 16.;
    ao += max (0., d - 3. * ObjDf (ro + rd * d));
  }
  return 0.5 + 0.5 * clamp (1. - 0.2 * ao, 0., 1.);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 20; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += 0.05;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 vn, col, bgCol, q;
  vec2 ip;
  int idObjT;
  float dHit, vDotL, sh, ao, r, a;
  bgCol = vec3 (0.2, 0.2, 0.3);
  dHit = ObjRay (ro, rd);
  if (dHit < dstFar) {
    ro += rd * dHit;
    idObjT = idObj;
    vn = ObjNf (ro);
    ao = ObjAO (ro, ltDir);
    if (idObjT == 1) col = vec3 (0.5, 0.7, 0.3);
    else {
      q = ro;
      q.xy -= TrackPath (q.z).xy;
      ip = floor (q.xz / 10. + 0.5);
      q.xz = q.xz - ip * 10.;
      r = Hashfv2 (vec2 (23., 31.) * ip);
      q.xz = Rot2D (q.xz, 2. * pi * (r +
         0.02 * (1. + 0.3 * r) * sin (0.5 * pi * (1. - 0.2 * r) * q.y)));
      a = mod (32. * (atan (q.z, - q.x) / (2. * pi)), 1.);
      vn.xz = Rot2D (vn.xz, -0.7 * sin (pi * a * a));
      vn = VaryNf (20. * ro, vn, 1.);
      col = vec3 (0.7, 0.5, 0.3);
    }
    col *= 1. - 0.3 * smoothstep (0.2, 0.8, Noisefv3 (vec3 (80., 50., 80.) * ro));
    vDotL = dot (ltDir, vn);
    sh = ObjSShadow (ro, ltDir);
    col = col * ao * (0.1 + 0.2 * max (- vDotL, 0.) + 0.8 * sh * max (vDotL, 0.)) +
       0.1 * sh * pow (max (dot (normalize (ltDir - rd), vn), 0.), 64.);
    col = mix (col, vec3 (0.2, 0.2, 0.4), smoothstep (0.3, 1., dHit / dstFar));
  } else col = vec3 (0.2, 0.2, 0.4);
  return pow (clamp (col, 0., 1.), vec3 (0.8));
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, pF, pB, u, vd;
  vec2 canvas, uv, ori, ca, sa;
  float az, el, tCur, f;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az = 3. * pi * mPtr.x;
    el = -0.1 * pi + pi * mPtr.y;
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = normalize (vec3 (uv, 1.3));
  pF = TrackPath (2.5 * tCur + 0.1);
  pB = TrackPath (2.5 * tCur - 0.1);
  ro = 0.5 * (pF + pB);
  ro.x += 5.;
  vd = normalize (pF - pB);
  u = - vd.y * vd;
  f = 1. / sqrt (1. - vd.y * vd.y);
  vuMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd) *
     vuMat;
  rd = vuMat * rd;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
  dstFar = 100.;
  glFragColor = vec4 (ShowScene (ro, rd), 1.);
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b, a, h) - r * h * (1. - h);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

const vec4 cHashA4 = vec4 (0., 1., 57., 58.);
const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, cHashA3.xy)) * cHashM);
}

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

float Noisefv3 (vec3 p)
{
  vec4 t1, t2;
  vec3 ip, fp;
  float q;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  q = dot (ip, cHashA3);
  t1 = Hashv4f (q);
  t2 = Hashv4f (q + cHashA3.z);
  return mix (mix (mix (t1.x, t1.y, fp.x), mix (t1.z, t1.w, fp.x), fp.y),
              mix (mix (t2.x, t2.y, fp.x), mix (t2.z, t2.w, fp.x), fp.y), fp.z);
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
  const vec3 e = vec3 (0.1, 0., 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) -
     Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
