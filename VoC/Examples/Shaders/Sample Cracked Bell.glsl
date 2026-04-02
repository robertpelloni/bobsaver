#version 420

// original https://www.shadertoy.com/view/WsjBR3

uniform int frames;
uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Cracked Bell" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrBoxDf (vec3 p, vec3 b);
float PrCapsDf (vec3 p, float r, float h);
float PrTorusDf (vec3 p, float ri, float rc);
float SmoothBump (float lo, float hi, float w, float x);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Fbm1 (float p);
float Fbm3 (vec3 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

vec3 ltPos;
float tCur, dstFar, bHt, bRd, crkOff;
int idObj;
const float pi = 3.14159;

#define VAR_ZERO min (frames, 0)

#define DMIN(id) if (d < dMin) { dMin = d;  idObj = id; }

float CrkFun (vec3 p)
{
  vec3 e;
  vec2 cs, w;
  float s;
  s = 1.;
  e = normalize (p);
  if (e.y > -0.21 * pi && e.y < 0.2 * pi) {
    s = 1. - smoothstep (0., 0.22 * pi, e.y);
    cs = sin (0.07 * pi * e.y + 0.2 * s * (Fbm1 (4. * pi * e.y + crkOff) - 0.5) + vec2 (0.5 * pi, 0.));
    w = vec2 (abs (dot (p.xz, vec2 (cs.x, - cs.y))), p.z);
    s = length (max (w, 0.)) - 0.02 * s;
  }
  return s;
}

float ObjDf (vec3 p)
{
  vec3 q;
  float dMin, d, r, c;
  dMin = dstFar;
  q = p;
  r = bRd;
  r *= (1. - 0.7 * smoothstep (-0.6 * bHt, bHt + r, q.y) - 0.3 * smoothstep (- bHt, -0.4 * bHt, q.y));
  c = 0.1 * (0.1 + 0.9 * smoothstep (- bHt, -0.8 * bHt, q.y));
  r -= c - 0.1;
  d = max (abs (PrCapsDf (q.xzy, r, bHt)) - c, - bHt - q.y);
  d = max (d, - CrkFun (q));
  DMIN (1);
  q = p;
  q.y -= bHt + 0.7;
  d = PrTorusDf (q, 0.1, 0.3);
  DMIN (2);
  q = p;
  q.y -= - bHt - 0.2;
  q.xz = abs (q.xz) - 0.7 * bRd;
  q.xz = Rot2D (q.xz, 0.25 * pi);
  d = PrBoxDf (q, vec3 (0.3, 0.2, 0.4));
  DMIN (3);
  d = p.y + bHt + 0.4;
  DMIN (4);
  return 0.7 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
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
  e = vec2 (0.001, -0.001);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

vec2 BallHit2 (vec3 ro, vec3 rd, float rad)
{
  vec3 u;
  vec2 d2;
  float b, d;
  u = ro;
  b = dot (rd, u);
  d = b * b + rad * rad - dot (u, u);
  d2 = vec2 (dstFar, dstFar);
  if (d > 0.) {
    d = sqrt (d);
    d2 = vec2 (- b - d, - b + d);
  }
  return d2;
}

float ObjSShadow (vec3 ro, vec3 rd, float dMax)
{
  float sh, d, h;
  sh = 1.;
  d = 0.02;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.02 * d, h));
    d += clamp (2. * h, 0.02, 0.3);
    if (sh < 0.05 || d > dMax) break;
  }
  return 0.6 + 0.4 * sh;
}

float CrkGlo (vec3 u)
{
  float t;
  t = asin (u.y / length (u));
  return clamp (2. * Fbm1 (128. * t - 5. * tCur + 2. * sin (t * pi * tCur)) - 0.5, 0., 1.);
}

