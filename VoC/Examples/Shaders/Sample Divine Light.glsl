#version 420

// original https://www.shadertoy.com/view/Wd2yWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Divine Light" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrRoundBox2Df (vec2 p, vec2 b, float r);
float Minv3 (vec3 p);
float SmoothMin (float a, float b, float r);
float SmoothMax (float a, float b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Hashfv3 (vec3 p);
float Noisefv3 (vec3 p);
float Fbm1 (float p);

vec3 ltPos, ltAx;
vec2 trkAx, trkAy, trkFx, trkFy;
float dstFar, tCur;
const float pi = 3.14159;

vec3 TrackPath (float t)
{
  return vec3 (dot (trkAx, sin (trkFx * t)), dot (trkAy, sin (trkFy * t)), t);
}

vec3 TrackVel (float t)
{
  return vec3 (dot (trkAx * trkFx, cos (trkFx * t)), dot (trkAy * trkFy, cos (trkFy * t)), 1);
}

float TubeDist (vec3 p)
{
  vec2 s, t;
  float w, a;
  t = p.xy;
  t *= t;
  s = vec2 (sqrt (sqrt (dot (t, t))), p.z) - 0.5;
  t = cos (64. * pi * s);
  w = 0.03 * (1. + 0.1 * t.x * t.y);
  a = 2. * pi * (floor (16. * (atan (p.y, - p.x) / (2. * pi)) + 0.5) / 16.);
  return min (SmoothMax (PrRoundBox2Df (s, vec2 (w), 0.03),
     0.04 - abs (dot (p.yx, sin (a + vec2 (0.5 * pi, 0.)))), 0.01),
     PrRoundBox2Df (s, vec2 (0.5 * w), 0.03));
}

float ObjDf (vec3 p)
{
  vec3 q, db;
  float r;
  q = p;
  q.xy -= TrackPath (q.z).xy;
  r = floor (8. * Hashfv3 (floor (q)));
  q = fract (q);
  if (r >= 4.) q = q.yxz;
  r = mod (r, 4.);
  if (mod (r, 2.) == 0.) q.x = 1. - q.x;
  if (abs (r - 1.5) == 0.5) q.y = 1. - q.y;
  db = vec3 (TubeDist (q), TubeDist (vec3 (q.z, 1. - q.x, q.y)), TubeDist (vec3 (1. - q.yz, q.x)));
  return 0.7 * Minv3 (db);
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
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
  for (int j = 0; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec3 BgCol (vec3 rd)
{
  float t, gd, b;
  t = 4. * tCur;
  b = dot (vec2 (atan (rd.x, rd.y), 0.5 * pi - acos (rd.z)), vec2 (2., sin (rd.x)));
  gd = clamp (sin (5. * b + t), 0., 1.) * clamp (sin (3.5 * b - t), 0., 1.) +
     clamp (sin (21. * b - t), 0., 1.) * clamp (sin (17. * b + t), 0., 1.);
  return mix (vec3 (0.8, 0.5, 0.), vec3 (0.9, 0.4, 0.2), 0.5 + 0.5 * rd.z) *
     (0.12 + 0.22 * (rd.z + 1.) * (rd.z + 1.)) * (2. + 0.3 * gd);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, bgCol, vn, ltVec, ltDir;
  float dstObj, nDotL, ltDist, atten;
  dstObj = ObjRay (ro, rd);
  bgCol = BgCol (rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col4 = vec4 (mix (vec3 (0.75, 0.7, 0.7), vec3 (0.8, 0.7, 0.7),
       smoothstep (0.45, 0.55, Noisefv3 (32. * ro))), 0.1);
    ltVec = ltPos - ro;
    ltDist = length (ltVec);
    ltDir = ltVec / ltDist;
    atten = min (1., 0.2 + smoothstep (0.7, 0.95, dot (ltAx, - ltDir))) / (1. + 0.2 * ltDist * ltDist);
    nDotL = max (dot (vn, ltDir), 0.);
    col = atten * (col4.rgb * (0.2 + 0.8 * nDotL * nDotL) +
       col4.a * pow (max (dot (reflect (rd, vn), ltDir), 0.), 32.));
    col = mix (col, bgCol, 0.1 + 0.9 * smoothstep (0., 0.85, dstObj / dstFar));
  } else col = bgCol;
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, vd, col;
  vec2 canvas, uv;
  float az, el, zmFac, fSpd, t;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += pi * mPtr.x;
    el += 0.5 * pi * mPtr.y;
  }
  trkAx = 0.07 * vec2 (2., 0.9);
  trkAy = 0.07 * vec2 (1.3, 0.66);
  trkFx = vec2 (0.2, 0.23);
  trkFy = vec2 (0.17, 0.24);
  fSpd = 1.;
  t = fSpd * tCur;
  ro = TrackPath (t);
  ro.xy += 0.05 * sin (0.05 * pi * tCur);
  vd = normalize (TrackVel (t));
  vuMat = StdVuMat (el + sin (vd.y), az + atan (vd.x, vd.z));
  zmFac = 2.5;
  rd = vuMat * normalize (vec3 (uv, zmFac));
  rd.xy = Rot2D (rd.xy, 0.07 * pi * (Fbm1 (0.2 * tCur) - 0.5));
  ltPos = ro + vuMat * vec3 (0.1, 0.1, 0.);
  ltAx = vuMat * vec3 (0., 0., 1.);
  dstFar = 50.;
  col = ShowScene (ro, rd);
  glFragColor = vec4 (col, 1.);
}

float PrRoundBox2Df (vec2 p, vec2 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
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

const float cHashM = 43758.54;

float Hashfv3 (vec3 p)
{
  return fract (sin (dot (p, vec3 (37., 39., 41.))) * cHashM);
}

vec2 Hashv2f (float p)
{
  return fract (sin (p + vec2 (0., 1.)) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  return fract (sin (dot (p, cHashVA3) + vec4 (0., cHashVA3.xyz)) * cHashM);
}

float Noiseff (float p)
{
  vec2 t;
  float ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = Hashv2f (ip);
  return mix (t.x, t.y, fp);
}

float Noisefv3 (vec3 p)
{
  vec4 t;
  vec3 ip, fp;
  ip = floor (p);
  fp = fract (p);
  fp *= fp * (3. - 2. * fp);
  t = mix (Hashv4v3 (ip), Hashv4v3 (ip + vec3 (0., 0., 1.)), fp.z);
  return mix (mix (t.x, t.y, fp.x), mix (t.z, t.w, fp.x), fp.y);
}

float Fbm1 (float p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    f += a * Noiseff (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}
