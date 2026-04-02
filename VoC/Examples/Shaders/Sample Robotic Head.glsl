#version 420

// original https://www.shadertoy.com/view/NlK3WR

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Robotic Head" by dr2 - 2021
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Trigonometric experiment (mouseable)

/*
  No. 12 in "Flexible Tube" series
    "Flexibility"               (MtlyWl)
    "Planet Reboot"             (wldGD8)
    "Decalled Floppy Tube"      (3l3GD7)
    "Elevating Platter"         (Wl33RS)
    "Multisegment Floppy Tube"  (tlcGRB)
    "Planet Reboot 2"           (Wtc3Rf)
    "Snake Worship"             (wtyGRD)
    "Decalled Floppy Tube 2"    (WsGfWd)
    "Floppy Column"             (wtccR4)
    "Metallic Tubeworms"        (3ltfzM)
    "Trapped Light"             (flt3WB)
    
  But now a different (transcendental) problem must be solved: 
  compute arc angle from arc and chord lengths, rather than radius
  from arc length and angle.
*/

#define AA  0   // optional antialiasing

#if 0
#define VAR_ZERO min (frames, 0)
#else
#define VAR_ZERO 0
#endif

float PrRoundBoxDf (vec3 p, vec3 b, float r);
float PrRoundBox2Df (vec2 p, vec2 b, float r);
float PrTorusBxDf (vec3 p, vec3 b, float ri);
float PrSphDf (vec3 p, float r);
float PrCylDf (vec3 p, float r, float h);
float PrCapsDf (vec3 p, float r, float h);
float PrRoundCylDf (vec3 p, float r, float rt, float h);
float PrConCapsDf (vec3 p, vec2 cs, float r, float h);
float SmoothMax (float a, float b, float r);
mat3 StdVuMat (float el, float az);
vec2 Rot2D (vec2 q, float a);
float Fbm1 (float p);
float Fbm2 (vec2 p);

vec3 ltPos[4], ltCol[4], qHit;
float tCur, dstFar;
int idObj;
const int idTube = 1, idCon = 2, idBall = 3, idHead = 4, idEar = 5, idNos = 6, idCrwn = 7,
   idTooth = 8, idEye = 9, idBas = 10, idArm = 11; 
const float pi = 3.1415927;

struct Arc {
  vec2 cs;
  float chDist, chRot, ang, rad, shift;
};
Arc arc;

struct Arm {
  float len, sep, rot;
};
Arm arm;

#define DMINQ(id) if (d < dMin) { dMin = d;  idObj = id;  qHit = q; }

