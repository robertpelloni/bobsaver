#version 420

// original https://www.shadertoy.com/view/NtfXzn

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Ten Intersecting Tetrahedra" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1

float PrBox2Df (vec2 p, vec2 b);
float PrTetDf (vec3 p, float d);
float PrDodecDf (vec3 p, float r);
float Maxv2 (vec2 p);
mat3 VToRMat (vec3 v, float a);
vec2 Rot2D (vec2 q, float a);
mat3 StdVuMat (float el, float az);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 ltDir[4], ltCol[4];
float tCur, dstFar;
int idObj;
const float pi = 3.1415927;

#define VAR_ZERO min (frames, 0)

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float TetFrameDf (vec3 p, float w)
{
  vec3 q;
  q = p;
  p = abs (p);
  q = mix (q, q.yzx, step (Maxv2 (p.yz), p.x));
  q = mix (q, q.zxy, step (Maxv2 (p.zx), p.y));
  q = mix (q, vec3 (q.x, - q.yz).yxz, step (q.z, 0.)) - vec3 (-1., 1., 1.) / sqrt (3.);
  return PrBox2Df (vec2 (0.5 * (q.x + q.y), q.z), vec2 (w));
}

float ObjDf (vec3 p)
{
  mat3 m;
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  m = VToRMat (vec3 (0., sin (atan (2. / (sqrt (5.) + 1.)) + vec2 (0.5 * pi, 0.))), 2. * pi / 5.);
  // rotation matrix from "Ico-Twirl", where atan (1. / phi) = 0.55357435
  q = p;
  for (int k = 0; k < 5; k ++) {
    d = TetFrameDf (q, 0.03);
    DMIN (1);
    d = PrTetDf (q, 0.27);
    DMIN (2);
    q = m * q;
  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
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
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float TrObjDf (vec3 p)
{
  return PrDodecDf (p, 0.74);
}

float TrObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 80; j ++) {
    d = TrObjDf (ro + dHit * rd);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 TrObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = TrObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = VAR_ZERO; j < 24; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.6 + 0.4 * sh;
}

float SphHit (vec3 ro, vec3 rd, float rad)
{
  float b, w;
  b = dot (rd, ro);
  w = b * b + rad * rad - dot (ro, ro);
  return (w > 0.) ? - b - sqrt (w) : dstFar;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 sumD, sumS, col, colB, vn, roo;
  float dstObj, dstTrObj, nDotL, sh, s;
  roo = ro;
  s = SphHit (ro, rd, 1.2);
  dstObj = (s < dstFar) ? ObjRay (ro, rd) : dstFar;
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    vn = VaryNf (128. * ro, vn, 0.2);
    if (idObj == 1) col4 = vec4 (0.9, 0.9, 0.9, 0.5);
    else if (idObj == 2) col4 = vec4 (1., 1., 1., 0.2);
    sumD = vec3 (0.);
    sumS = vec3 (0.);
    for (int k = VAR_ZERO; k < 4; k ++) {
      nDotL = max (dot (vn, ltDir[k]), 0.);
      sh = ObjSShadow (ro, ltDir[k]);
      sumD += ltCol[k] * col4.rgb * sh * nDotL * nDotL *
         smoothstep (0.95, 0.98, dot (normalize (3. * ltDir[k] - ro), ltDir[k]));
      sumS += ltCol[k] * col4.a * step (0.95, sh) * pow (max (0., dot (ltDir[k],
         reflect (rd, vn))), 32.);
    }
    col = 0.05 * col4.rgb + 0.95 * sumD + sumS;
  } else {
    col = vec3 (0.1);
  }
  ro = roo;
  dstTrObj = (s < dstFar) ? TrObjRay (ro, rd) : dstFar;
  if (dstTrObj < min (dstObj, dstFar)) {
    ro += dstTrObj * rd;
    vn = TrObjNf (ro);
    colB = vec3 (0.);
    for (int k = VAR_ZERO; k < 4; k ++) {
      nDotL = max (dot (vn, ltDir[k]), 0.);
      colB += ltCol[k] * nDotL * nDotL *
         smoothstep (0.9, 0.95, dot (normalize (3. * ltDir[k] - ro), ltDir[k]));
    }
    colB = vec3 (0.05) + 0.95 * colB;
    col = mix (col, colB, 0.05 + 0.95 * pow (1. - max (- dot (rd, vn), 0.), 5.));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec2 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, e;
  float el, az, zmFac, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = mouse.xy*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.3 * pi;
  //if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  //}
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -7.);
  zmFac = 6.;
  dstFar = 30.;
  e = vec2 (1., -1.);
  for (int k = VAR_ZERO; k < 4; k ++) {
    ltDir[k] = normalize ((k < 2) ? ((k == 0) ? e.xxx : e.xyy) : ((k == 2) ? e.yxy : e.yyx));
    ltDir[k].xy = Rot2D (ltDir[k].xy, 0.13 * pi * tCur);
    ltDir[k].xz = Rot2D (ltDir[k].xz, 0.17 * pi * tCur);
  }
  ltCol[0] = vec3 (1., 0.2, 0.2);
  ltCol[1] = ltCol[0].gbr;
  ltCol[2] = ltCol[0].brg;
  ltCol[3] = 0.8 * ltCol[0].rrg;
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

float Maxv2 (vec2 p)
{
  return max (p.x, p.y);
}

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d;
  d = abs (p) - b;
  return min (Maxv2 (d), 0.) + length (max (d, 0.));
}

float PrTetDf (vec3 p, float d)
{
  vec2 e;
  e = vec2 (1., -1.) / sqrt (3.);
  return max (max (dot (p, e.yxx), dot (p, e.xyx)), max (dot (p, e.xxy), dot (p, e.yyy))) - d;
}

float PrDodecDf (vec3 p, float d)
{
  vec3 e;
  float s;
  e = vec3 ((sqrt (5.) + 1.) / 2., 1., 0.) / sqrt (5.);
  s = 0.;
  for (int k = 0; k < 4; k ++) {
    s = max (s, max (dot (p, e), max (dot (p, e.yzx), dot (p, e.zxy))));
    e.x = - e.x;
    if (k == 1) e.y = - e.y;
  }
  return s - d;
}

mat3 VToRMat (vec3 v, float a)
{
  mat3 m;
  vec3 w, b1, b2, bp, bm;
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  w = (1. - cs.x) * v * v + cs.x;
  b1 = (1. - cs.x) * v.xzy * v.yxz;
  b2 = - cs.y * v.zyx;
  bp = b1 + b2;
  bm = b1 - b2;
  m[0][0] = w.x;  m[1][1] = w.y;  m[2][2] = w.z;
  m[0][1] = bp.x;  m[1][0] = bm.x;
  m[2][0] = bp.y;  m[0][2] = bm.y;
  m[1][2] = bp.z;  m[2][1] = bm.z;
  return m;
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

float Fbmn (vec3 p, vec3 n)
{
  vec3 s;
  float a;
  s = vec3 (0.);
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    s += a * vec3 (Noisefv2 (p.yz), Noisefv2 (p.zx), Noisefv2 (p.xy));
    a *= 0.5;
    p *= 2.;
  }
  return dot (s, abs (n));
}

vec3 VaryNf (vec3 p, vec3 n, float f)
{
  vec4 v;
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  for (int j = VAR_ZERO; j < 4; j ++)
     v[j] = Fbmn (p + ((j < 2) ? ((j == 0) ? e.xyy : e.yxy) : ((j == 2) ? e.yyx : e.yyy)), n);
  g = v.xyz - v.w;
  return normalize (n + f * (g - n * dot (n, g)));
}
