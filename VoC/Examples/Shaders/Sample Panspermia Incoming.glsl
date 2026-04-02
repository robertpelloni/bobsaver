#version 420

// original https://www.shadertoy.com/view/tlcXD7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Panspermia Incoming" by dr2 - 2020
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  0  // optional antialising

float PrSphDf (vec3 p, float r);
float PrCylAnDf (vec3 p, float r, float w, float h);
float Minv3 (vec3 p);
float SmoothMin (float a, float b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);
float Hashfv2 (vec2 p);
vec3 Hashv3v3 (vec3 p);

vec4 qrHit;
vec3 ltDir, bGrid, cId, obRnd, obDisp;
vec2 obRotCs[2];
float tCur, dstFar;
bool cOcc;
const float pi = 3.14159;

#define CosSin(x) (sin ((x) + vec2 (0.5 * pi, 0.)))

vec3 SymCom (vec3 p, vec2 cs, vec2 w)
{
  vec2 f;
  float a;
  p.x = - abs (p.x);
  for (int j = 0; j < 4; j ++) {
    f.y = dot (p.yz, vec2 (cs.x, - cs.y));
    if (f.y > 0.) {
      f.x = dot (p.yz, cs.yx);
      p.yz = vec2 (dot (f, vec2 (cs.y, - cs.x)), dot (f, cs));
    }
    if (j < 3) p.xy = Rot2Cs (p.xy, w);
  }
  return vec3 (p.xy, - p.z);
}

vec3 IcosSym (vec3 p)
{
  vec2 cs;
  cs = CosSin (0.5 * acos (sqrt (5.) / 3.));
  p.yz = Rot2Cs (vec2 (p.y, abs (p.z)), vec2 (cs.x, - cs.y));
  return SymCom (p, cs, CosSin (-2. * pi / 3.));
}

vec3 DodecSym (vec3 p)
{
  vec2 cs;
  cs = CosSin (0.5 * atan (2.));
  p.xz = Rot2Cs (vec2 (p.x, abs (p.z)), cs);
  p.xy = Rot2Cs (p.xy, CosSin (- pi / 10.));
  return SymCom (p, cs, CosSin (-2. * pi / 5.));
}

void ObjState ()
{
  obRnd = Hashv3v3 (cId);
  obDisp = bGrid * (cId + 0.5) + (0.1 + 0.05 * bGrid.x * obRnd.x) *
     vec3 (CosSin (obRnd.z * tCur + obRnd.x), 0.).xzy;
  obRotCs[0] = CosSin ((obRnd.y - 0.5) * 0.7 * tCur );
  obRotCs[1] = CosSin ((obRnd.z - 0.5) * 0.7 * tCur);
  cOcc = (obRnd.x * step (2., length (cId.xz)) > 0.7);
}

float ObjDf (vec3 p)
{
  vec3 q, q1, q2;
  float d, d1, d2, ds, r1, r2, len, s;
  d = dstFar;
  if (cOcc) {
    p -= obDisp;
    p.xz = Rot2Cs (p.xz, obRotCs[0]);
    p.xy = Rot2Cs (p.xy, obRotCs[1]);
    len = 0.3;
    q1 = IcosSym (p);
    q1.z += 0.18 + len;
    s = 0.5 * (1. - q1.z / len);
    r1 = 0.03 * (1. + 5. * s * s);
    d1 = PrCylAnDf (q1, r1, 0.016 * (1. - 0.7 * s), len);
    q2 = DodecSym (p);
    q2.z += 0.18 + len;
    s = 0.5 * (1. - q2.z / len);
    r2 = 0.03 * (1. + 5. * s * s);
    d2 = PrCylAnDf (q2, r2, 0.016 * (1. - 0.7 * s), len);
    if (d1 < d2) {
      d = d1;
      qrHit = vec4 (q1, r1);
    } else {
      d = d2;
      qrHit = vec4 (q2, r2);
    }
    q = p;
    ds = PrSphDf (q, 0.2);
    if (ds < d) {
      d = SmoothMin (d, ds, 0.02);
      qrHit = vec4 (q, 0.);
    }
    d *= 0.8;
  }
  return d;
}

