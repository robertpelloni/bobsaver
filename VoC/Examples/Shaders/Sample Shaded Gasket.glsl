#version 420

// original https://www.shadertoy.com/view/DltGW2

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Shaded Gasket" by dr2 - 2023
// License: Creative Commons Attribution-NonCommercial-ShareAlike 4.0

/*
  Based on fizzer's "Apollonian Gasket Möbius" (WtdSDf); this method
  provides disk coordinates and radii, but not iteration counts for the
  disks shown.
  
  A simpler version is mla's (e.g.) "Colourful Apollonian III" (wdsfWX);
  this uses colors based on iteration counts, but not proper coordinates
  for the disks shown (note how the shading can vary inside each disk).
  
  Since both quantities are used here - for combining normal-based bump
  mapping with different disk colors, disk radius (log) is used as a
  proxy for the iteration count.
 
  See "Indra's Pearls" for lots of info, but only the simplest color
  renderings appear in the book.
  
  The Möbius code has been reformulated.
*/

#define AA  1 // (= 0/1)

#if 0
#define VAR_ZERO min (frames, 0)
#else
#define VAR_ZERO 0
#endif

float Minv2 (vec2 p);
float Maxv2 (vec2 p);
vec2 Rot2D (vec2 q, float a);
vec3 HsvToRgb (vec3 c);

#define N_CIRC  3  // odd value (>= 3)

vec3 limCirc[N_CIRC + 1], invCirc[N_CIRC + 1], ltDir;
vec2 sAzEl;
const int maxIt = 64;
const float pi = 3.1415927;

struct Mob {
  vec2 a, b, c, d;
};

vec2 CMul (vec2 a1, vec2 a2)
{
  return vec2 (a1.x * a2.x - a1.y * a2.y, a1.x * a2.y + a1.y * a2.x);
}

vec2 CConj (vec2 a)
{
  return vec2 (a.x, - a.y);
}

float CModSq (vec2 a)
{
  return a.x * a.x + a.y * a.y;
}

vec2 CDiv (vec2 a1, vec2 a2)
{
  return CMul (a1, CConj (a2)) / CModSq (a2);
}

vec2 MobOp (Mob m, vec2 z)
{
  return CDiv (CMul (z, m.a) + m.b, CMul (z, m.c) + m.d);
}

Mob MobInv (Mob m)
{
  return Mob (m.d, - m.b, - m.c, m.a);
}

Mob MobProd (Mob m1, Mob m2)
{
  return Mob (CMul (m1.a, m2.a) + CMul (m1.b, m2.c), CMul (m1.a, m2.b) + CMul (m1.b, m2.d),
     CMul (m1.c, m2.a) + CMul (m1.d, m2.c), CMul (m1.c, m2.b) + CMul (m1.d, m2.d));
}

vec3 MobToCirc (Mob m, vec3 c)
{
  vec2 z;
  z = MobOp (m, c.xy - CDiv (vec2 (c.z * c.z, 0.), CConj (c.xy + CDiv (m.d, m.c))));
  return vec3 (z, length (z - MobOp (m, c.xy + vec2 (c.z, 0.))));
}

Mob CircToMob (vec3 c)
{
  Mob m;
  m = Mob (vec2 (c.z, 0.), c.xy, vec2 (0.), vec2 (1., 0.));
  return MobProd (MobProd (m, Mob (vec2 (0.), vec2 (1., 0.), vec2 (1., 0.), vec2 (0.))),
     Mob (m.d, m.b * vec2 (-1., 1.), m.c, m.a));
}

void CircInit ()
{
  float a, r, rs;
  a = pi / float (N_CIRC);
  r = 1. / cos (a);
  rs = sqrt (r * r - 1.);
  for (int j = 0; j < N_CIRC; j ++) {
    limCirc[j] = vec3 (sin (2. * a * float (j) - vec2 (0.5 * pi, 0.)) * r, rs) * (r - rs);
    invCirc[j] = vec3 (sin (2. * a * float (j) + vec2 (0.5 * pi, 0.)) * r, rs);
  }
  limCirc[N_CIRC] = vec3 (0., 0., 1.);
  invCirc[N_CIRC] = vec3 (0., 0., r - rs);
}

#define DDOT(x) dot ((x), (x))

