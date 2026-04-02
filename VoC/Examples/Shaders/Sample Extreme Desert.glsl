#version 420

// original https://www.shadertoy.com/view/MsdBD4

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Extreme Desert" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

/*
  Desert flyover with changing lighting (look around with mouse)

  Based on earlier 'Terrain Explorer' with terrain option derived from 'Sirenian Dawn'
  by nimitz; sand ripples use waveform from 'Rock Garden'.

  Motivation from Shane's 'Desert Sand'
*/

#define FAST_SUN  1    // (0/1) fast lighting changes
#define AA        0    // (0/1) optional antialiasing

float SmoothBump (float lo, float hi, float w, float x);
vec2 Rot2D (vec2 q, float a);
vec3 Noisev3v2 (vec2 p);
float Fbm2 (vec2 p);
float Fbm2s (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 sunDir;
float tCur, dstFar, gFac, hFac, fWav, aWav, smFac, stepFac;
const float pi = 3.14159;

float GrndHt (vec2 p)
{
  mat2 qRot;
  vec3 v;
  vec2 q, t;
  float wAmp, wp, tp, f;
  q = gFac * p;
  qRot = mat2 (0.8, -0.6, 0.6, 0.8) * fWav;
  wAmp = 1.;
  t = vec2 (0.);
  wp = aWav;
  tp = 5.;
  f = 0.;
  for (int j = 0; j < 4; j ++) {
    v = Noisev3v2 (q);
    t += pow (abs (v.yz), vec2 (tp)) - v.yz;
    tp -= 1.;
    f += wAmp * v.x / (1. + dot (t, t));
    wAmp *= - wp;
    wp *= smFac;
    q *= qRot;
  }
  return hFac * (1. + 6. * f / (1. + smoothstep (-0.5, 1.5, f)));
}

float GrndRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, h, s, sLo, sHi;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = 0; j < 200; j ++) {
    p = ro + s * rd;
    h = p.y - GrndHt (p.xz);
    if (h < 0. || s > dstFar) break;
    sLo = s;
    s += stepFac * (max (0.3, 0.6 * h) + 0.008 * s);
  }
  if (h < 0.) {
    sHi = s;
    for (int j = 0; j < 5; j ++) {
      s = 0.5 * (sLo + sHi);
      p = ro + s * rd;
      h = step (0., p.y - GrndHt (p.xz));
      sLo += h * (s - sLo);
      sHi += (1. - h) * (s - sHi);
    }
    dHit = sHi;
  }
  return dHit;
}

vec3 GrndNf (vec3 p, float d)
{
  vec2 e = vec2 (max (0.01, 0.001 * d * d), 0.);
  return normalize (vec3 (GrndHt (p.xz) - vec2 (GrndHt (p.xz + e.xy), GrndHt (p.xz + e.yx)), e.x).xzy);
}

float RippleHt (vec2 p)
{
  vec2 q;
  float s1, s2;
  q = Rot2D (p, -0.02 * pi);
  s1 = abs (sin (4. * pi * abs (q.x + 1.5 * Fbm2s (0.5 * q))));
  s1 = (1. - s1) * (s1 + sqrt (1. - s1 * s1));
  q = Rot2D (p, 0.01 * pi);
  s2 = abs (sin (3.1 * pi * abs (q.x + 1.9 * Fbm2s (0.3 * q))));
  s2 = (1. - s2) * (s2 + sqrt (1. - s2 * s2));
  return mix (s1, s2, 0.1 + 0.8 * smoothstep (0.3, 0.7, Fbm2 (2. * p)));
}

vec4 RippleNorm (vec2 p, vec3 vn, float f)
{
  vec2 e = vec2 (0.002, 0.);
  float h;
  h = RippleHt (p);
  vn.xy = Rot2D (vn.xy, f * (RippleHt (p + e) - h));
  vn.zy = Rot2D (vn.zy, f * (RippleHt (p + e.yx) - h));
  return vec4 (vn, h);
}

