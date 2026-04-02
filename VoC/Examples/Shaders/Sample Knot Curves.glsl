#version 420

// original https://www.shadertoy.com/view/4t3fWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Knot Curves 2" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec2 Rot2D (vec2 q, float a);
mat3 DirToRMatT (vec3 vd, vec3 vu);
vec3 HsvToRgb (vec3 c);
vec3 VaryNf (vec3 p, vec3 n, float f);

#define N_KNOT  11

vec3 qnHit, ltDir, knc[N_KNOT], kns[N_KNOT];
float dstFar, tCur, sclFac, qSeg;
int knType;
const float pi = 3.14159;

float CapsHit (vec3 ro, vec3 rd, float rad, float len)
{
  vec3 s, rs;
  float dMin, d, a, b, w;
  dMin = dstFar;
  a = dot (rd.xy, rd.xy);
  b = dot (rd.xy, ro.xy);
  w = b * b - a * (dot (ro.xy, ro.xy) - rad * rad);
  if (w > 0. && a > 0.) {
    d = - b - sqrt (w);
    if (d > 0.) {
      d /= a;
      s = ro + d * rd;
      if (abs (s.z) < len) {
        dMin = d;
        qnHit = vec3 (s.xy, 0.);
      }
    }
  }
  if (dMin == dstFar) {
    for (int k = 0; k <= 1; k ++) {
      rs = ro;
      rs.z += (k > 0) ? len : - len;
      b = dot (rd, rs);
      w = b * b - dot (rs, rs) + rad * rad;
      if (w > 0.) {
        d = - b - sqrt (w);
        if (d > 0. && d < dMin) {
          dMin = d;
          qnHit = rs + d * rd;
        }
      }
    }
  }
  return dMin;
}

// Knot parametrizations from A.K. Trautwein thesis (University of Iowa, 1995) (many more)

