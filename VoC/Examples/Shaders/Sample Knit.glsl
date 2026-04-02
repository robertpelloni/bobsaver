#version 420

// original https://www.shadertoy.com/view/tsBSDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Knit" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// 3D knit pattern (earlier 2D version is FabriceNeyret2's "Weaving")

float PrTorus4Df (vec3 p, float ri, float rc);
vec2 Rot2D (vec2 q, float a);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 ltDir;
vec2 bSize, cId;
float dstFar, tCur, cDiam;
int idObj;
const float pi = 3.14159;

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  p.y -= 0.5;
  q = p;
  q += vec3 ((q.z + abs (q.x) > 0.25) ? vec2 (0., -0.25) :
     vec2 (((q.x > 0.) ? -0.5 : 0.5), 0.25), -0.25 * q.z * q.z).xzy;
  d = PrTorus4Df (q.xzy, 0.035, 0.5 * cDiam);
  DMIN (1);
  q = p;
  q.z -= cDiam;
  q += vec3 ((q.z + abs (q.x) > 0.25) ? vec2 (0., -0.25) :
     vec2 (((q.x > 0.) ? -0.5 : 0.5), 0.25), -0.25 * q.z * q.z).xzy;
  d = PrTorus4Df (q.xzy, 0.035, 0.5 * cDiam);
  DMIN (2);
  q = p;
  q.z += cDiam;
  q += vec3 ((q.z + abs (q.x) > 0.25) ? vec2 (0., -0.25) :
     vec2 (((q.x > 0.) ? -0.5 : 0.5), 0.25), -0.25 * q.z * q.z).xzy;
  d = PrTorus4Df (q.xzy, 0.035, 0.5 * cDiam);
  DMIN (2);
  return 0.7 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p, rdi;
  vec2 s;
  float dHit, d, eps;
  eps = 0.0005;
  dHit = eps;
  if (rd.x == 0.) rd.x = 0.001;
  if (rd.z == 0.) rd.z = 0.001;
  ro.xz /= bSize;
  rd.xz /= bSize;
  rdi.xz = 1. / rd.xz;
  for (int j = 0; j < 180; j ++) {
    p = ro + dHit * rd;
    cId = floor (p.xz);
    s = (cId + step (0., rd.xz) - p.xz) * rdi.xz;
    d = min (ObjDf (vec3 (bSize * (p.xz - cId - 0.5), p.y).xzy), abs (min (s.x, s.y)) + eps);
    dHit += d;
    if (d < eps || dHit > dstFar) break;
  }
  if (d >= eps) dHit = dstFar;
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0002, -0.0002);
  p.xz -= bSize * (cId + 0.5);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec2 FlatCvHt (vec2 p)
{
  float d, h;
  p = mod (p, vec2 (1., 2. * cDiam)) - 0.5 * vec2 (1., 2. * cDiam);
  d = length (p + ((p.y + abs (p.x) > 0.25) ? vec2 (0., -0.25) :
     vec2 (((p.x > 0.) ? -0.5 : 0.5), 0.25))) - 0.5 * cDiam;
  h = 0.6 * (1. - smoothstep (-0.01, 0.01, abs (d) - 0.05)) * (1. + 2. * p.y * p.y);
  return vec2 (h, d);
}

vec3 FlrCol (vec2 p, vec3 col)
{
  vec3 c;
  vec2 w, w1, w2;
  p += 0.2 * sin (0.5 * tCur + vec2 (0.5 * pi, 0.));
  w1 = FlatCvHt (p);
  w2 = FlatCvHt (p + vec2 (0., cDiam));
  if (w1.x > w2.x) {
    c = vec3 (0.7, 0.65, 0.);
    w = w1;
  } else {
    c = vec3 (0.7, 0.7, 0.75);
    w = w2;
  }
  c *= w.x * (0.2 + 0.8 * cos (0.5 * pi * w.y / 0.06));
  col = max (c, col);
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, bgCol;
  float dstObj, dstFlr, nDotL;
  cDiam = sqrt (0.5);
  bSize = vec2 (1., 2. * cDiam);
  dstObj = ObjRay (ro, rd);
  bgCol = vec3 (0.8, 0.5, 0.6) * (0.2 + 0.2 * (rd.y + 1.) * (rd.y + 1.));
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    col = (idObj == 1) ? vec3 (0.7, 0.65, 0.) : vec3 (0.7, 0.7, 0.75);
    vn = ObjNf (ro);
    vn = VaryNf (128. * ro, vn, 0.3);
    nDotL = max (dot (vn, ltDir), 0.);
    col = col * (0.2 + 0.8 * nDotL * nDotL) +
       0.3 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    col = mix (col, bgCol, smoothstep (0.5, 1., dstObj / dstFar));
  } else if (rd.y < 0.) {
    dstFlr = - ro.y / rd.y;
    if (dstFlr < dstFar) {
      ro += dstFlr * rd;
      col = FlrCol (ro.xz, bgCol);
      col = mix (col, bgCol, smoothstep (0.5, 1., dstFlr / dstFar));
    } else col = bgCol;
  } else {
    col = bgCol;
  }
  return clamp (col, 0., 1.);
}

#define AA  1

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
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.25 * pi;
  if (mPtr.z > 0.) {
    az += 1.5 * pi * mPtr.x;
    el += 0.6 * pi * mPtr.y;
  } else {
    az -= 0.01 * pi * tCur;
    el -= 0.15 * pi * sin (0.02 * pi * tCur);
  }
  el = clamp (el, -0.5 * pi, -0.1 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -10.);
  dstFar = 40.;
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
       sr * (0.667 * a + 0.5) * pi), 5.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (pow (col, vec3 (0.9)), 1.);
}

float PrTorus4Df (vec3 p, float ri, float rc)
{
  vec2 q;
  q = vec2 (length (p.xy) - rc, p.z);
  q *= q;
  return sqrt (sqrt (dot (q * q, vec2 (1.)))) - ri;
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
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
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
