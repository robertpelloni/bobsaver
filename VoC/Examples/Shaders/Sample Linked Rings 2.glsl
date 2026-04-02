#version 420

// original https://www.shadertoy.com/view/3sXcRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Linked Rings 2" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrBoxDf (vec3 p, vec3 b);
float PrBox2Df (vec2 p, vec2 b);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Fbm2 (vec2 p);

mat3 vuMat;
vec3 ltDir;
float dstFar, tCur, mobRad;
const float pi = 3.14159;

float MobiusTDf (vec3 p, float r, float b, float rc, float ns)
{
  vec3 q;
  float d, a, na, aq;
  p.xz = Rot2D (p.xz, 0.2 * tCur);
  q = vec3 (length (p.xz) - r, 0., p.y);
  a = atan (p.z, p.x);
  q.xz = Rot2D (q.xz, 0.5 * a);
  d = length (max (abs (q.xz) - b, 0.)) - rc;
  q = p;
  na = floor (ns * atan (q.z, - q.x) / (2. * pi));
  aq = 2. * pi * (na + 0.5) / ns;
  q.xz = Rot2D (q.xz, aq);
  q.x += r;
  q.xy = Rot2D (q.xy, 0.5 * aq);
  d = max (d, - max (PrBoxDf (q, vec3 (1.2, 1.2, 0.33) * b),
    - PrBox2Df (q.xy, vec2 (0.8, 0.8) * b)));
  return 0.7 * d;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float d, a, aq, na;
  p.xz = Rot2D (p.xz, 0.25 * pi);
  q = p;
  q.z = abs (q.z) - 1.4 * mobRad;
  d = MobiusTDf (q, mobRad, 0.5, 0.01, 24.);
  q = p;
  q.y = abs (q.y) - 1.4 * mobRad;
  d = min (d, MobiusTDf (q.xzy, mobRad, 0.5, 0.01, 24.));
  q = p;
  d = min (d, MobiusTDf (q.zxy, mobRad, 0.5, 0.01, 24.));
  return d;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.0005 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = 0; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 BgCol (vec3 rd)
{
  vec2 u;
  float a;
  rd = rd * vuMat;
  a = 0.5 * atan (length (rd.xy), rd.z);
  rd = normalize (vec3 (rd.xy * tan (a), 1.));
  u = vec2 (0.05 * tCur + rd.xy / rd.z);
  return mix (mix (vec3 (0., 0., 0.6), vec3 (1.), 1.4 * Fbm2 (2. * u)),
     vec3 (0.3, 0.3, 0.6), smoothstep (0.35 * pi, 0.4 * pi, a));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 ror, rdr, vn, col;
  float dstObj, dstObjR, reflFac;
  dstObj = ObjRay (ro, rd);
  reflFac = 1.;
  if (dstObj < dstFar) {
    ror = ro + dstObj * rd;
    rdr = reflect (rd, ObjNf (ror));
    ror += 0.01 * rdr;
    dstObjR = ObjRay (ror, rdr);
    if (dstObjR < dstFar) {
      dstObj = dstObjR;
      ro = ror;
      rd = rdr;
      reflFac = 0.7;
    }
  }
  if (dstObj < dstFar) {
    ro += rd * dstObj;
    vn = ObjNf (ro);
    col = vec3 (0.3, 0.3, 0.6) * (0.2 + 0.8 * max (dot (vn, ltDir), 0.) +
       0.5 * pow (max (0., dot (ltDir, reflect (rd, vn))), 32.));
    col = reflFac * mix (col, BgCol (reflect (rd, vn)), 0.5);
  } else col = 0.7 * BgCol (rd);
  return clamp (col, 0., 1.);
}

void main(void)
{
  vec4 mPtr;
  vec3 ro, rd;
  vec2 canvas, uv;
  float el, az;
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
    az -= 0.05 * tCur;
    el -= 0.2 * pi * cos (0.05 * tCur);
  }
  dstFar = 50.;
  mobRad = 2.5;
  vuMat = StdVuMat (el, az);
  rd = vuMat * normalize (vec3 (uv, 2.8));
  ro = vuMat * vec3 (0., 0., -20.);
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
  glFragColor = vec4 (ShowScene (ro, rd), 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
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

const float cHashM = 43758.54;

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

float Noisefv2 (vec2 p)
{
  vec2 t, ip, fp;
  ip = floor (p);  
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = mix (Hashv2v2 (ip), Hashv2v2 (ip + vec2 (0., 1.)), fp.y);
  return mix (t.x, t.y, fp.x);
}

float Fbm2 (vec2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}
