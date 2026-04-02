#version 420

// original https://www.shadertoy.com/view/3ltSDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Caged Kryptonite" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  Object shape based on varying Voronoi displacements.
  Motivated by Shane's "Geometric Cellular Surfaces", but with a lot less work,
  so no need for texture storage.
*/

mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float SmoothMin (float a, float b, float r);
float SmoothMax (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec3 Hashv3v3 (vec3 p);
float Noisefv3 (vec3 p);
float Fbm1 (float p);

vec3 ltDir;
float dstFar, tCur;
int idObj;
const float pi = 3.14159;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float VPoly (vec3 p)
{
  vec3 ip, fp, g, w, wm;
  float s, sm, d, wo;
  ip = floor (p);
  fp = fract (p);
  wo = 0.2 * sin (0.4 * tCur);
  sm = 4.;
  for (float gz = -1.; gz <= 1.; gz ++) {
    for (float gy = -1.; gy <= 1.; gy ++) {
      for (float gx = -1.; gx <= 1.; gx ++) {
        g = vec3 (gx, gy, gz);
        w = g + 0.5 * Hashv3v3 (ip + g) + wo - fp;
        s = dot (w, w);
        if (s < sm) {
          sm = s;
          wm = w;
        }
      }
    }
  }
  d = 4.;
  for (float gz = -1.; gz <= 1.; gz ++) {
    for (float gy = -1.; gy <= 1.; gy ++) {
      for (float gx = -1.; gx <= 1.; gx ++) {
        g = vec3 (gx, gy, gz);
        w = g + 0.5 * Hashv3v3 (ip + g) + wo - fp - wm;
        s = dot (w, w);
        if (s > 1e-3) d = SmoothMin (d, dot (0.5 * (w + 2. * wm), w / sqrt (s)), 0.15);
      }
    }
  }
  return d;
}

float ObjDf (vec3 p)
{
  float dMin, d, dh, w;
  dMin = dstFar;
  d = length (p) - 1.;
  if (d < 0.5) {
    w = (0.1 + 0.9 * SmoothBump (0.1, 0.9, 0.05, mod (0.05 * tCur, 1.))) *
       VPoly (3. * normalize (p));
    dh = SmoothMin (d + 0.1, SmoothMax (d - 0.2, 0.08 - w, 0.1) +
       0.1 * (1. - 0.7 * smoothstep (0.1, 0.4, w)), 0.1);
    d = SmoothMax (abs (d), w, 0.05) - 0.05;
    DMIN (1);
    d = dh + 0.01 * Noisefv3 (64. * p);
    DMIN (2);
  } else dMin = d;
  return 0.5 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 120; j ++) {
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
  e = vec2 (0.0002, -0.0002);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 BgCol (vec3 rd)
{
  vec2 f;
  f = mod (16. * vec2 (atan (rd.z, - rd.x), asin (rd.y)) / pi, 1.);
  return 0.5 * mix (vec3 (0.2, 0.3, 0.6), vec3 (0.7, 0.7, 0.4),
     max (SmoothBump (0.47, 0.53, 0.01, f.x), SmoothBump (0.47, 0.53, 0.01, f.y))) *
     (0.7 + 0.3 * rd.y);
}

float GlowCol (vec3 ro, vec3 rd, float dstObj)
{
  vec3 dirGlow;
  float dstGlow, brGlow;
  brGlow = 0.;
  dirGlow = - ro;
  dstGlow = length (ro);
  dirGlow /= dstGlow;
  if (dstGlow < dstObj) brGlow = 5. * pow (max (dot (rd, dirGlow), 0.), 128.) / dstGlow;
  return clamp (brGlow * SmoothBump (0.1, 0.9, 0.05, mod (0.05 * tCur, 1.)), 0., 1.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, roo;
  float dstObj, sh, vv;
  roo = ro;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj == 1) col4 = vec4 (0.8, 0.4, 0.2, 0.2);
    else if (idObj == 2) col4 = vec4 (mix (vec3 (0.1, 0.5, 0.2),
       vec3 (0.5, 0.5, 0.1), 0.3 * step (0.5, Noisefv3 (4. * ro +
       4. * Fbm1 (2. * tCur)))), -1.);
    vv = max (dot (vn, ltDir), 0.);
    sh = ObjSShadow (ro, ltDir);
    if (col4.a >= 0.) {
      col = col4.rgb * (0.2 + 0.8 * sh * vv * vv) +
         col4.a * step (0.95, sh) * pow (max (0., dot (ltDir, reflect (rd, vn))), 32.);
      col = mix (col, BgCol (reflect (rd, vn)), 0.3);
    } else {
      vv = max (- dot (vn, rd), 0.);
      col = (0.5 + 0.5 * sh) * col4.rgb * (0.8 + 0.3 * Fbm1 (6.5 * tCur)) *
         (0.6 + 0.4 * vv * vv);
    }
  } else col = 0.3 * BgCol (rd);
  col = mix (col, vec3 (0.3, 1., 0.8), GlowCol (roo, rd, dstObj));
  return clamp (col, 0., 1.);
}

#define AA  0   // optional antialiasing

void main(void)
{
  mat3 vuMat;
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
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az += 0.002 * pi * tCur;
    el -= 0.05 * pi * sin (0.001 * pi * tCur);
  }
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -8.);
  zmFac = 6.;
  dstFar = 20.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
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
  glFragColor = vec4 (pow (col, vec3 (0.8)), 1.);
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

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

const float cHashM = 43758.54;

vec2 Hashv2f (float p)
{
  return fract (sin (p + vec2 (0., 1.)) * cHashM);
}

vec3 Hashv3v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec3 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3))) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
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
