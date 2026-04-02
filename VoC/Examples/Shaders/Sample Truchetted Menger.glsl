#version 420

// original https://www.shadertoy.com/view/3lcBDl

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Truchetted Menger" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  0   // (= 0/1) optional antialiasing

#define VAR_ZERO min (frames, 0)

float PrRoundBoxDf (vec3 p, vec3 b, float r);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
float Minv3 (vec3 p);
float SmoothMax (float a, float b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Hashfv2 (vec2 p);

vec3 ltDir;
vec2 gId, cMid;
float tCur, dstFar, hgSize, cDir;
const float pi = 3.1415927, sqrt3 = 1.7320508;

// Blended from "Menger Helix" and "Truchet Passages"

float MengDf (vec3 p)
{
  vec3 b;
  float sclFac, r, r0, a, s;
  const float nIt = 3.;
  sclFac = 2.4;
  r0 = 0.6 * 18. / pi;
  p /= (0.5 / r0);
  b = (sclFac - 1.) * vec3 (1., 1.125, 0.625);
  r = length (p.xz);
  a = (r > 0.) ? atan (p.z, - p.x) / (2. * pi) : 0.;
  p.x = mod (18. * a + 1., 2.) - 1.;
  p.z = r - r0;
  s = 1.;
  for (float n = 0.; n < nIt; n ++) {
    p = abs (p);
    p.xy = (p.x > p.y) ? p.xy : p.yx;
    p.xz = (p.x > p.z) ? p.xz : p.zx;
    p.yz = (p.y > p.z) ? p.yz : p.zy;
    p = sclFac * p - b;
    p.z += b.z * step (p.z + 0.5 * b.z, 0.);
    s *= sclFac;
  }
  return (0.5 / r0) * PrRoundBoxDf (p, vec3 (1.) - 0.1, 0.1) / s;
}

float ObjDf (vec3 p)
{
  p.xz -= cMid;
  p /= hgSize;
  p.xz = Rot2D (p.xz, cDir * pi / 6.);
  p.xz = Rot2D (p.xz, 2. * pi * floor (3. * atan (p.z, - p.x) / (2. * pi) + 0.5) / 3.);
  p.x += 1.;
  p.xz = Rot2D (p.xz, mod (0.2 * cDir * tCur + pi / 3., 2. * pi / 3.) - pi / 3.);
  return MengDf (p);
}

void SetTrConf ()
{
  cMid = HexToPix (gId * hgSize);
  cDir = 2. * step (Hashfv2 (gId), 0.5) - 1.;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM, gIdP;
  float dHit, d, s, eps;
  if (rd.x == 0.) rd.x = 0.0001;
  if (rd.z == 0.) rd.z = 0.0001;
  eps = 0.0005;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSize / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]),
     dot (ro.xz, edN[2])) / hgSize;
  pM = HexToPix (PixToHex (ro.xz / hgSize));
  hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
  s = Minv3 (hv);
  gIdP = vec2 (-999.);
  dHit = 0.;
  for (int j = VAR_ZERO; j < 160; j ++) {
    p = ro + dHit * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId != gIdP) {
      gIdP = gId;
      SetTrConf ();
    }
    d = ObjDf (p);
    if (dHit + d < s) {
      dHit += d;
    } else {
      dHit = s + eps;
      pM += sqrt3 * ((s == hv.x) ? edN[0] : ((s == hv.y) ? edN[1] : edN[2]));
      hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
      s = Minv3 (hv);
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
  e = vec2 (0.002, -0.002);
  for (int j = VAR_ZERO; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 gIdP;
  float sh, d, h;
  sh = 1.;
  d = 0.01;
  gIdP = vec2 (-999.);
  for (int j = VAR_ZERO; j < 30; j ++) {
    p = ro + d * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId != gIdP) {
      gIdP = gId;
      SetTrConf ();
    }
    h = ObjDf (p);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += clamp (h, 0.02, 0.5);
    if (sh < 0.05 ) break;
  }
  return 0.6 + 0.4 * sh;
}

vec3 BgCol (vec3 rd)
{
  float t, gd, b;
  t = 2. * tCur;
  b = dot (vec2 (atan (rd.x, rd.z), 0.5 * pi - acos (rd.y)), vec2 (2., sin (rd.x)));
  gd = clamp (sin (5. * b + t), 0., 1.) * clamp (sin (3.5 * b - t), 0., 1.) +
     clamp (sin (21. * b - t), 0., 1.) * clamp (sin (17. * b + t), 0., 1.);
  return mix (vec3 (0.25, 0.5, 1.), vec3 (0., 0.3, 0.4), 0.5 * (1. - rd.y)) *
     (0.65 + 0.35 * rd.y) * (1. + 0.2 * gd);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj, sh;
  dstObj = ObjRay (ro, rd);
  col = BgCol (rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    sh = ObjSShadow (ro + 0.01 * vn, ltDir);
    col = mix (col, vec3 (0.3, 0.9, 0.5) * (0.3 + 0.7 * sh * max (dot (vn, ltDir), 0.)),
       exp (min (0., 1. - 8. * dstObj / dstFar)));
  }
  return clamp (col, 0., 1.);
}

vec2 TrkPath (float t)
{
  vec2 r;
  float tt;
  tt = mod (t, 4.);
  if (tt < 1.) r = mix (vec2 (sqrt3/2., -0.5), vec2 (sqrt3/2., 0.5), tt);
  else if (tt < 2.) r = mix (vec2 (sqrt3/2., 0.5), vec2 (0., 1.), tt - 1.);
  else if (tt < 3.) r = mix (vec2 (0., 1.), vec2 (0., 2.), tt - 2.);
  else r = mix (vec2 (0., 2.), vec2 (sqrt3/2., 2.5), tt - 3.);
  r += vec2 (0.001, 3. * floor (t / 4.));
  return r * hgSize;
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, uvv, p1, p2, vd;
  float el, az, zmFac, asp, sr, vel;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  asp = canvas.x / canvas.y;
  hgSize = 2.;
  vel = 0.1;
  p1 = TrkPath (vel * tCur + 0.3);
  p2 = TrkPath (vel * tCur - 0.3);
  ro.xz = 0.5 * (p1 + p2);
  ro.x += 0.2;
  ro.y = 4.;
  vd = p1 - p2;
  az = atan (vd.x, vd.y);
  el = -0.2 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  }
  el = clamp (el, -0.3 * pi, 0.3 * pi);
  vuMat = StdVuMat (el, az);
  zmFac = 4.;
  dstFar = 40.;
  ltDir = normalize (vec3 (1., 1., -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = float (VAR_ZERO); a < naa; a ++) {
    uvv = (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.), sr * (0.667 * a + 0.5) * pi)) / zmFac;
    rd = vuMat * normalize (vec3 ((2. * tan (0.5 * atan (uvv.x / asp))) * asp, uvv.y, 1.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
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
  return vec2 (sqrt3 * (h.x + 0.5 * h.y), (3./2.) * h.y);
}

float Minv3 (vec3 p)
{
  return min (p.x, min (p.y, p.z));
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

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
}
