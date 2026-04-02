#version 420

// original https://www.shadertoy.com/view/lltfRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Hilbert 3D" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// 3D Hilbert curves (algorithm derived from al13n's "Space Filling Curve")

#define AA  0

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrRoundBox2Df (vec2 p, vec2 b, float r);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
vec3 HsvToRgb (vec3 c);
vec3 RotToDir (vec3 v1, vec3 v2, vec3 p);
vec2 Rot2D (vec2 q, float a);
float Fbm2 (vec2 p);

vec3 ltPos, qHilb;
float dstFar, tCur, szFac, cFac, vShift, zDisp;
int idObj, nIter;
bool doSh;
const int maxIter = 5;
const float pi = 3.14159, sqrt3 = 1.73205;

vec3 HilbCrv (vec3 p)
{
  vec3 s;
  vec2 cv;
  float lLen, cLen, dp, xRev, zRev, zAdd;
  cLen = 1. / (2. * cFac - 1.);
  lLen = cFac * cFac * (1. - ((1. - 0.25 * pi) * cFac - 1.) * cLen);
  dp = 1. + cLen;
  xRev = 1.;
  zRev = 1.;
  zAdd = 0.;
  for (int j = 0; j < maxIter; j ++) {
    lLen *= 0.125;
    dp *= 0.5;
    s = sign (p);
    zAdd += lLen * zRev * s.z * (4. - s.y * (2. - s.x));
    if (s.x > 0.) p = p.zxy * vec3 (- s.z, 1., - s.y);
    else if (s.y > 0.) p = p.yxz * vec3 (-1., -1., - s.z);
    else if (s.z > 0.) p = p.yzx * vec3 (1., -1., 1.);
    else p = p.zyx;
    p += dp * vec3 (1., ((s.x + s.y < 0.) ? 1. : -1.), 1.);
    if (s.x + s.z < 0.) xRev = - xRev;
    else if (s.x > 0.) {
      if (s.y != s.z) zRev = - zRev;
    } else zRev = - zRev;
    if (j == nIter - 1) break;
  }
  cv = vec2 (p.y, - p.z) + cLen;
  if (min (cv.x, cv.y) > 0.) p.yz = vec2 (length (cv) - cLen, (atan (cv.x, cv.y) - 0.25 * pi) * cLen);
  else if (p.y + p.z < 0.) p.yz = p.zy * vec2 ( -1., 1.) + vec2 (0., (1. - 0.25 * pi) * cLen);
  else p.z -= (1. - 0.25 * pi) * cLen;
  p.xz *= vec2 (xRev, zRev);
  p.z += zAdd;
  return p;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, w;
  q = p / szFac;
  q.y -= vShift;
  q.xz = Rot2D (q.xz, pi + 0.25 * pi * sin (0.03 * 2. * pi * tCur));
  q = RotToDir (vec3 (-1., 1., 1.) / sqrt3, vec3 (0., 1., 0.), q);
  w = 0.5 / cFac;
  d = PrRoundBoxDf (q, vec3 (1. - 0.26 * w), 0.01);
  if (doSh || d < 0.1) {
    qHilb = HilbCrv (q);
    q = qHilb;
    q.z = mod (q.z + zDisp, w) - 0.5 * w;
    d = max (d, min (PrRoundBox2Df (q.xy, vec2 (0.1 * w), 0.05 * w), PrSphDf (q, 0.4 * w)));
    idObj = 1;
  }
  dMin = 0.7 * szFac * d;
  q = p;
  q.y -= 0.02;
  d = PrCylDf (q.xzy, 0.8, 0.02);
  if (d < dMin) { dMin = d;  idObj = 2; }
  return dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 160; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0001, -0.0001);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  doSh = true;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05) break;
  }
  return 0.4 + 0.6 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, ltDir;
  float dstObj, dstGrnd, vdl, sh, att, h;
  cFac = pow (2., float (nIter));
  zDisp = 1. * tCur / cFac;
  szFac = 1. + 0.8 / cFac;
  vShift = (sqrt3 - 1.3 / cFac) + 0.04;
  doSh = false;
  dstObj = ObjRay (ro, rd);
  dstGrnd = (rd.y < 0.) ? - ro.y / rd.y : dstFar;
  if (min (dstObj, dstGrnd) < dstFar) {
    ltDir = normalize (ltPos);
    if (dstObj < dstGrnd) {
      ro += dstObj * rd;
      vn = ObjNf (ro);
      vdl = max (dot (vn, ltDir), 0.);
      h = 0.05 * zDisp * cFac;
      if (idObj == 1) h += 0.5 + 0.5 * qHilb.z / (cFac * cFac);
      if (idObj == 1 || length (ro.xz) < 0.6) {
        col = HsvToRgb (vec3 (mod (h, 1.), 1., 1.));
        vdl *= vdl * vdl;
      } else col = vec3 (0.5);
    } else {
      ro += dstGrnd * rd;
      vn = vec3 (0., 1., 0.);
      col = vec3 (0.4) * (0.7 + 0.3 * Fbm2 (4. * ro.xz));
      vdl = max (dot (vn, ltDir), 0.);
    }
    att = smoothstep (0.9, 0.95, dot (normalize (ltPos - ro), ltDir));
    sh = ObjSShadow (ro, ltDir);
    col = att * (col * (0.2 + 0.8 * sh * vdl) +
       0.2 * sh * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.));
  } else col = vec3 (0.);
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac, ltEl, ltAz, ns;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 3. * pi * mPtr.x;
    el += 0.7 * pi * mPtr.y;
  }
  el = clamp (el, -0.25 * pi, 0.05 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., sqrt3, -10.);
  zmFac = 5. + 10. * abs (az) / pi;
  ltEl = -0.2 * pi * (1. + 0.2 * sin (0.2 * 2. * pi * tCur));
  ltAz = pi + 0.2 * pi * cos (0.25 * 2. * pi * tCur);
  ltPos = vec3 (0., 0., 20.);
  ltPos.yz = Rot2D (ltPos.yz, ltEl);
  ltPos.xz = Rot2D (ltPos.xz, ltAz);
  dstFar = 100.;
  ns = mod (0.25 * tCur, float (2 * (maxIter - 1) - 1));
  nIter = 2 + int (min (ns, 2. * float (maxIter - 1) - ns));
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

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrRoundBox2Df (vec2 p, vec2 b, float r)
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

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1.,
     0., 1.), c.y);
}

vec3 RotToDir (vec3 v1, vec3 v2, vec3 p)
{
  vec3 n;
  float c;
  n = normalize (cross (v1, v2));
  c = dot (v1, v2);
  return c * p + sin (acos (c)) * cross (n, p) + (1. - c) * dot (n, p) * n;
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