vec3 SkyBg (vec3 rd)
{
  return mix (vec3 (0.2, 0.3, 0.7), vec3 (0.5, 0.5, 0.5), pow (1. - max (rd.y, 0.), 8.));
}

vec3 SkyCol (vec3 ro, vec3 rd)
{
  float sd, f;
  ro.xz += tCur;
  sd = max (dot (rd, sunDir), 0.);
  f = Fbm2 (0.1 * (ro + rd * (50. - ro.y) / (rd.y + 0.0001)).xz);
  return mix (SkyBg (rd) + vec3 (1., 1., 0.9) * (0.3 * pow (sd, 32.) + 0.2 * pow (sd, 512.)),
     vec3 (0.9), clamp (1.6 * f * rd.y + 0.1, 0., 1.));
}

vec3 GlareCol (vec3 rd, vec3 sd, vec2 uv)
{
  vec2 e = vec2 (1., 0.);
  return (sd.z > 0.) ? 0.1 * pow (abs (sd.z), 4.) *
     (2. * e.xyy * max (dot (normalize (rd + vec3 (0., 0.3, 0.)), sunDir), 0.) +
     e.xxy * SmoothBump (0.03, 0.05, 0.01, length (uv - 0.7 * sd.xy)) +
     e.yxx * SmoothBump (0.2, 0.23, 0.02, length (uv - 0.5 * sd.xy)) +
     e.xyx * SmoothBump (0.6, 0.65, 0.03, length (uv - 0.3 * sd.xy))) : vec3 (0.);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 vn4;
  vec3 col, vn;
  float dstGrnd, f, spec, sh, dFac;
  dstGrnd = GrndRay (ro, rd);
  if (dstGrnd < dstFar) {
    ro += dstGrnd * rd;
    vn = GrndNf (ro, dstGrnd);
    f = 0.2 + 0.6 * smoothstep (0.7, 1.1, 2. * Fbm2s (16. * ro.xz));
    col = mix (mix (vec3 (0.75, 0.5, 0.1), vec3 (0.65, 0.4, 0.1), f),
       mix (vec3 (1., 0.8, 0.5), vec3 (0.9, 0.7, 0.4), f), smoothstep (1., 3., ro.y));
    col = mix (vec3 (0.7, 0.6, 0.4), col, smoothstep (0.2, 0.5, vn.y));
    spec = mix (0.05, 0.1, smoothstep (2., 3., ro.y));
    dFac = 1. - smoothstep (0.3, 0.4, dstGrnd / dstFar);
    if (dFac > 0. && vn.y > 0.85) {
      f = smoothstep (0.5, 2., ro.y) * smoothstep (0.85, 0.9, vn.y) * dFac;
      vn4 = RippleNorm (ro.xz, vn, 6. * f);
      vn = vn4.xyz;
      col *= mix (1., 0.9 + 0.1 * smoothstep (0.1, 0.3, vn4.w), f);
    }
    if (dFac > 0.) vn = VaryNf (8. * ro, vn, dFac);
    sh = 0.3 + 0.7 * smoothstep (0.3, 0.7, Fbm2 (0.1 * ro.xz + 1.3 * tCur));
    col *= 0.2 + sh * (0.1 * vn.y + 0.7 * max (0., dot (vn, sunDir)) +
       0.1 * max (0., dot (vn, normalize (vec3 (- sunDir.xz, 0.)).xzy))) +
       spec * sh * pow (max (0., dot (sunDir, reflect (rd, vn))), 32.);
    col *= 0.8 + 0.2 * dFac;
    col = mix (col, SkyBg (rd), pow (dstGrnd / dstFar, 4.));
  } else col = SkyCol (ro, rd);
  return clamp (col, 0., 1.);
}