vec3 ObjCell (vec3 p)
{
  cId.xz = floor (p.xz / bGrid.xz);
  p.y += 0.2 * tCur * (1. + Hashfv2 (cId.xz));
  cId.y = floor (p.y / bGrid.y);
  return p;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p, cIdP, s, rdi;
  float dHit, d, eps;
  eps = 0.0005;
  if (rd.x == 0.) rd.x = 0.001;
  if (rd.y == 0.) rd.y = 0.001;
  if (rd.z == 0.) rd.z = 0.001;
  rdi = 1. / rd;
  cIdP = vec3 (-999.);
  dHit = eps;
  for (int j = 0; j < 220; j ++) {
    p = ObjCell (ro + dHit * rd);
    if (cId != cIdP) {
      ObjState ();
      cIdP = cId;
    }
    d = ObjDf (p);
    s = (bGrid * (cId + step (0., rd)) - p) * rdi;
    d = min (d, abs (Minv3 (s)) + eps);
    dHit += d;
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
  for (int j = 0; j < 4; j ++) {
    v[j] = ObjDf (p + ((j < 2) ? ((j == 0) ? e.xxx : e.xyy) : ((j == 2) ? e.yxy : e.yyx)));
  }
  v.x = - v.x;
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p, cIdP;
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  cIdP = vec3 (-999.);
  for (int j = 0; j < 20; j ++) {
    p = ObjCell (ro + d * rd);
    if (cId != cIdP) {
      ObjState ();
      cIdP = cId;
    }
    h = ObjDf (p);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.05 || d > 2.) break;
  }
  return 0.6 + 0.4 * sh;
}

vec3 BgCol (vec3 rd)
{
  float t, gd, b;
  t = tCur * 3.;
  b = dot (vec2 (atan (rd.x, rd.z), 0.5 * pi - acos (rd.y)), vec2 (2., sin (rd.x)));
  gd = clamp (sin (5. * b + t), 0., 1.) * clamp (sin (3.5 * b - t), 0., 1.) +
     clamp (sin (21. * b - t), 0., 1.) * clamp (sin (17. * b + t), 0., 1.);
  return 1.5 * mix (vec3 (0.25, 0.6, 1.), vec3 (0., 0.4, 0.3), 0.5 * (1. - rd.y)) *
     (0.8 + 0.2 * rd.y) * (1. + 0.25 * gd);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, bgCol, vn, p;
  float dstObj, sh;
  bGrid = vec3 (2.);
  bgCol = BgCol (rd);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    p = ObjCell (ro);
    ObjState ();
    vn = ObjNf (p);
    if (length (p - obDisp) > 0.21) col = (length (qrHit.xy) < qrHit.w) ?
       vec3 (1., 0.4, 0.4) * (0.6 + 0.4 * smoothstep (-0.1, 0.1, sin (15. * atan (qrHit.y, qrHit.x)))) :
       vec3 (0.4, 1., 0.4) * (0.6 + 0.4 * smoothstep (-0.1, 0.1, sin (15. * 2. * pi * qrHit.z)));
    else col = vec3 (1., 1., 0.4);
    sh = ObjSShadow (ro, ltDir);
    col = col * (0.2 + 0.1 * max (- dot (vn, ltDir), 0.) + 0.8 * sh * max (dot (vn, ltDir), 0.)) +
       0.1 * step (0.95, sh) * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    col = mix (col, bgCol, 0.3 + 0.7 * smoothstep (0.4, 1., dstObj / dstFar));
  } else col = bgCol;
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0); //mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  tCur += 10.;
  if (mPtr.z > 0.) {
    az = 2. * pi * mPtr.x;
    el = 0.6 * pi * mPtr.y;
  } else {
    az = 0.02 * pi * tCur;
    el = 0.1 * pi + 0.2 * pi * sin (0.01 * pi * tCur);
  }
  vuMat = StdVuMat (el, az);
  ro = vec3 (0.5);
  ltDir = vuMat * normalize (vec3 (1., 1., -2.));
  dstFar = 60.;
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), 4.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylAnDf (vec3 p, float r, float w, float h)
{
  return max (abs (length (p.xy) - r) - w, abs (p.z) - h);
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
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

float Hashfv2 (vec2 p)
{
  return fract (sin (dot (p, vec2 (37., 39.))) * cHashM);
}

vec3 Hashv3v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  return fract (sin (dot (p, cHashVA3) + vec3 (0., cHashVA3.xy)) * cHashM);
}
