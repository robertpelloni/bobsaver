#version 420

// original https://www.shadertoy.com/view/dlKGRV

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Hexagonally Discretized Waves" by dr2 - 2023
// License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0

// Wave watching on a hexagonal grid (mouseable)

/*
  No. 7 in "Hexagon Waves" series
    "Cookie Waves"         (wlSSWy)
    "Paper Rolls"          (WlKSRd)
    "Truchet Waves"        (3tScDc)
    "Edible Edifices"      (3ljBWt)
    "Gold Edifices"        (NldSzM)
    "Losing Focus 2"       (sdSBzc)
*/

#define AA  0   // (= 0/1) optional antialiasing

#define VAR_GRID_SIZE   0  // (= 0/1)

#define VAR_ZERO min (nFrame, 0)

vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
float HexEdgeDist (vec2 p, float h);
float Minv3 (vec3 p);
float SmoothMax (float a, float b, float r);
vec3 HsvToRgb (vec3 c);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Noisev2v4 (vec4 p);

vec3 qHit, ltDir;
vec2 cId, cMid;
float dstFar, tCur, hgSize, wavHt, whFac;
int nFrame, idObj;
const float pi = 3.1415927, sqrt3 = 1.7320508;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d;
  dMin = dstFar;
  q = p - vec3 (cMid, wavHt).xzy;
  d = SmoothMax (HexEdgeDist (q.xz, hgSize - 0.005), q.y, 0.1);
  DMINQ (1);
  return dMin;
}

float WaveHt (vec2 p, float tWav)
{ // (from "Barque Fleet")
  vec4 t4;
  vec2 q, t, tw;
  float wFreq, wAmp, h;
  q = p;
  wFreq = 1.;
  wAmp = 1.;
  tw = tWav * vec2 (1., -1.);
  h = 0.;
  for (int j = VAR_ZERO; j < 3; j ++) {
    t4 = wFreq * (q.xyxy + tw.xxyy);
    t4 = abs (sin (t4 + 2. * Noisev2v4 (t4).xxyy - 1.));
    t4 = (1. - t4) * (t4 + sqrt (1. - t4 * t4));
    t = 1. - sqrt (t4.xz * t4.yw);
    t *= t;
    h += wAmp * dot (t, t);
    q *= mat2 (1.6, -1.2, 1.2, 1.6);
    wFreq *= 2.;
    wAmp *= 0.25;
  }
  return h;
}

void SetConf ()
{
  cMid = HexToPix (cId * hgSize);
  wavHt = whFac * WaveHt (0.01 * cMid, 0.1 * tCur);
}

float ObjRay (vec3 ro, vec3 rd)
{ // (mod from "Cookie Waves")
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM;
  float dHit, d, s, eps;
  bool cNu;
  if (rd.x == 0.) rd.x = 0.0001;
  if (rd.z == 0.) rd.z = 0.0001;
  eps = 0.001;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSize / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]), dot (ro.xz, edN[2])) / hgSize;
  dHit = 0.;
  cId = PixToHex (ro.xz / hgSize);
  pM = HexToPix (cId);
  cNu = true;
  for (int j = VAR_ZERO; j < 400; j ++) {
    if (j == 0 || cNu) {
      hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
      s = Minv3 (hv);
      SetConf ();
      cNu = false;
    }
    d = ObjDf (ro + dHit * rd);
    if (dHit + d < s) {
      dHit += d;
    } else {
      dHit = s + eps;
      cId = PixToHex ((ro.xz + dHit * rd.xz) / hgSize);
      pM += sqrt3 * edN[(s == hv.x) ? 0 : ((s == hv.y) ? 1 : 2)];
      cNu = true;
    }
    if (d < eps || dHit > dstFar) break;
  }
  if (d >= eps) dHit = dstFar;
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
  vec3 p;
  vec2 cIdP;
  float sh, d, h;
  sh = 1.;
  d = 0.01;
  cIdP = vec2 (-999.);
  for (int j = VAR_ZERO; j < 30; j ++) {
    p = ro + d * rd;
    cId = PixToHex (p.xz / hgSize);
    if (cId != cIdP) {
      cIdP = cId;
      SetConf ();
    }
    h = ObjDf (p);
    sh = min (sh, smoothstep (0., 0.1 * d, h));
    d += 0.05;
    if (sh < 0.05 || d > 5.) break;
  }
  return 0.7 + 0.3 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, bgCol;
  float dstObj, sh, h, nDotL;
  whFac = 16.;
  dstObj = ObjRay (ro, rd);
  bgCol = vec3 (0.4, 0.4, 0.6);
  col = bgCol;
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    h = clamp (wavHt / (2.4 * whFac), 0., 1.);
    col4 = vec4 (HsvToRgb (vec3 (fract (0.7 * (0.9 - h)), 0.7, 1.)), 0.1);
    col4 *= 1. - 0.1 * ((qHit.y < -0.01) ? smoothstep (0.5, 0.6, sin (4. * pi * qHit.y)) :
       smoothstep (0.5, 0.6, sin (12. * pi * HexEdgeDist (qHit.xz/ hgSize, 1.))));
    sh = ObjSShadow (ro + 0.01 * vn, ltDir);
    nDotL = max (dot (vn, ltDir), 0.);
    col = col4.rgb * (0.2 + 0.3 * max (dot (vn, ltDir * vec3 (-1., 1., -1.)), 0.) +
       0.8 * sh * pow (nDotL, 1.5)) +
       col4.a * step (0.95, sh) * pow (max (dot (reflect (ltDir, vn), rd), 0.), 32.);
    col = mix (col, bgCol, smoothstep (0.8, 1., dstObj / dstFar));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr, sMax;
  nFrame = frames;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
