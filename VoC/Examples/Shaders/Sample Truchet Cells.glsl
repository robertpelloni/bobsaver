#version 420

// original https://www.shadertoy.com/view/lslfDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Colored Truchet Cells" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec3 HsvToRgb (vec3 c);
float Hashfv3 (vec3 p);

vec3 ltPos, qHit;
float dstFar, tCur;
const float pi = 3.14159;

vec3 TrackPath (float t)
{
//  return vec3 (0., 0., t);
  return vec3 (2. * sin (0.2 * t) + 0.9 * sin (0.23 * t),
     1.3 * sin (0.17 * t) + 0.66 * sin (0.24 * t), t);
}

float TubeDf (vec3 p)
{
  return length (vec2 (length (p.xy), p.z) - 0.5) - 0.06;
}

float ObjDf (vec3 p)
{
  vec3 q, qq;
  float dMin, d, r;
  q = p;
  q.xy -= TrackPath (q.z).xy;
  r = floor (8. * Hashfv3 (floor (q)));
  q = fract (q);
  if (r >= 4.) q = q.yxz;
  r = mod (r, 4.);
  if (r == 0.) q.x = 1. - q.x;
  else if (r == 1.) q.y = 1. - q.y;
  else if (r == 2.) q.xy = 1. - q.xy;
  dMin = dstFar;
  qq = q;
  d = TubeDf (qq);
  if (d < dMin) { dMin = d;  qHit = qq; }
  qq = vec3 (q.z, 1. - q.x, q.y);
  d = TubeDf (qq);
  if (d < dMin) { dMin = d;  qHit = qq; }
  qq = vec3 (1. - q.yz, q.x);
  d = TubeDf (qq);
  if (d < dMin) { dMin = d;  qHit = qq; }
  return 0.8 * dMin;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 100; j ++) {
    d = ObjDf (ro + rd * dHit);
    if (d < 0.001 || dHit > dstFar) break;
    dHit += d;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec3 e = vec3 (0.001, -0.001, 0.);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy),
     ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 16; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += 0.07;
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn, ltVec, q;
  float dHit, ltDist, sh, a;
  dHit = ObjRay (ro, rd);
  if (dHit < dstFar) {
    ro += dHit * rd;
    a = atan (- qHit.y, qHit.x) / pi;
    col = HsvToRgb (vec3 (mod (2. * a + 0.3 * tCur, 1.), 1., 1.));
    vn = ObjNf (ro);
    ltVec = ltPos - ro;
    ltDist = length (ltVec);
    ltVec /= ltDist;
    sh = ObjSShadow (ro, ltVec);
    col = col * (0.1 + 0.9 * sh * max (dot (vn, ltVec), 0.)) +
       0.1 * sh * pow (max (dot (normalize (vn - rd), vn), 0.), 64.);
    col *= 1. / (1. + 0.1 * ltDist * ltDist);
  } else col = vec3 (0.);
  return col;
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, pF, pB, u, vd;
  vec2 canvas, uv, ori, ca, sa;
  float az, el, asp, zmFac, vFly, f;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  asp = canvas.x / canvas.y;
  vFly = 0.5;
  az = 0.;
  el = 0.;
  //if (mPtr.z > 0.) {
  //  az = 2. * pi * mPtr.x;
  //  el = -0.1 * pi + pi * mPtr.y;
  //}
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  zmFac = 2.;
  rd = normalize (vec3 ((2. * tan (0.5 * atan (uv.x / (asp * zmFac)))) * asp,
     uv.y / zmFac, 1.));
  pF = TrackPath (vFly * tCur + 0.1);
  pB = TrackPath (vFly * tCur - 0.1);
  ro = 0.5 * (pF + pB);
  vd = normalize (pF - pB);
  u = - vd.y * vd;
  f = 1. / sqrt (1. - vd.y * vd.y);
  vuMat = mat3 (f * vec3 (vd.z, 0., - vd.x), f * vec3 (u.x, 1. + u.y, u.z), vd) *
     vuMat;
  rd = vuMat * rd;
  ltPos = ro + vuMat * vec3 (0.3, 0.5, 0.1);
  dstFar = 30.;
  glFragColor = vec4 (pow (clamp (ShowScene (ro, rd), 0., 1.), vec3 (0.6)), 1.);
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

const vec3 cHashA3 = vec3 (1., 57., 113.);
const float cHashM = 43758.54;

float Hashfv3 (vec3 p)
{
  return fract (sin (dot (p, cHashA3)) * cHashM);
}
