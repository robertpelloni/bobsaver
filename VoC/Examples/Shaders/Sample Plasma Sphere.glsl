#version 420

// original https://www.shadertoy.com/view/Mtyfzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Plasma Sphere" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Swirling colors; mouse overrides sphere motion.
// Started from plasma idea in "Magnetismic" by nimitz.

#define AA  0

float PrSphAnDf (vec3 p, float r, float w);
float PrTorusDf (vec3 p, float ri, float rc);
vec2 Rot2D (vec2 q, float a);
float SmoothBump (float lo, float hi, float w, float x);
vec3 HueToRgb (float c);
float Fbm3s (vec3 p, float t);

vec3 ltDir, qnHit;
float dstFar, tCur, aRot, redFac;
int idObj;
bool doRot;
const float pi = 3.14159, phi = 1.618034;

float SphFib (vec3 v, float n)
{   // Keinert et al's inverse spherical Fibonacci mapping
  vec4 b;
  vec3 vf;
  vec2 ff, c;
  float fk, ddMin, a, z, ni;
  ni = 1. / n;
  fk = pow (phi, max (2., floor (log (n * pi * sqrt (5.) * dot (v.xy, v.xy)) /
     log (phi + 1.)))) / sqrt (5.);
  ff = vec2 (floor (fk + 0.5), floor (fk * phi + 0.5));
  b = vec4 (ff * ni, pi * (fract ((ff + 1.) * phi) - (phi - 1.)));
  c = floor ((0.5 * mat2 (b.y, - b.x, b.w, - b.z) / (b.y * b.z - b.x * b.w)) *
     vec2 (atan (v.y, v.x), v.z - (1. - ni)));
  ddMin = 4.1;
  for (int j = 0; j < 4; j ++) {
    a = dot (ff, vec2 (j - 2 * (j / 2), j / 2) + c);
    z = 1. - (2. * a + 1.) * ni;
    vf = vec3 (sin (2. * pi * fract (phi * a) + vec2 (0.5 * pi, 0.)) * sqrt (1. - z * z), z);
    ddMin = min (ddMin, dot (vf - v, vf - v));
  }
  return sqrt (ddMin);
}

float FibHole (vec3 p)
{
  return smoothstep (0.032, 0.036, SphFib (p, 2048.));
}

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float ObjDf (vec3 p)
{
  vec3 q;
  float rad, dMin, d;
  dMin = dstFar;
  rad = 1.;
  for (int j = 0; j < 2; j ++) {
    q = p.yzx;
    if (doRot) {
      if (j == 0) q.xz = Rot2D (q.xz, aRot);
      else q.yz = Rot2D (q.yz, aRot);
    }
    d = 0.7 * PrSphAnDf (q, rad, -0.005 + 0.01 * FibHole (normalize (q)));
    DMIN (1);
    rad *= redFac;
  }
  rad = 1.;
  p.xz = Rot2D (p.xz, 0.25 * pi);
  for (int j = 0; j < 3; j ++) {
    q = p;
    if (j == 1) q.xy = Rot2D (q.xy, 0.5 * pi);
    else if (j == 2) q.yz = Rot2D (q.yz, -0.5 * pi);
    d = PrTorusDf (q.xzy, 0.01 * rad, 1.02 * rad);
    DMIN (2);
  }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float d, h;
  d = 0.;
  for (int j = 0; j < 120; j ++) {
    h = ObjDf (ro + d * rd);
    d += h;
    if (h < 0.0005 || d > dstFar) break;
  }
  return d;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.00012, -0.0001);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float BallHit (vec3 ro, vec3 rd, float bRad)
{
  float h, b, d;
  b = dot (rd, ro);
  d = b * b + bRad * bRad - dot (ro, ro);
  h = dstFar;
  if (d > 0.) {
    h = - b - sqrt (d);
    qnHit = (ro + h * rd) / bRad;
  }
  return h;
}

