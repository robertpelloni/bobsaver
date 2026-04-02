#version 420

// original https://www.shadertoy.com/view/3sfyW2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Moebius Gears" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrRoundBox2Df (vec2 p, vec2 b, float r);
float Minv3 (vec3 p);
float Maxv3 (vec3 p);
float SmoothMin (float a, float b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Fbm3 (vec3 p);

mat3 vuMat;
vec3 ltDir, qHit;
float dstFar, tCur;
int idObj;
const float pi = 3.14159;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float MobiusTDf (vec3 p, float r, float b, float ns, float da, float dMin)
{
  vec3 q;
  float d, a, t;
  p.xy = vec2 (- p.y, p.x);
  q = vec3 (Rot2D (vec2 (length (p.xz) - r, p.y), 0.5 * atan (p.z, p.x)), 0.).xzy;
  d = PrRoundBox2Df (q.xz, vec2 (b), 0.05);
  DMINQ (1);
  t = 0.15 * tCur + 0.5 * pi * da / ns;
  q = p;
  q.xz = Rot2D (q.xz, t);
  a = 2. * pi * (floor (ns * atan (q.z, - q.x) / (2. * pi)) + 0.5) / ns;
  q.xz = Rot2D (q.xz, a);
  q.x += r;
  q.xy = Rot2D (q.xy, 0.5 * (a + t));
  d = SmoothMin (d, PrRoundBoxDf (q, vec3 (0.6 * b, 2.1 * b, 0.35 * (pi * r / ns)), 0.05), 0.2);
  DMINQ (1);
  return dMin;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, mobRad;
  dMin = dstFar;
  mobRad = 2.5;
  q = p;
  q.x -= mobRad + 0.55;
  dMin = MobiusTDf (q.zxy, mobRad, 0.3, 24., 1., dMin);
  q = p;
  q.x += mobRad + 0.55;
  q.x = - q.x;
  dMin = min (dMin, MobiusTDf (q.zxy, mobRad, 0.3, 24., -1., dMin));
  return 0.7 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 160; j ++) {
    d = ObjDf (ro + dHit * rd);
    dHit += d;
    if (d < 0.001 || dHit > dstFar) break;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.01, -0.01);
  for (int j = 0; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec2 BlkHit (vec3 ro, vec3 rd)
{
  vec3 v, tm, tp, u, qnBlk;
  vec2 qBlk;
  float dn, df, bSize;
  bSize = 20. * dstFar;
  if (rd.x == 0.) rd.x = 0.001;
  if (rd.y == 0.) rd.y = 0.001;
  if (rd.z == 0.) rd.z = 0.001;
  v = ro / rd;
  tp = bSize / abs (rd) - v;
  tm = - tp - 2. * v;
  dn = Maxv3 (tm);
  df = Minv3 (tp);
  if (df > 0. && dn < df) {
    qnBlk = - sign (rd) * step (tm.zxy, tm) * step (tm.yzx, tm);
    u = (v + dn) * rd;
    qBlk = vec2 (dot (u.zxy, qnBlk), dot (u.yzx, qnBlk)) / bSize;
  }
  return qBlk;
}

float BgCol (vec3 ro, vec3 rd, float scl)
{
  vec2 q;
  q = smoothstep (0.03, 0.1, abs (mod (16. * scl * BlkHit (ro, rd) + 0.5, 1.) - 0.5));
  return 1. - min (q.x, q.y);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 vn, col;
  float dstObj, vDotL;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    vDotL = max (dot (vn, ltDir), 0.);
    vDotL *= vDotL;
    col = vec3 (0.85, 0.85, 0.9) * (0.3 + 0.2 * max (- dot (vn, ltDir), 0.) + 0.7 * vDotL * vDotL) +
       0.2 * pow (max (0., dot (ltDir, reflect (rd, vn))), 64.);
    col *= 0.8 + 0.2 * Fbm3 (64. * qHit);
    col = mix (col, vec3 (1.) * BgCol (ro, reflect (rd, vn), 1.), 0.03);
  } else col = vec3 (0.1) * BgCol (ro, rd, 2.);
  return clamp (col, 0., 1.);
}

#define AA  1

void main(void)
{
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
  az = 0.1 * pi * sin (0.01 * pi * tCur);
  el = 0.05 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  }
  dstFar = 50.;
  vuMat = StdVuMat (el, az);
  rd = vuMat * normalize (vec3 (uv, 4.));
  ro = vuMat * vec3 (0., 0., -22.);
  zmFac = 6.;
  ltDir = vuMat * normalize (vec3 (0.2, 0.2, -1.));
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
  glFragColor = vec4 (col, 1.);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrRoundBox2Df (vec2 p, vec2 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
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

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  return fract (sin (dot (p, cHashVA3) + vec4 (0., cHashVA3.xyz)) * cHashM);
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

float Fbm3 (vec3 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 5; i ++) {
    f += a * Noisefv3 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
}