#if VAR_GRID_SIZE
  sMax = 4.;
  hgSize = exp2 (sMax - 0.5 - abs (floor (mod (0.3 * tCur, 2. * sMax)) - sMax + 0.5));
#else
  hgSize = 1.;
#endif
  az = 0.1 * pi;
  el = -0.12 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  }
  el = clamp (el, -0.4 * pi, -0.1 * pi);
  vuMat = StdVuMat (el, az);
  ro = vec3 (2. * cos (0.1 * tCur), 60., tCur);
  zmFac = 3.;
  dstFar = 300.;
  ltDir = normalize (vec3 (1., 0.7, -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    rd = normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    rd = vuMat * rd;
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

vec2 PixToHex (vec2 p)
{
  vec3 c, r, dr;
  c.xz = vec2 ((1./sqrt3) * p.x - (1./3.) * p.y, (2./3.) * p.y);
  c.y = - c.x - c.z;
  r = floor (c + 0.5);
  dr = abs (r - c);
  r -= step (dr.yzx, dr) * step (dr.zxy, dr) * dot (r, vec3 (1.));
  return r.xz;
}

vec2 HexToPix (vec2 h)
{
  return vec2 (sqrt3 * (h.x + 0.5 * h.y), 1.5 * h.y);
}

float HexEdgeDist (vec2 p, float h)
{
  p = abs (p);
  p -= vec2 (0.5, - sqrt3/2.) * min (p.x - sqrt3 * p.y, 0.);
  p.x -= h * sqrt3/2.;
  return sign (p.x) * max (abs (p.x), abs (p.y) - 0.5 * h);
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
}

float SmoothMin (float a, float b, float r)
{
  float h;
  h = clamp (0.5 + 0.5 * (b - a) / r, 0., 1.);
  return mix (b - h * r, a, h);
}

float SmoothMax (float a, float b, float r)
{
  return - SmoothMin (- a, - b, r);
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

const float cHashM = 43758.54;

vec4 Hashv4f (float p)
{
  return fract (sin (p + vec4 (0., 1., 57., 58.)) * cHashM);
}

vec2 Noisev2v4 (vec4 p)
{
  vec4 ip, fp, t1, t2;
  ip = floor (p);
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t1 = Hashv4f (dot (ip.xy, vec2 (1., 57.)));
  t2 = Hashv4f (dot (ip.zw, vec2 (1., 57.)));
  return vec2 (mix (mix (t1.x, t1.y, fp.x), mix (t1.z, t1.w, fp.x), fp.y),
               mix (mix (t2.x, t2.y, fp.z), mix (t2.z, t2.w, fp.z), fp.w));
}