vec4 PlasCol (vec3 p, vec3 rd, float d, float bRad)
{
  vec4 col4, c4;
  vec3 q;
  float w, h;
  h = mod (0.1 * tCur, 1.);
  d += 0.01;
  col4 = vec4 (0.);
  for (int j = 0; j < 64; j ++) {
    q = p + d * rd;
    if (length (q) > bRad || col4.a >= 1.) break;
    q.xz = Rot2D (q.xz, -2. * pi * h);
    w = dot (q, q);
    q /= w + 0.05;
    q.xz = Rot2D (q.xz, q.y);
    q.xy = Rot2D (q.xy, -1.1 * q.z);
    q /= dot (q, q) + 100. * (1.05 + sin (0.17 * tCur));
    c4 = vec4 (HueToRgb (h), 1.) * clamp (4. * Fbm3s (30. * q, 0.5 * tCur) - 2. - w, 0., 1.) +
       vec4 (HueToRgb (mod (h + 0.4, 1.)), 1.) * clamp (4. * Fbm3s (33. * q.yzx, 0.5 * tCur) -
       2. - w, 0., 1.);
    d += (bRad / 64.) * (1. - 0.25 * c4.a);
    col4 += 0.02 * (1. - col4.a) * c4.a * c4;
  }
  return col4;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, bgCol, vn;
  float dstObj, dstBall, c, bRad;
  aRot = doRot ? (2. * pi / 5.) * (floor (0.2 * tCur) + smoothstep (0.7, 1.,
     mod (0.2 * tCur, 1.))) : 0.;
  redFac = 0.98;
  bRad = 0.95;
  dstBall = BallHit (ro, rd, bRad);
  dstObj = ObjRay (ro, rd);
  if (dstBall < min (dstObj, dstFar)) col4 = PlasCol (ro, rd, dstBall, bRad);
  if (dstObj < dstFar) {
    ro += rd * dstObj;
    vn = ObjNf (ro);
    if (idObj == 1) col = vec3 (0.7, 0.7, 0.5);
    else if (idObj == 2) col = vec3 (0.6, 0.8, 0.85);
    if (dot (normalize (ro), vn) < 0.) col *= 0.5;
    col = col * (0.3 + 0.7 * max (dot (vn, ltDir), 0.)) +
       0.1 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    rd = reflect (rd, vn);
  }
  c = max (SmoothBump (0.4, 0.6, 0.05, mod (64. * atan (rd.z, - rd.x) / pi, 1.)),
     SmoothBump (0.4, 0.6, 0.05, mod (64. * asin (rd.y) / pi, 1.)));
  bgCol = mix (vec3 (1., 0.9, 0.8) * (0.4 + 0.2 * rd.y), vec3 (0.1, 0.1, 0.5), c);
  c = (rd.y > max (abs (rd.x), abs (rd.z * 0.25))) ? min (2. * rd.y, 1.) :
     0.05 * (1. + dot (rd, ltDir));
  if (rd.y > 0.) c += 0.5 * pow (clamp (1.05 - 0.5 *
     length (max (abs (rd.xz / rd.y) - vec2 (1., 4.), 0.)), 0., 1.), 8.);
  bgCol += vec3 (0.5, 0.5, 1.) * c + 2. * vec3 (1., 0.9, 0.8) *
     (pow (abs (rd.x), 2048.) + pow (abs (rd.z), 2048.));
  bgCol *= 0.4;
  if (dstBall < min (dstObj, dstFar)) col = mix (((dstObj < dstFar) ? col : bgCol),
     col4.rgb, col4.a);
  else if (dstObj < dstFar) col += 0.2 * bgCol;
  else col = bgCol;
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  //mPtr = mouse*resolution.xy;
  //mPtr.xy = mPtr.xy / canvas - 0.5;
  mPtr = vec4(0.0);
  doRot = true;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 3. * pi * mPtr.x;
    el += 1.5 * pi * mPtr.y;
    doRot = false;
  } else {
    az = 0.25 * pi - 0.03 * pi * tCur;
    el = 0.2 * pi * sin (0.3 * az);
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  zmFac = 3.3;
  ro = vuMat * vec3 (0., 0., -4.);
  ltDir = normalize (vec3 (0., 1., 0.));
  dstFar = 10.;
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.),
       0.5 * pi * (a + 0.5)), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrSphAnDf (vec3 p, float r, float w)
{
  return abs (length (p) - r) - w;
}

float PrTorusDf (vec3 p, float ri, float rc)
{
  return length (vec2 (length (p.xy) - rc, p.z)) - ri;
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
}

vec3 HueToRgb (float c)
{
  return clamp (abs (fract (c + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1., 0., 1.);
}

const float cHashM = 43758.54;

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
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

float Fbm3s (vec3 p, float t)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 4; j ++) {
    f += a * abs (sin (2. * pi * Noisefv3 (p - t)));
    a *= 0.5;
    p *= 3.;
  }
  return f * (1. / 1.875);
}
