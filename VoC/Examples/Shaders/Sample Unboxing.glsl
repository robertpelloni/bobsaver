#version 420

// original https://www.shadertoy.com/view/WslGzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Unboxing" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Boxes - matryoshka style

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float SmoothMax (float a, float b, float r);
float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
vec3 HsvToRgb (vec3 c);

vec3 ltDir, qHit;
float dstFar, tCur, tBox;
int idObj;
const int nBox = 10;
const float pi = 3.14159;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float DstBoxFlaps (vec3 p, float dMin, int k)
{
  vec4 bSize;
  vec3 q;
  vec2 b;
  float d, fk, szBox, aBox, r, qt;
  fk = float (k) / float (nBox);
  szBox = 1. - 0.5 * fk;
  aBox = -0.5 * pi * SmoothBump (0.32 - 0.2 * fk, 0.68 + 0.2 * fk, 0.13, tBox);
  dMin /= szBox;
  p /= szBox;
  bSize = vec4 (2., 1., 1.5, 0.02);
  p.y -= - bSize.y;
  r = 0.3 * bSize.w;
  q = p;
  d = PrRoundBoxDf (q, bSize.xwz - r, r);
  DMINQ (1 + k);
  q = p;
  q.x = abs (q.x);
  q.xy = Rot2D (q.xy - bSize.xw, aBox) - bSize.yw * vec2 (1., -1.);
  d = PrRoundBoxDf (q, bSize.ywz - r, r);
  DMINQ (1 + k);
  qt = q.x;
  q.x = abs (qt);
  q.xy -= bSize.yw;
  d = PrCylDf (q, 1.3 * bSize.w, bSize.z - 2. * bSize.w);
  DMINQ (1 + nBox);
  q.x = qt - bSize.y;
  q.xy = Rot2D (q.xy, aBox) - bSize.xw * vec2 (0.5, -1.);
  b = vec2 (q.x, abs (q.z)) / bSize.xz;
  d = 0.5 * SmoothMax (PrRoundBoxDf (q, bSize.xwz * vec3 (0.5, 1., 1.) - r, r),
     dot (b, vec2 (1.)) - 0.5, 0.02);
  DMINQ (1 + k);
  q = p;
  q.z = abs (q.z);
  q.zy = Rot2D (q.zy - bSize.zw, aBox) - bSize.yw * vec2 (1., -1.);
  d = PrRoundBoxDf (q, bSize.xwy - r, r);
  DMINQ (1 + k);
  qt = q.z;
  q.z = abs (qt);
  q.zy -= bSize.yw;
  q = q.yzx;
  d = PrCylDf (q, 1.3 * bSize.w, bSize.x - 2. * bSize.w);
  DMINQ (1 + nBox);
  q = q.zxy;
  q.z = qt - bSize.y;
  q.zy = Rot2D (q.zy, aBox) - bSize.zw * vec2 (0.5, -1.);
  b = vec2 (abs (q.x), q.z) / bSize.xz;
  d = 0.5 * SmoothMax (PrRoundBoxDf (q, bSize.xwz * vec3 (1., 1., 0.5) - r, r),
     dot (b, vec2 (1.)) - 0.5, 0.02);
  DMINQ (1 + k);
  return dMin * szBox;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  for (int k = 0; k < nBox; k ++) dMin = DstBoxFlaps (p, dMin, k);
  q = p;
  d = PrSphDf (q, 1. - 0.5 * float (nBox - 1) / float (nBox));
  DMINQ (2 + nBox);
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0002, -0.0002);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = 0; j < 20; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn;
  float dstObj, sh;
  tBox = mod (0.07 * tCur + 0.5, 1.);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    if (idObj <= nBox) {
      col4 = vec4 (HsvToRgb (vec3 (mod (0.1 + float (idObj - 1) / float (nBox), 1.),
         1., 0.9)), 0.1);
      if (idObj == 1 && qHit.y < 0.) col4.rgb *= 0.5 +
         0.5 * smoothstep (0., 0.01, min (abs (qHit.x), abs (qHit.z)));
    } else if (idObj == 1 + nBox) {
      col4 = vec4 (0.9, 0.9, 0., 0.3) * (0.3 + 0.7 * SmoothBump (0.03, 0.97, 0.01,
         mod (2. * qHit.z, 1.)));
    } else if (idObj == 2 + nBox) {
      col4 = vec4 (HsvToRgb (vec3 (mod (0.04 * tCur, 1.), 0.5, 0.8 +
         0.1 * (sin (25. * tCur) + 0.5 * sin (33. * tCur)))), 0.3);
    }
    sh = ObjSShadow (ro, ltDir);
    col = col4.rgb * (0.2 + 0.8 * sh * max (dot (vn, ltDir), 0.) * max (dot (vn, ltDir), 0.)) +
       step (0.9, sh) * sh * col4.a * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
  } else {
    col = vec3 (0.3, 0.3, 0.6) * (0.2 + 0.2 * (rd.y + 1.) * (rd.y + 1.));
  }
  return clamp (col, 0., 1.);
}

#define AA  0

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.205 * pi;
  el = -0.2 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 1.5 * pi * mPtr.y;
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (-0.5, -0.3, -20.);
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
  dstFar = 50.;
  #if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), 5.2));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  col = mix (col, vec3 (0.1, 0.1, 0.7), smoothstep (0.08, 0.1, length (max (abs (uv) -
     vec2 (canvas.x / canvas.y, 1.) + 0.15, 0.))));
  glFragColor = vec4 (pow (col, vec3 (0.9)), 1.);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
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

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1., 0., 1.), c.y);
}