float ObjDf (vec3 p)
{
  vec3 pr, q;
  float dMin, d, sLen, sx, a;
  dMin = dstFar;
  sLen = 0.25;
  p.y -= arm.sep + 1.;
  q = p;
  pr = p;
  pr.xz = Rot2D (pr.xz, arm.rot);
  pr.y -= arm.sep;
  q = pr;
  q.z -= -0.5;
  d = PrRoundBoxDf (q, vec3 (0.8, 1.2, 1.), 0.2);
  d = SmoothMax (d, - min (PrSphDf (vec3 (abs (q.x) - 0.4, q.y - 0.4, q.z + 1.2), 0.25),
     PrCapsDf (vec3 (q.x, q.y + 0.7, q.z + 1.2).yzx, 0.15, 0.4)), 0.02);
  DMINQ (idHead);
  q = pr;
  q.z -= -0.2;
  d = PrRoundBoxDf (q, vec3 (0., 1.3, 0.9), 0.3);
  DMINQ (idCrwn);
  q = pr;
  d = PrTorusBxDf (q, vec3 (arm.len - 0.2, 0.1, 0.2), 0.1);
  DMINQ (idCon);
  q = pr;
  q.x = abs (q.x);
  q -= vec3 (0.4, 0.4, -1.65);
  d = PrSphDf (q, 0.22);
  DMINQ (idEye);
  q = pr;
  q -= vec3 (0., 0.2, -1.7);
  d = PrConCapsDf (q.xzy, sin (0.1 * pi + vec2 (0.5 * pi, 0.)), 0.13, 0.25);
  DMINQ (idNos);
  q = pr;
  q.x = abs (q.x);
  q -= vec3 (1.1, 0.5, -0.8);
  d = PrRoundCylDf (q.yzx, 0.3, 0.15, 0.);
  DMINQ (idEar);
  q = pr;
  d = max (PrRoundBoxDf (vec3 (mod (q.x + 0.05, 0.1) - 0.05, abs (q.y + 0.7) - 0.12,
     q.z + 1.65), vec3 (0.025, 0.04, 0.), 0.03), abs (q.x) - 0.45);
  DMINQ (idTooth);
  q = pr;
  sx = sign (q.x);
  q.x = abs (q.x) - arm.len;
  q.xz = Rot2D (q.xz, 0.5 * (pi - arm.rot) * sx);
  q.x += sLen * sx;
  d = PrCylDf (q.yzx, 0.1, sLen);
  DMINQ (idCon);
  sx *= sign (q.x);
  q.x = abs (q.x) - sLen;
  if (sx > 0.) q = q.xzy;
  d = PrSphDf (q, 0.17);
  DMINQ (idBall);
  q = p;
  d = PrCylDf (q.xzy, 0.4, 0.6);
  DMINQ (idBas);
  q = p;
  q.yz -= vec2 (- arm.sep - 0.2, -0.3);
  d = PrRoundCylDf (q.xzy, 1., 0.2, 0.7);
  DMINQ (idBas);
  q = p;
  q.yz -= vec2 (- arm.sep, - sLen);
  d = PrRoundBoxDf (q, vec3 (arm.len + 0.2, 0.2, 0.), 0.2);
  DMINQ (idArm);
  q = p;
  sx = sign (q.x);
  q.x = abs (q.x);
  q.xy -= vec2 (arm.len, - arm.sep);
  q.xz = Rot2D (q.xz, -0.5 * (pi - arm.rot) * sx);
  q.x -= sLen * sx;
  d = PrCylDf (q.yzx, 0.1, sLen);
  DMINQ (idCon);
  sx *= sign (q.x);
  q.x = abs (q.x) - sLen;
  if (sx < 0.) q = q.xzy;
  d = PrSphDf (q, 0.17);
  DMINQ (idBall);
  for (float k = 0.; k <= 1.; k ++) { // (constant-length flexible tubing)
    q = p;
    q.xz = Rot2D (q.xz, k * pi + 0.5 * arm.rot) - vec2 (arc.shift, 2. * sLen * sign (1. - 2. * k));
    q.yz = Rot2D (q.yz, arc.chRot - (k + 0.5) * pi) + vec2 (arc.chDist, 0.);
    a = mod ((128. / arc.ang) * atan (q.z, q.y) / (2. * pi), 1.);
    d = max (dot (vec2 (abs (q.z), q.y), arc.cs), length (vec2 (length (q.yz) - arc.rad, q.x)) -
       0.13 + 0.02 * smoothstep (0.15, 0.35, 0.5 - abs (0.5 - a)));
    DMINQ (idTube);
  }
  return dMin;
}

#define F(x) (sin (x) / x - b)

float SecSolve (float b)
{  // (solve for arc angle given length and chord, |err| < 1e-4 for b < 0.95) 
  vec3 t;
  vec2 f;
  t.yz = vec2 (0.7, 1.2);
  f = vec2 (F(t.y), F(t.z));
  for (int nIt = 0; nIt < 4; nIt ++) {
    t.x = (t.z * f.x - t.y * f.y) / (f.x - f.y);
    t.zy = t.yx;
    f = vec2 (F(t.x), f.x);
  }
  return t.x;
}