mat3 EvalOri (vec3 v, vec3 a)
{
  vec3 g, w;
  float f, c, s;
  v = normalize (v);
  g = cross (v, vec3 (0., 1., 0.));
  if (g.y != 0.) {
    g.y = 0.;
    w = normalize (cross (g, v));
  } else w = vec3 (0., 1., 0.);
  f = v.z * a.x - v.x * a.z;
  f = - clamp (2. * f, -0.2 * pi, 0.2 * pi);
  c = cos (f);
  s = sin (f);
  w = normalize (cross (w, v));
  return mat3 (w, cross (v, w), v) * mat3 (c, s, 0., - s, c, 0., 0., 0., 1.);
}

vec3 TrackPath (float t)
{
  return vec3 (20. * sin (0.07 * t) * sin (0.022 * t) * cos (0.018 * t) +
     13. * sin (0.0061 * t), 0., t);
}

void main(void)
{
  mat3 flMat, vuMat;
  vec4 mPtr, dateCur;
  vec3 ro, rd, col, fpF, fpB;
  vec2 canvas, uv, uvv, ori, ca, sa;
  float el, az, sunEl, sunAz, dt, tCur, flyVel, mvTot, h, hSum, nhSum;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  dateCur = date;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / resolution.xy - 0.5;
  tCur = mod (tCur + 30., 36000.) + 30. * floor (dateCur.w / 3600.);
  az = 0.;
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.6 * pi * mPtr.y;
  }
  gFac = 0.07;
  hFac = 1.5;
  fWav = 1.9;
  aWav = 0.45;
  smFac = 0.65;
  flyVel = 3.;
  dstFar = 120.;
  stepFac = 0.35;
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  mvTot = flyVel * tCur;
  ro = TrackPath (mvTot);
  dt = 1.;
  fpF = TrackPath (mvTot + dt);
  fpB = TrackPath (mvTot - dt);
  flMat = EvalOri ((fpF - fpB) / (2. * dt), (fpF - 2. * ro + fpB) / (dt * dt));
  hSum = 0.;
  nhSum = 0.;
  for (float fk = -1.; fk <= 5.; fk ++) {
    hSum += GrndHt (TrackPath (mvTot + 0.5 * fk).xz);
    ++ nhSum;
  }
  ro.y = 6. * hFac + hSum / nhSum;
#if FAST_SUN
  sunAz = 0.03 * 2. * pi * tCur;
#else
  sunAz = 0.01 * 2. * pi * tCur;
#endif
  sunEl = pi * (0.2 + 0.1 * sin (0.35 * sunAz));
  sunDir = vec3 (cos (sunAz) * cos (sunEl), sin (sunEl), sin (sunAz) * cos (sunEl));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    uvv = uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.), 0.5 * pi * (a + 0.5));
    rd = normalize (vec3 (uvv, 2.5));
    rd = vuMat * rd;
    rd = flMat * rd;
    col += (1. / naa) * (ShowScene (ro, rd) + GlareCol (rd, sunDir * vuMat, uvv));
  }
  glFragColor = vec4 (pow (col, vec3 (0.9)), 1.);
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
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
}

vec4 Hashv4f (float p)
{
  return fract (sin (p + vec4 (0., 1., 57., 58.)) * cHashM);
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

vec3 Noisev3v2 (vec2 p)
{
  vec4 h;
  vec3 g;
  vec2 ip, fp, ffp;
  ip = floor (p);
  fp = fract (p);
  ffp = fp * fp * (3. - 2. * fp);
  h = Hashv4f (dot (ip, vec2 (1., 57.)));
  g = vec3 (h.y - h.x, h.z - h.x, h.x - h.y - h.z + h.w);
  return vec3 (h.x + dot (g.xy, ffp) + g.z * ffp.x * ffp.y,
     30. * fp * fp * (fp * fp - 2. * fp + 1.) * (g.xy + g.z * ffp.yx));
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

float Fbm2s (vec2 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int i = 0; i < 3; i ++) {
    f += a * Noisefv2 (p);
    a *= 0.5;
    p *= 2.;
  }
  return f * (1. / 1.75);
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
