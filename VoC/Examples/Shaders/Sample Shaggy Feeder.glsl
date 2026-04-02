#version 420

// original https://www.shadertoy.com/view/tlXyWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Shaggy Feeder" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Hairy critter that eats grass, shoots, roots and leaves...

// Learned hairstyling from "furball" by simesgreen 

mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Noisefv2 (vec2 p);
vec2 Noisev2v2 (vec2 p);
float Fbm1 (float p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 sunDir;
float dstFar, tCur, tRot, rBall, furThk;
const float pi = 3.1415927;

float BallHit (vec3 ro, vec3 rd)
{
  float b, d;
  d = dstFar;
  b = dot (rd, ro);
  d = b * b + rBall * rBall - dot (ro, ro);
  return (d > 0.) ? - b - sqrt (d) : dstFar;
}

vec3 FurPos (vec3 p)
{
  float s, t;
  s = length (p);
  p /= s;
  t = 1. + (s - rBall) / furThk;
  p.xz = Rot2D (p.xz, 0.5 * t * sin (2. * pi * tRot));
  return vec3 (atan (p.z, p.x), acos (p.y) - 0.3 * t, s);
}

float FurDens (vec3 q)
{
  vec2 s;
  s = Noisev2v2 (96. * q.xy);
  return smoothstep (0.3, 1., s.x) * smoothstep (1., 1.2, s.y - (q.z - rBall) / furThk);
}

vec3 FurCol (vec3 ro, vec3 rd, vec3 col)
{
  vec4 col4, c4;
  vec3 p, q, vn;
  vec2 e;
  float d;
  const float nLay = 96.;
  furThk = 0.2;
  rBall = 1.;
  d = BallHit (ro, rd);
  col4 = vec4 (0.);
  if (d < dstFar) {
    p = ro + (d + 0.001) * rd;
    p.xz = Rot2D (p.xz, 0.5 * sin (2. * pi * tRot + 0.5 * pi));
    for (float j = 0.; j < nLay; j ++) {
      q = FurPos (p);
      c4.a = (j < nLay - 1. || q.z > rBall - furThk) ? FurDens (q) : 1.;
      if (c4.a > 0.) {
        e = vec2 (0.01, 0.);
        vn = normalize (c4.a - vec3 (FurDens (FurPos (p + e.xyy)),
           FurDens (FurPos (p + e.yxy)), FurDens (FurPos (p + e.xxy))));
        c4.rgb = mix (vec3 (0.7, 0.4, 0.2), vec3 (0.3, 0.3, 0.5),
           smoothstep (0.4, 0.6, Fbm2 (16. * q.xy)));
        c4.rgb = c4.rgb * (0.5 + 0.5 * max (0., dot (vn, sunDir)));
        c4.rgb *= c4.a * (0.6 + 0.4 * smoothstep (0.3, 0.7, (q.z - (rBall - furThk)) / furThk));
        col4 += c4 * (1. - col4.a);
      }
      p += (2. * furThk / nLay) * rd;
      if (p.y < 0.02 || col4.a > 0.95 || q.z > rBall) break;
    }
  }
  if (col4.a > 0.95) col = col4.rgb;
  return col;
}

vec3 SkyBgCol (vec3 ro, vec3 rd)
{
  vec3 col, clCol, skCol;
  vec2 q;
  float f, fd, ff, sd;
  if (rd.y > -0.02 && rd.y < 0.03 * Fbm1 (16. * atan (rd.z, - rd.x))) {
    col = vec3 (0.3, 0.41, 0.55);
  } else {
    q = 0.02 * (ro.xz + 0.5 * tCur + ((100. - ro.y) / rd.y) * rd.xz);
    ff = Fbm2 (q);
    f = smoothstep (0.2, 0.8, ff);
    fd = smoothstep (0.2, 0.8, Fbm2 (q + 0.01 * sunDir.xz)) - f;
    clCol = (0.7 + 0.5 * ff) * (vec3 (0.7) - 0.7 * vec3 (0.3, 0.3, 0.2) * sign (fd) *
       smoothstep (0., 0.05, abs (fd)));
    sd = max (dot (rd, sunDir), 0.);
    skCol = vec3 (0.4, 0.5, 0.8) + step (0.1, sd) * vec3 (1., 1., 0.9) *
       min (0.3 * pow (sd, 64.) + 0.5 * pow (sd, 2048.), 1.);
    col = mix (skCol, clCol, 0.1 + 0.9 * f * smoothstep (0.01, 0.1, rd.y));
  }
  return col;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, trCol, vn, gPos;
  vec2 vf;
  float dstGrnd, dMove, s, bRad, f, w;
  dMove = 0.1 * tCur;
  if (rd.y < 0.) {
    dstGrnd = - ro.y / rd.y;
    ro += dstGrnd * rd;
    vn = vec3 (0., 1., 0.);
    gPos = ro + vec3 (0., 0., dMove);
    vf = vec2 (8., 4. * (1. - smoothstep (0.5, 0.9, dstGrnd / dstFar)));
    col = mix (vec3 (0.4, 0.5, 0.3), vec3 (0., 0.5, 0.1),
       smoothstep (0.2, 0.8, Fbm2 (8. * gPos.xz)));
    w = 0.1 * (Noisefv2 (8. * gPos.xz) - 0.5);
    if (ro.z < 0. && abs (gPos.x) < 0.8 + w) {
      f = Fbm2 (32. * gPos.xz);
      trCol = vec3 (0.6, 0.7, 0.1) * (0.5 + 0.5 * f);
      bRad = 0.1 + 0.15 * Fbm1 (floor ((gPos.z + 1.) / 2.));
      s = length (vec2 (gPos.x, mod (gPos.z + 1., 2.) - 1.));
      if (s < bRad) {
        trCol = mix (vec3 (0.1 + 0.2 * f, 0., 0.), trCol, smoothstep (-0.04, 0., s - bRad));
        vf = vec2 (8., 8.);
      } else vf = vec2 (16., 1.);
      col = mix (trCol, col, smoothstep (0.75, 0.8, abs (gPos.x) - w));
    }
    col *= 0.9 + 0.1 * smoothstep (0.8, 0.9, length (ro.xz));
    col = mix (vec3 (0.2, 0.5, 0.2), col,  1. - smoothstep (0.5, 0.9, dstGrnd / dstFar));
    if (vf.x > 0.) vn = VaryNf (vf.x * gPos, vn, vf.y);
    col = col * (0.2 + 0.8 * max (dot (vn, sunDir), 0.));
    col = mix (0.8 * col, vec3 (0.3, 0.41, 0.55), pow (1. + rd.y, 16.));
  } else {
    col = SkyBgCol (ro, rd);
  }
  col = FurCol (ro, rd, col);
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.17 * pi;
  tRot = 0.4 * tCur;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az -= 0.03 * pi * tCur;
    el += 0.08 * pi * sin (0.05 * pi * tCur);
  }
  el = clamp (el, -0.4 * pi, -0.05 * pi);
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -10.);
  sunDir = vuMat * normalize (vec3 (1., 2., -1.));
  dstFar = 50.;
  rd = vuMat * normalize (vec3 (uv, 4.));
  col = ShowScene (ro, rd);
  glFragColor = vec4 (col, 1.);
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

vec2 Hashv2f (float p)
{
  return fract (sin (p + vec2 (0., 1.)) * cHashM);
}

vec2 Hashv2v2 (vec2 p)
{
  vec2 cHashVA2 = vec2 (37., 39.);
  return fract (sin (vec2 (dot (p, cHashVA2), dot (p + vec2 (1., 0.), cHashVA2))) * cHashM);
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

vec2 Noisev2v2 (vec2 p)
{
  return vec2 (Noisefv2 (p), Noisefv2 (p + vec2 (17., 23.)));
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