vec4 PCirc (vec2 p, vec2 pm)
{
  Mob mm, m;
  vec3 g, gi, w;
  vec2 z, cm;
  float eps;
  bool done;
  eps = 1e-9;
  CircInit ();
  z = p;
  mm = Mob (vec2 (1., 0.), vec2 (0.), vec2 (0.), vec2 (1., 0.));
  if (DDOT (pm) > 0.0005 && DDOT (pm) < 1.) {
    cm = pm * vec2 (-1., 1.) / DDOT (pm);
    m = CircToMob (vec3 (cm, sqrt (DDOT (cm) - 1.)));
    z = MobOp (m, z);
    mm = MobProd (m, mm);
  }
  for (int it = VAR_ZERO; it < maxIt; it ++) {
    done = true;
    for (int j = 0; j <= N_CIRC; j ++) {
      gi = invCirc[j];
      if (DDOT (z - gi.xy * vec2 (1., -1.)) < gi.z * gi.z) {
        g = gi;
        done = false;
        break;
      }
    }
    if (! done) {
      if (g.x == 0.) g.x = eps;
      m = CircToMob (g);
      z = MobOp (m, z);
      mm = MobProd (m, mm);
    } else break;
  }
  mm = MobInv (mm);
  if (CModSq (mm.c) == 0.) mm.c = vec2 (eps, 0.);
  w.z = 1.;
  for (int j = 0; j <= N_CIRC; j ++) {
    g = MobToCirc (mm, limCirc[j]);
    if (g.z > 0. && g.z < 1.) {
      w.xy = (p - g.xy) / g.z;
      w.z = DDOT (w.xy);
      if (w.z < 1.) break;
    }
  }
  return vec4 (w, g.z);
}

vec3 BgCol (vec3 v)
{
  vec4 col4;
  vec3 u, c;
  vec2 f;
  v.xz = Rot2D (v.xz, sAzEl.x);
  v.xy = Rot2D (v.xy, sAzEl.y);
  col4 = vec4 (0.);
  for (int ky = -1; ky <= 1; ky ++) {
    for (int kx = -1; kx <= 1; kx ++) {
      u = v;
      f = 0.0025 * vec2 (kx, ky);
      u.yz = Rot2D (u.yz, f.y);
      u.xz = Rot2D (u.xz, f.x);
      c = vec3 (1. - Minv2 (smoothstep (0.03, 0.05, abs (fract (16. *  vec2 (atan (u.z, - u.x),
         asin (u.y)) / pi) - 0.5)))) * (0.6 + 0.4 * u.y);
      col4 += vec4 (min (c, 1.), 1.) * (1. - 0.15 * dot (f, f));
    }
  }
  return col4.rgb / col4.a;
}

vec3 Color (vec2 p, vec2 pm)
{
  vec4 p4;
  vec3 col, vn;
  float nDotL;
  p4 = PCirc (p.yx, pm.yx);
  col = vec3 (0.);
  if (p4.z < 1.) {
    vn = vec3 (p4.xy, sqrt (1. - p4.z)).xzy;
    nDotL = max (dot (vn, ltDir), 0.);
    col = HsvToRgb (vec3 (fract (0.75 - 0.9 * log2 (p4.w) / log2 (float (maxIt))), 1., 1.));
    col = col * (0.2 +  0.8 * nDotL * nDotL) + vec3 (0.2) * pow (max (dot (ltDir,
       reflect (vec3 (0., -1., 0.), vn)), 0.), 64.);
    col = mix (col, BgCol (vn), 0.3);
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  vec4 mPtr;
  vec3 col;
  vec2 canvas, uv, uvv, pm;
  float tCur, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  if (abs (uv.x) < 1.) {
    sAzEl = vec2 (0.2 * pi * tCur, 0.1 * pi);
    ltDir = vec3 (0., 1., 0.);
    ltDir.xy = Rot2D (ltDir.xy, 0.2 * pi);
    ltDir.xz = Rot2D (ltDir.xz, -0.7 * pi);
    pm = (mPtr.z > 0. && Maxv2 (abs (mPtr.xy * canvas)) < 0.5 * canvas.y) ? mPtr.xy : vec2 (0.);
#if ! AA
    const float naa = 1.;
#else
    const float naa = 3.;
#endif  
    col = vec3 (0.);
    sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
    for (float a = float (VAR_ZERO); a < naa; a ++) {
      uvv = uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.), sr * (0.667 * a + 0.5) * pi);
      if (length (uvv) < 1.) col += (1. / naa) * Color (1.05 * uvv, pm);
    }
  } else col = vec3 (0.82);
  glFragColor = vec4 (col, 1.);
}

float Minv2 (vec2 p)
{
  return min (p.x, p.y);
}

float Maxv2 (vec2 p)
{
  return max (p.x, p.y);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.) - 1.,
     0., 1.), c.y);
}