void ArcConf ()
{
  vec2 u;
  float arcLen, arcEx, chLen, aLim;
  aLim = 0.5 * pi;
  arm.len = 2.;
  arm.sep = 1.2;
  arcEx = 1.5;
  arcLen = arcEx * length (vec2 (arm.len * sin (0.5 * aLim), arm.sep));
  arm.rot = aLim * (0.3 + 0.7 * Fbm1 (0.7 * tCur)) * sin (0.2 * pi * tCur);
  u = vec2 (arm.len * sin (0.5 * arm.rot), arm.sep);
  chLen = length (u);
  arc.chRot = atan (u.x, u.y);
  arc.shift = sqrt (arm.len * arm.len - u.x * u.x);
  arc.ang = SecSolve (chLen / arcLen);
  arc.chDist = chLen / tan (arc.ang);
  arc.rad = sqrt (arc.chDist * arc.chDist + chLen * chLen);
  arc.cs = sin (- arc.ang + vec2 (0.5 * pi, 0.));
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p;
  float dHit, d;
  dHit = 0.;
  for (int j = VAR_ZERO; j < 120; j ++) {
    p = ro + dHit * rd;
    d = ObjDf (p);
    if (d < 0.0005 || dHit > dstFar || p.y < 0.) break;
    dHit += d;
  }
  if (p.y < 0.) dHit = dstFar;
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

float ObjSShadow (vec3 ro, vec3 rd, float dMax)
{
  float sh, d, h;
  sh = 1.;
  d = 0.01;
  for (int j = VAR_ZERO; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += h;
    if (sh < 0.001 || d > dMax) break;
  }
  return 0.3 + 0.7 * sh;
}

vec4 ObjCol ()
{
  vec4 col4;
  float s;
  if (idObj == idTube) {
    col4 = vec4 (0.9, 0.9, 1., 0.3);
  } else if (idObj == idCon) {
    col4 = vec4 (1., 0.7, 0.4, 0.3);
  } else if (idObj == idBall) {
    col4 = vec4 (1., 0.7, 0.4, 0.3) * (0.8 + 0.2 * smoothstep (0., 0.005,
       abs (abs (qHit.z) - 0.05) - 0.005));
  } else if (idObj == idHead) {
    s = min (abs (PrRoundBox2Df (qHit.yz - vec2 (-0.7, -0.4), vec2 (0.25, 0.3), 0.1)),
       abs (PrRoundBox2Df (qHit.yz - vec2 (0., 0.5), vec2 (0.4, 0.1), 0.07)));
    if (qHit.y > 0.) s = min (s, abs (PrRoundBox2Df (vec2 (abs (qHit.x) - 0.55, qHit.z),
       vec2 (0.1, 0.9), 0.07)));
    s = min (s, (qHit.z < 0.) ? abs (PrRoundBox2Df (qHit.xy - vec2 (0., 1.),
       vec2 (0.6, 0.1), 0.1)) : abs (PrRoundBox2Df (vec2 (abs (qHit.x), qHit.y) -
       vec2 (0.55, 0.), vec2 (0.1, 1.1), 0.07)));
    col4 = vec4 (0.8, 1., 0.9, 0.2) * (0.8 + 0.2 * smoothstep (0., 0.03, s));
    if (PrRoundBoxDf (qHit, vec3 (0.8, 1.2, 1.) - 0.01, 0.2) < 0.) col4 = vec4 (0.6, 0., 0., -1.);
  } else if (idObj == idEar) {
    col4 = vec4 (0.5, 1., 0.8, 0.2);
    if (qHit.x > 0.1) col4 *= 0.7 + 0.3 * smoothstep (0., 0.02, mod (16. *
       length (qHit.yz), 1.) - 0.1);
  } else if (idObj == idNos) {
    col4 = vec4 (0.9, 1., 0.6, 0.2);
    if (qHit.y < -0.3 && length (vec2 (abs (qHit.x) - 0.07, qHit.z + 0.1)) < 0.05) col4 *= 0.3;
  } else if (idObj == idCrwn) {
    s = 0.;
    if (abs (qHit.z) < 0.9) s = qHit.z;
    else if (abs (qHit.y) < 1.3) s = qHit.y;
    col4 = vec4 (0.6, 0.6, 0.2, 0.2);
    if (s != 0.) col4 *= 0.8 + 0.2 * smoothstep (0., 0.05, mod (8. * s, 1.) - 0.1);
  } else if (idObj == idTooth) {
    col4 = vec4 (1., 1., 1., 0.2);
  } else if (idObj == idEye) {
    col4 = vec4 (vec3 (0.3, 0.5, 1.) * (0.7 + 0.3 * Fbm1 (8. * tCur)), -1.);
  } else if (idObj == idBas) {
    col4 = vec4 (0.3, 0.7, 0.3, 0.2) * (0.8 + 0.2 * smoothstep (0., 0.05,
       mod (8. * qHit.y, 1.) - 0.1));
  } else if (idObj == idArm) {
    col4 = vec4 (0.5, 0.9, 0.3, 0.2) * (0.8 + 0.2 * smoothstep (0., 0.03,
       abs (PrRoundBox2Df (vec2 (abs (qHit.x), qHit.y) - vec2 (arm.len - 0.05, 0.),
       vec2 (0.2, 0.12), 0.07))));
  }
  return col4;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn, ltDir, ltAx, c;
  float dstObj, nDotL, sh, att, ltDst;
  ArcConf ();
  col = vec3 (0.);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col4 = ObjCol ();
  } else if (rd.y < 0.) {
    dstObj = - ro.y / rd.y;
    ro += dstObj * rd;
    vn = vec3 (0., 1., 0.);
    col4 = vec4 (0.6, 0.6, 0.6, 0.1) * (1. - 0.2 * Fbm2 (4. * ro.xz));
    col4.rgb *= 1. - 0.2 * smoothstep (0.05, 0.08,
       length (max (abs (mod (ro.xz + 0.7, 1.4) - 0.7) - 0.6, 0.)));
  }
  if (dstObj < dstFar) {
    if (col4.a >= 0.) {
      for (int k = VAR_ZERO; k < 4; k ++) { // (see "Controllable Hexapod 2")
        ltDir = ltPos[k] - ro;
        ltDst = length (ltDir);
        ltDir /= ltDst;
        ltAx = normalize (ltPos[k] - vec3 (0., arm.sep + 1., 0.));
        att = smoothstep (0., 0.02, dot (ltDir, ltAx) - 0.95);
        sh = (dstObj < dstFar) ? ObjSShadow (ro + 0.01 * vn, ltDir, ltDst) : 1.;
        nDotL = max (dot (vn, ltDir), 0.);
        if (col4.a > 0.) nDotL *= nDotL * nDotL;
        c = att * ltCol[k] * (col4.rgb * (0.15 + 0.85 * sh * nDotL) +
           col4.a * step (0.95, sh) * pow (max (dot (ltDir, reflect (rd, vn)), 0.), 32.));
        col += c * c;
      }
      col = sqrt (col);
    } else col = col4.rgb * (0.2 + 0.8 * max (0., - dot (vn, rd)));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv;
  float el, az, zmFac, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.13 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  } else {
    az -= 0.03 * pi * tCur;
    el += 0.1 * pi * cos (0.02 * pi * tCur);
  }
  el = clamp (el, -0.4 * pi, -0.01 * pi);
  vuMat = StdVuMat (el, az);
  ro = vuMat * vec3 (0., 2., -20.);
  ro.y = max (ro.y, 0.1);
  for (int k = VAR_ZERO; k < 4; k ++) {
    ltPos[k] = vec3 (0., 30., 0.);
    ltPos[k].xy = Rot2D (ltPos[k].xy, 0.25 * pi * (1. + 0.2 * sin (0.05 * pi * tCur -
       pi * float (k) / 4.)));
    ltPos[k].xz = Rot2D (ltPos[k].xz, 0.1 * pi * tCur + 2. * pi * float (k) / 4.);
  }
  ltCol[0] = vec3 (1., 0.5, 0.5);
  ltCol[1] = ltCol[0].gbr;
  ltCol[2] = ltCol[0].brg;
  ltCol[3] = 0.8 * ltCol[0].rrg;
  zmFac = 4.8;
  dstFar = 100.;
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
  glFragColor = vec4 (col, 1.);
}

float PrRoundBoxDf (vec3 p, vec3 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrRoundBox2Df (vec2 p, vec2 b, float r)
{
  return length (max (abs (p) - b, 0.)) - r;
}

float PrTorusBxDf (vec3 p, vec3 b, float ri)
{
  return length (vec2 (length (max (abs (p.xy) - b.xy, 0.)) - b.z, p.z)) - ri;
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

float PrCapsDf (vec3 p, float r, float h)
{
  return length (p - vec3 (0., 0., clamp (p.z, - h, h))) - r;
}

float PrRoundCylDf (vec3 p, float r, float rt, float h)
{
  return length (max (vec2 (length (p.xy) - r, abs (p.z) - h), 0.)) - rt;
}

float PrConCapsDf (vec3 p, vec2 cs, float r, float h)
{
  float d;
  d = max (dot (vec2 (length (p.xy) - r, p.z), cs), abs (p.z) - h);
  h /= cs.x * cs.x;
  r /= cs.x;
  p.z += r * cs.y;
  return min (d, min (length (p - vec3 (0., 0., h)) - (r - h * cs.y),
     length (p - vec3 (0., 0., - h)) - (r  + h * cs.y)));
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