void KtSetup ()
{
  for (int k = 0; k < N_KNOT; k ++) {
    knc[k] = vec3 (0);  kns[k] = vec3 (0);
  }
  if (knType == 1) {  // 3.1 trefoil knot
     knc[0] = vec3 ( 41,   36,   0);   kns[0] = vec3 (-18,   27,   45);
     knc[1] = vec3 (-83, -113,  -30);  kns[1] = vec3 (-83,   30,  113);
     knc[2] = vec3 (-11,   11,  -11);  kns[2] = vec3 ( 27,  -27,   27);
     sclFac = 0.015;
  } else if (knType == 2) {  // 4.1 figure 8 knot
     knc[0] = vec3 (  32,   94,   16);  kns[0] = vec3 (-51,   41,   73);
     knc[1] = vec3 (-104,  113, -211);  kns[1] = vec3 (-34,    0,  -39);
     knc[2] = vec3 ( 104,  -68,  -99);  kns[2] = vec3 (-91, -124,  -21);
     sclFac = 0.008;
  } else if (knType == 3) {  // 5.1 knot
     knc[0] = vec3 (  88,   89,   44);  kns[0] = vec3 ( 115,  -32,  -69);
     knc[1] = vec3 (-475, -172,   34);  kns[1] = vec3 (-127,  294,  223);
     knc[2] = vec3 ( -87,   76,   16);  kns[2] = vec3 (  36,  102,  120);
     knc[3] = vec3 (  11,  -61,   42);  kns[3] = vec3 ( -19,  113, -125);
     sclFac = 0.0045;
  } else if (knType == 4) {  // 5.2 knot
     knc[0] = vec3 ( -33,  -57,   34);  kns[0] = vec3 ( 43,   99, -21);
     knc[1] = vec3 (   0,  -54, -100);  kns[1] = vec3 (214, -159, -93);
     knc[2] = vec3 (-101, -117,  -27);  kns[2] = vec3 (-47,   -5, -16);
     knc[3] = vec3 (   0,  -31,   52);  kns[3] = vec3 ( 11,  -45,  84);
     sclFac = 0.008;
  } else if (knType == 5) {  // granny knot
     knc[0] = vec3 (-22,   0,  0);  kns[0] = vec3 (-128,   0,   0);
     knc[1] = vec3 (  0, -10,  0);  kns[1] = vec3 (   0, -27,   0);
     knc[2] = vec3 (-44,   0, 70);  kns[2] = vec3 ( -78,   0, -40);
     knc[3] = vec3 (  0,  38,  0);  kns[3] = vec3 (   0,  38,   0);
     sclFac = 0.016;
  } else if (knType == 6) {  // square knot
     knc[0] = vec3 ( -22,  11,   0);  kns[0] = vec3 (-128,   0,   0);
     knc[2] = vec3 ( -44, -43,  70);  kns[2] = vec3 ( -78,   0, -40);
     knc[4] = vec3 (   0,  34,   8);  kns[4] = vec3 (   0, -39,  -9);
     sclFac = 0.016;
  } else if (knType == 7) {  // 6.1 knot
     knc[0] = vec3 (  12,   29,  -30);  kns[0] = vec3 ( 20,  78, -78);
     knc[1] = vec3 (-163, -180, -111);  kns[1] = vec3 ( 76,  58,  37);
     knc[2] = vec3 ( -87,   88,  -67);  kns[2] = vec3 (-15,  72, -51);
     knc[3] = vec3 ( -21,    0,   31);  kns[3] = vec3 ( 14, -14,   8);
     knc[4] = vec3 (  24,    0,  -11);  kns[4] = vec3 (-50,   0,  65);
     sclFac = 0.008;
  } else if (knType == 8) {  // 6.2 knot
     knc[0] = vec3 (  -6,  -21,  -18);  kns[0] = vec3 (-21,  -24,  -13);
     knc[1] = vec3 (-195, -207,  113);  kns[1] = vec3 ( 92,  -72, -107);
     knc[2] = vec3 ( -64,  112,   86);  kns[2] = vec3 (-23,   -7,   -9);
     knc[3] = vec3 (  -6,  -13,  -26);  kns[3] = vec3 ( 13,  -40,   -7);
     knc[4] = vec3 (  24,  -27,   24);  kns[4] = vec3 ( 15,   -3,   33);
     knc[5] = vec3 (   0,  -17,   21);  kns[5] = vec3 ( 41,    0,   31);
     sclFac = 0.008;
  } else if (knType == 9) {  // 6.3 knot
     knc[0] = vec3 (-40,   90,  52);  kns[0] = vec3 ( 32,  89,  64);
     knc[1] = vec3 ( 69, -142,  53);  kns[1] = vec3 (-12, 147,  35);
     knc[2] = vec3 (120,   74,  77);  kns[2] = vec3 (-52,  85, -87);
     knc[3] = vec3 (-56,    0, 101);  kns[3] = vec3 ( 46, -56, -19);
     knc[4] = vec3 (  0,   23,  -5);  kns[4] = vec3 (-17,   0,   2);
     knc[5] = vec3 ( 14,   16,   3);  kns[5] = vec3 ( 19,   7,   9);
     sclFac = 0.008;
  } else if (knType == 10) {  // 7.2 Knot
     knc[0] = vec3 (  10, 42, 0);  kns[0] = vec3 (115, -104, 30);
     knc[1] = vec3 (-184, -252,  20);  kns[1] = vec3 ( 10,  47,  19);
     knc[2] = vec3 (   0,  -21,   6);  kns[2] = vec3 (101, -65, -31);
     knc[3] = vec3 (  23,  -23,  -4);  kns[3] = vec3 ( 55, -23, -24);
     knc[4] = vec3 ( -38,   36, -44);  kns[4] = vec3 ( -6, -10, -50);
     knc[5] = vec3 ( -14,  -13,  31);  kns[5] = vec3 ( 8,    2,  39);
     knc[6] = vec3 (  16,  -18, -16);  kns[6] = vec3 ( 14,  -9,  23);
     sclFac = 0.007;
  } else if (knType == 11) {  // 7.7 Knot
     knc[0] = vec3 ( -5,   17, -28);  kns[0] = vec3 (  0,   21,   9);
     knc[1] = vec3 (  8, -174, 110);  kns[1] = vec3 ( 83,   13,   4);
     knc[2] = vec3 ( 87,  -15,  11);  kns[2] = vec3 (100,    3,  -6);
     knc[3] = vec3 ( -5,   -9, -46);  kns[3] = vec3 ( 22,   46, -17);
     knc[4] = vec3 (-10,   16,  32);  kns[4] = vec3 ( 10,  -25,  -9);
     knc[5] = vec3 ( -2,  -21, -12);  kns[5] = vec3 (-10,    7,  -9);
     knc[6] = vec3 (  5,   -9,  -9);  kns[6] = vec3 (  6,   -3,  18);
     sclFac = 0.01;
  }
}

