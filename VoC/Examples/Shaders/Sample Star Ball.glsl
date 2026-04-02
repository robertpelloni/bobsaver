#version 420

// original https://www.shadertoy.com/view/WtsfzH

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Star Ball" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1  // optional antialiasing

#define VAR_ZERO min (frames, 0)

float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
vec3 HsvToRgb (vec3 c);
vec3 VaryNf (vec3 p, vec3 n, float f);

float tCur, dstFar;
int idObj;
const float pi = 3.1415927;

#define CosSin(x) (sin ((x) + vec2 (0.5 * pi, 0.)))

vec3 SymCom (vec3 p, vec2 cs, vec2 w)
{
  vec2 f;
  float a;
  p.x = - abs (p.x);
  for (int j = 0; j < 4; j ++) {
    f.y = dot (p.yz, vec2 (cs.x, - cs.y));
    if (f.y > 0.) {
      f.x = dot (p.yz, cs.yx);
      p.yz = vec2 (dot (f, vec2 (cs.y, - cs.x)), dot (f, cs));
    }
    if (j < 3) p.xy = Rot2Cs (p.xy, w);
  }
  return vec3 (p.xy, - p.z);
}

vec3 IcosSym (vec3 p)
{
  vec2 cs;
  cs = CosSin (0.5 * acos (sqrt (5.) / 3.));
  p.yz = Rot2Cs (vec2 (p.y, abs (p.z)), vec2 (cs.x, - cs.y));
  return SymCom (p, cs, CosSin (-2. * pi / 3.));
}

vec3 DodecSym (vec3 p)
{
  vec2 cs;
  cs = CosSin (0.5 * atan (2.));
  p.xz = Rot2Cs (vec2 (p.x, abs (p.z)), cs);
  p.xy = Rot2Cs (p.xy, CosSin (- pi / 10.));
  return SymCom (p, cs, CosSin (-2. * pi / 5.));
}

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float ObjDf (vec3 p)
{
  vec3 q1, q2;
  float dMin, d;
  dMin = dstFar;
  q1 = IcosSym (p);
  q1.z += 0.48;
  q2 = DodecSym (p);
  q2.z += 0.48;
  d = min (0.9 * min (PrCylDf (q1, 0.05 * (0.55 + 1.5 * q1.z), 0.3),
     PrCylDf (q2, 0.05 * (0.55 + 1.5 * q2.z), 0.3)), PrSphDf (p, 0.2));
  DMIN (1);
  d = min (d, max (abs (abs (PrSphDf (p, 0.4)) - 0.04) - 0.01,
     - min (PrCylDf (q1, 0.15 * (0.55 + 1.5 * q1.z), 0.3),
     PrCylDf (q2, 0.15 * (0.55 + 1.5 * q2.z), 0.3))));
  DMIN (2);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
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
  for (int j = VAR_ZERO; j < 50; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.4 + 0.6 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 ltPos[4], ltDir, col, vn, c, dfTot, spTot;
  float dstObj, at, nDotL, sh;
  for (int k = 0; k < 3; k ++) {
    ltPos[k] = vec3 (0., 1., 3.);
    ltPos[k].xz = Rot2D (ltPos[k].xz, float (k) * 2. * pi / 3. - 0.2 * pi * tCur);
  }
  ltPos[3] = vec3 (0., 5., 0.);
  ltPos[3].xy = Rot2D (ltPos[3].xy, pi * (0.05 + 0.04 * sin (0.22 * pi * tCur)));
  ltPos[3].xz = Rot2D (ltPos[3].xz, 0.1 * pi * tCur);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == 2) vn = VaryNf (64. * ro, vn, 0.4);
    dfTot = vec3 (0.);
    spTot = vec3 (0.);
    for (int k = 0; k < 4; k ++) {
      ltDir = normalize (ltPos[k]);
      at = smoothstep (0.6, 0.95, dot (normalize (ltPos[k] - ro), ltDir));
      sh = ObjSShadow (ro + 0.05 * vn, ltDir);
      c = HsvToRgb (vec3 (0.9 - 0.25 * float (k), 0.9, 1.));
      nDotL = max (dot (vn, ltDir), 0.);
      dfTot += c * (0.05 + 0.95 * at * sh * nDotL * nDotL);
      spTot += 0.5 * c * at * step (0.95, sh) * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    }
    col = dfTot + spTot;
  } else {
    col = vec3 (0.1);
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, t, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.07 * pi;
  el = -0.12 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    t = floor (tCur / 3.) + smoothstep (0.9, 1., mod (tCur / 3., 1.));
    az += 0.22 * pi * t;
    el += 0.2 * pi * sin (0.1 * pi * t);
  }
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -5.);
  zmFac = 6.;
  dstFar = 20.;
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
  glFragColor = vec4 (pow (col, vec3 (0.8)), 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1., 0., 1.), c.y);
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

vec2 Rot2Cs (vec2 q, vec2 cs)
{
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
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}
