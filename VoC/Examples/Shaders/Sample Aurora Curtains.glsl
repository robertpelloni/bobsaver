#version 420

// original https://www.shadertoy.com/view/4tBcWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Aurora Curtains" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
 The curtain forms seen in the aurora borealis (and australis) are presumably 
 due to wavelike fluctuations in the magnetosphere. Here the auroral effect is 
 achieved using the same technique as for ocean waves (rather than the more 
 complicated scheme in nimitz's "Auroras"). Reminds me of the view near Denali, 
 with enhanced brightness and some speedup (plus you don't have to go out in the 
 cold late at night to see it). Mousing encouraged.
*/

float Noisefv2 (vec2 p);
float Noisefv3 (vec3 p);
float Fbm1 (float p);
vec3 VaryNf (vec3 p, vec3 n, float f);
vec3 HsvToRgb (vec3 c);

float tCur;
const float pi = 3.14159;

float WaveHt (vec2 p)
{
  mat2 qRot = mat2 (0.8, -0.6, 0.6, 0.8);
  vec4 t4, v4;
  vec2 t;
  float wFreq, wAmp, ht;
  wFreq = 1.;
  wAmp = 1.;
  ht = 0.;
  for (int j = 0; j < 3; j ++) {
    p *= qRot;
    t = 0.05 * tCur * vec2 (1., -1.);
    t4 = (p.xyxy + t.xxyy) * wFreq;
    t = vec2 (Noisefv2 (t4.xy), Noisefv2 (t4.zw));
    t4 += 2. * t.xxyy - 1.;
    v4 = (1. - abs (sin (t4))) * (abs (sin (t4)) + abs (cos (t4)));
    ht += wAmp * dot (pow (1. - sqrt (v4.xz * v4.yw), vec2 (8.)), vec2 (1.));
    wFreq *= 2.;
    wAmp *= 0.5;
  }
  return ht;
}

vec4 AurCol (vec3 ro, vec3 rd)
{
  vec4 col, mCol;
  vec3 p, dp;
  float ar;
  dp = rd / rd.y;
  p = ro + (40. - ro.y) * dp;
  col = vec4 (0.);
  mCol = vec4 (0.);
  for (float ns = 0.; ns < 50.; ns ++) {
    p += dp;
    ar = 0.05 - clamp (0.06 * WaveHt (0.01 * p.xz), 0., 0.04);
    mCol = mix (mCol, ar * vec4 (HsvToRgb (vec3 (0.34 + 0.007 * ns, 1., 1. - 0.02 * ns)), 1.), 0.5);
    col += mCol;
  }
  return col;
}

vec3 SkyCol (vec3 rd)
{
  vec3 rds;
  rds = floor (2000. * rd);
  rds = 0.00015 * rds + 0.1 * Noisefv3 (0.0005 * rds.yzx);
  for (int j = 0; j < 19; j ++) rds = abs (rds) / dot (rds, rds) - 0.9;
  return 0.3 * vec3 (1., 1., 0.9) * min (1., 0.5e-3 * pow (min (6., length (rds)), 5.));
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 aCol;
  vec3 col;
  float dstWat, rFac;
  rFac = 1.;
  if (rd.y < 0.) {
    dstWat = - ro.y / rd.y;
    ro += dstWat * rd;
    rd = reflect (rd, VaryNf (3. * ro + 0.2 * tCur, vec3 (0., 1., 0.),
       0.5 * (1. - smoothstep (10., 30., dstWat))));
    rFac = 0.8;
  }
  if (rd.y < 0.04 * Fbm1 (32. * atan (rd.x, - rd.z)) + 0.01) col = vec3 (0.1, 0.1, 0.12);
  else {
    aCol = AurCol (ro, rd);
    col = rFac * ((1. - 0.5 * aCol.a) * SkyCol (rd) + 0.6 * aCol.rgb);
  }
  return pow (clamp (col, 0., 1.), vec3 (0.9));
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd;
  vec2 uv, ori, ca, sa;
  float el, az;
  uv = 2. * gl_FragCoord.xy / resolution.xy - 1.;
  uv.x *= resolution.x / resolution.y;
  tCur = time;
  //mPtr = mouse*resolution.xy;
  //mPtr.xy = mPtr.xy / resolution.xy - 0.5;
  mPtr = vec4(0.0);
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 0.8 * pi * mPtr.x;
    el += 0.3 * pi * mPtr.y;
  } else {
    az += 0.5 * pi * sin (0.005 * pi * tCur);
    el += 0.05 * pi * sin (0.007 * pi * tCur);
  }
  el = clamp (el, -0.35 * pi, 0.1 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 2., -4.);
  rd = vuMat * normalize (vec3 (uv, 2.));
  glFragColor = vec4 (ShowScene (ro, rd), 1.);
}

const float cHashM = 43758.54;

vec2 Hashv2f (float p)
{
  return fract (sin (p + vec2 (0., 1.)) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
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

float Noisefv2 (vec2 p)
{
  vec2 t, ip, fp;
  ip = floor (p);  
  fp = fract (p);
  fp = fp * fp * (3. - 2. * fp);
  t = mix (Hashv2v2 (ip), Hashv2v2 (ip + vec2 (0., 1.)), fp.y);
  return mix (t.x, t.y, fp.x);
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
  for (int i = 0; i < 5; i ++) {
    f += a * Noiseff (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.9375);
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
  vec3 g;
  vec2 e = vec2 (0.1, 0.);
  g = vec3 (Fbmn (p + e.xyy, n), Fbmn (p + e.yxy, n), Fbmn (p + e.yyx, n)) - Fbmn (p, n);
  return normalize (n + f * (g - n * dot (n, g)));
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}