vec3 KtPoint (float a)
{
  vec3 r;
  float f;
  r = vec3 (0.);
  for (int k = 0; k < N_KNOT; k ++) {
    f = float (k + 1) * a;
    r += knc[k] * cos (f) + kns[k] * sin (f);
  }
  return sclFac * r;
}

float ObjRay (vec3 ro, vec3 rd)
{
  mat3 rMat, rMatS;
  vec3 r, rp, qnHitS;
  float dAng, dMin, d;
  const float ndAng = 160.;
  dMin = dstFar;
  dAng = 2. * pi / ndAng;
  r = KtPoint (2. * pi - dAng);
  for (float j = 0.; j < ndAng; j ++) {
    rp = r;
    r = KtPoint (j * dAng);
    rMat = DirToRMatT (normalize (r - rp), vec3 (0., 0., 1.));
    d = CapsHit ((ro - 0.5 * (r + rp)) * rMat, rd * rMat, 0.1, 0.5 * length (r - rp));
    if (d < dMin) {
      dMin = d;
      rMatS = rMat;
      qnHitS = qnHit;
      qSeg = j;
    }
  }
  if (dMin < dstFar) {
    qnHit = rMatS * normalize (qnHitS);
    qSeg /= ndAng;
  }
  return dMin;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = VaryNf (32. * ro, qnHit, 1.);
    col = HsvToRgb (vec3 (qSeg, 1., 0.9));
    col = col * (0.2 + 0.8 * max (dot (vn, ltDir), 0.)) +
       0.2 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
  } else col = vec3 (0.2, 0.2, 0.22) * (0.5 + 0.3 * rd.y);
  return clamp (col, 0., 1.);
}

#define AA  0

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 rd, ro, col;
  vec2 canvas, uv, uvv, ca, sa, ori;
  float az, el, t;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  knType = 1 + int (mod (floor (0.2 * tCur + 3.), float (N_KNOT)));
  KtSetup ();
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    t = floor (0.6 * tCur) + smoothstep (0., 0.2, mod (0.6 * tCur, 1.));
    az = 0.2 * t;
    el = 0.23 * t;
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -20.);
  dstFar = 50.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    uvv = uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.), 0.5 * pi * (a + 0.5));
    rd = vuMat * normalize (vec3 (uvv, 6.));
    col += (1. / naa) * ((abs (uvv.x) < 1.) ? ShowScene (ro, rd) :
       vec3 (0.2, 0.2, 0.22) * (0.5 + 0.3 * rd.y));
  }
  glFragColor = vec4 (col, 1.);
}

mat3 DirToRMatT (vec3 vd, vec3 vu)
{
  vec3 vc;
  vc = normalize (cross (vu, vd));
  return mat3 (vc, cross (vd, vc), vd);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec3 HsvToRgb (vec3 c)
{
  return c.z * mix (vec3 (1.), clamp (abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. -
     3.) - 1., 0., 1.), c.y);
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
