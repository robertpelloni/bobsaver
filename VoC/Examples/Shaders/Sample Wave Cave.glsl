#version 420

// original https://www.shadertoy.com/view/7ljXzG

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Wave Cave" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Wave pattern (from "Wave Room 2") projected on cave walls (from "Nautilus" series)

float SmoothBump (float lo, float hi, float w, float x);
mat3 DirToRMatT (vec3 vd, vec3 vu);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Noisefv2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 ltPos, gloPos;
float tCur, dstFar, cvSize;
const float pi = 3.1415927;

#define VAR_ZERO min (frames, 0)

vec3 TrkPath (float t)
{
  return vec3 ((4.7 * sin (t * 0.15 / cvSize) + 2.7 * cos (t * 0.19 / cvSize)) * cvSize, 0., t);
}

float ObjDf (vec3 p)
{
  float s, d;
  p.x -= TrkPath (p.z).x;
  p /= cvSize;
  p += 0.1 * (1. - cos (2. * pi * (p + 0.2 * (1. - cos (2. * pi * p.zxy)))));
  d = 0.5 * cvSize * (length (cos (0.6 * p - 0.5 * sin (1.4 * p.zxy +
     0.4 * cos (2.7 * p.yzx)))) - 1.1);
  return d;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 320; j ++) {
    p = ro + dHit * rd;
    d = ObjDf (p);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e;
  e = vec2 (0.01, -0.01);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd, float dLim)
{
  float sh, d, h;
  sh = 1.;
  d = 0.1;
  for (int j = VAR_ZERO; j < 20; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += max (0.2, h);
    if (sh < 0.05 || d > dLim) break;
  }
  return 0.5 + 0.5 * sh;
}

float WaveHt (vec2 p)
{
  mat2 qRot;
  vec4 t4, v4;
  vec2 t2;
  float wFreq, wAmp, ht, tWav;
  tWav = 0.2 * tCur;
  qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  wFreq = 1.;
  wAmp = 1.;
  ht = 0.;
  for (int j = 0; j < 3; j ++) {
    p *= qRot;
    t4 = (p.xyxy + tWav * vec2 (1., -1.).xxyy) * wFreq;
    t4 += 2. * vec2 (Noisefv2 (t4.xy), Noisefv2 (t4.zw)).xxyy - 1.;
    t4 = abs (sin (t4));
    v4 = (1. - t4) * (t4 + sqrt (1. - t4 * t4));
    t2 = 1. - sqrt (v4.xz * v4.yw);
    t2 *= t2;
    t2 *= t2;
    ht += wAmp * dot (t2, t2);
    wFreq *= 2.;
    wAmp *= 0.5;
  }
  return ht;
}

vec4 WaveNfH (vec2 p)
{
  vec3 v;
  vec2 e;
  e = vec2 (0.01, 0.);
  p *= 2.;
  for (int j = VAR_ZERO; j < 3; j ++) v[j] = WaveHt (p + ((j == 0) ? e.yy : ((j == 1) ? e.xy : e.yx)));
  return vec4 (normalize (vec3 (-0.2 * (v.x - v.yz), e.x)), v.x);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 hn4;
  vec3 vn, col, bgCol, ltVec;
  vec2 u;
  float dstObj, wGlow, sh, atten, ltDist;
  dstObj = ObjRay (ro, rd);
  wGlow = mix ((0.9 + 0.1 * sin (8. * pi * tCur)) * pow (max (dot (rd, normalize (gloPos - ro)), 0.), 1024.),
     0., smoothstep (-0.2, 0.2, length (gloPos - ro) - dstObj));
  bgCol = vec3 (0., 0.1, 0.1);
  col = bgCol;
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    ltVec = ltPos - dstObj * rd;
    ltDist = length (ltVec);
    atten = (1. - smoothstep (0.1, 0.6, ltDist / dstFar)) / (1. + 0.002 * pow (ltDist, 1.5));
    ltVec /= ltDist;
    vn = ObjNf (ro);
    u = vec2 (atan (vn.x, vn.z) + pi, tan (2. * atan (0.5 * asin (vn.y)))) / (2. * pi);
    hn4 = mix (WaveNfH (u), WaveNfH (u - vec2 (1., 0.)), u.x);
    vn = vn * DirToRMatT (normalize (hn4.xyz), vec3 (0., 1., 0.));
    vn = VaryNf (16. * ro, vn, 0.2);
    sh = ObjSShadow (ro, ltVec, ltDist);
    col = mix (vec3 (0.3, 0.9, 0.7), vec3 (0.2, 0.6, 0.9), smoothstep (0.6, 0.7, hn4.w));
    col = col * (0.2 + 0.8 * sh * max (dot (vn, ltVec), 0.)) +
       0.3 * step (0.95, sh) * pow (max (dot (reflect (ltVec, vn), rd), 0.), 32.);
    col = mix (col, bgCol, smoothstep (0.45, 0.95, dstObj / dstFar)) * atten;
  }
  col += wGlow * vec3 (0.5, 0.5, 0.);
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, vd;
  vec2 canvas, uv;
  float el, az, asp, zmFac, t, dVu;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  asp = canvas.x / canvas.y;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az = 2. * pi * mPtr.x;
    el = pi * mPtr.y;
  }
  cvSize = 7.;
  tCur = mod (tCur, 1800.);
  t = 3. * tCur;
  dVu = 2. * SmoothBump (0.25, 0.75, 0.15, mod (tCur / 40., 1.)) - 1.;
  ro = TrkPath (t + 3. * cvSize * dVu);
  ro.x += 2. * (1. - abs (dVu));
  ro.y = 2. + 2. * (1. - abs (dVu));
  vd = TrkPath (t) - ro;
  vuMat = StdVuMat (el + atan (vd.y, length (vd.xz)), az + atan (vd.x, vd.z));
  gloPos = TrkPath (t + 10. * cvSize);
  zmFac = 1.5;
  rd = vuMat * normalize (vec3 (2. * tan (0.5 * atan (uv.x / (asp * zmFac))) * asp * zmFac,
     uv.y, zmFac));
  ltPos = vuMat * vec3 (0., 0.5, 0.);
  dstFar = 50. * cvSize;
  glFragColor = vec4 (ShowScene (ro, rd), 1.);
}

mat3 DirToRMatT (vec3 vd, vec3 vu)
{
  vec3 vc;
  float s;
  vc = cross (vu, vd);
  s = length (vc);
  if (s > 0.) vc /= s;
  return mat3 (vc, cross (vd, vc), vd);
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
  for (int i = 0; i < 5; i ++) {
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
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = Fbmn (p + ((j < 2) ? ((j == 0) ? e.xyy : e.yxy) : ((j == 2) ? e.yyx : e.yyy)), n);
  }
  g = v.xyz - v.w;
  return normalize (n + f * (g - n * dot (n, g)));
}