float LabSym (vec2 p)
{
  vec2 q;
  float d, r;
  r = length (p);
  d = max (min (0.06 - abs (0.1 - abs (r - 0.8)), p.y), min (0.06 - abs (p.y), 1.1 - abs (p.x)));
  q = Rot2D (p, 2. * pi * floor (16. * ((r > 0.) ? atan (p.y, - p.x) / (2. * pi) : 0.) + 0.5) / 16.);
  d = max (d, min (min (0.06 - abs (q.y), 0.2 - abs (q.x + 1.1)), p.y + 0.1));
  q.x += 1.5;
  d = max (d, min (0.1 - length (q), p.y + 0.1));
  return d;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 roo, col, vn, u, ltDir;
  vec2 db2;
  float dstObj, pDotR, r, rLo, rHi, sh, att, locLit, tLit;
  bHt = 2.;
  bRd = 2.4;
  tLit = SmoothBump (0.25, 0.75, 0.15, mod (0.1 * tCur, 1.)) * (0.9 + 0.3 * Fbm1 (16. * tCur));
  roo = ro;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    locLit = 0.;
    if (idObj == 1) {
      col4 = 1.3 * mix (vec4 (0.4, 0.2, 0.1, 0.2), vec4 (0.37, 0.27, 0.1, 0.3),
         smoothstep (0.45, 0.55, Fbm3 (4. * ro)));
      if (dot (vn.xz, ro.xz) > 0.) col4.rgb *= (1. - 0.2 * SmoothBump (-0.3, 0.3, 0.02, ro.y + 0.28)) *
         (1. + 0.5 * smoothstep (-0.05, 0., LabSym (4. *
         vec2 (mod (8. * atan (ro.z, - ro.x) / (2. * pi) + 0.5, 1.) - 0.5, 0.8 * (ro.y + 0.5)))));
    } else if (idObj == 2) {
      col4 = vec4 (0.5, 0.2, 0., 0.2);
    } else if (idObj == 3) {
      col4 = vec4 (0.4, 0.3, 0.2, 0.1);
    } else if (idObj == 4) {
      r = length (ro.xz);
      col4 = vec4 (0.2, 0.2, 0.25, 0.) * (0.95 + 0.05 * sin (2. * pi * r)) *
         (0.8 + 0.2 * smoothstep (-0.2, 0., r - bRd));
      locLit = 1. - smoothstep (-0.1, 0.5, r - bRd);
      if (smoothstep (0., 0.1, CrkFun (ro)) < 1.) 
         locLit = max (2. * CrkGlo (ro) / (1. + dot (ro, ro)), locLit);
    }
    vn = VaryNf (32. * ro, vn, 0.5);
    ltDir = normalize (ltPos);
    att = 0.1 + 0.9 * smoothstep (0.97, 0.995, dot (normalize (ltPos - ro), ltDir));
    sh = min (att, ObjSShadow (ro + 0.01 * vn, ltDir, length (ltPos - ro)));
    col = col4.rgb * (0.2 + 0.2 * max (- dot (vn, ltDir), 0.) + 0.8 * sh * max (dot (vn, ltDir), 0.)) +
       col4.a * step (0.95, sh) * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    col += 0.6 * vec3 (1., 1., 0.5) * locLit * tLit;
  } else {
    col = vec3 (0.02);
  }
  pDotR = - dot (roo, rd);
  rLo = 1.5;
  rHi = 5.;
  locLit = 0.;
  for (float sd = float (VAR_ZERO); sd < 1.6; sd += 1. / 120.) {
    att = 2. * min (1., 10. / (1. + 200. * sd * sd));
    db2 = BallHit2 (roo, rd, rLo + (rHi - rLo) * sd);
    if (db2.x < min (dstObj, dstFar) && db2.x < pDotR) {
      u = roo + db2.x * rd;
      if (smoothstep (0., 0.0012 * (db2.x - rLo), CrkFun (u)) < 1.) locLit = max (locLit, CrkGlo (u) * att);
    }
    if (db2.y < min (dstObj, dstFar) && db2.y > pDotR) {
      u = roo + db2.y * rd;
      if (smoothstep (0., 0.002 * (db2.x - rLo), CrkFun (u)) < 1.) locLit = max (locLit, CrkGlo (u) * att);
    }
  }
  col = mix (col, vec3 (1., 1., 0.5), locLit * tLit);
  return clamp (col, 0., 1.);
}

#define AA  0   // optional antialiasing

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr, ltEl, ltAz, todCur;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  todCur = date.w;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.05 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az += 0.3 * pi * sin (0.03 * pi * tCur);
    el -= 0.05 * pi * sin (0.02 * pi * tCur);
  }
  el = clamp (el, -0.4 * pi, -0.01 * pi);
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 0., -20.);
  zmFac = 5.;
  dstFar = 100.;
  ltEl = -0.3 * pi * (1. + 0.15 * sin (0.1 * 2. * pi * tCur));
  ltAz = pi + 0.2 * pi * cos (0.125 * 2. * pi * tCur);
  ltPos = vec3 (0., 0., 50.);
  ltPos.yz = Rot2D (ltPos.yz, ltEl);
  ltPos.xz = Rot2D (ltPos.xz, ltAz);
  crkOff = mod (floor (0.01 * todCur), 10.);
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (pow (col, vec3 (1.)), 1.);
}

float PrBoxDf (vec3 p, vec3 b)
{
  vec3 d;
  d = abs (p) - b;
  return min (max (d.x, max (d.y, d.z)), 0.) + length (max (d, 0.));
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
}

float PrTorusDf (vec3 p, float ri, float rc)
{
  return length (vec2 (length (p.xy) - rc, p.z)) - ri;
}

float SmoothBump (float lo, float hi, float w, float x)
{
  return (1. - smoothstep (hi - w, hi + w, x)) * smoothstep (lo - w, lo + w, x);
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
  return fract (sin (dot (p, cHashVA2) + vec2 (0., cHashVA2.x)) * cHashM);
}

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  return fract (sin (dot (p, cHashVA3) + vec4 (0., cHashVA3.xyz)) * cHashM);
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

float Fbm3 (vec3 p)
{
  float f, a;
  f = 0.;
  a = 1.;
  for (int j = 0; j < 5; j ++) {
    f += a * Noisefv3 (p);
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
