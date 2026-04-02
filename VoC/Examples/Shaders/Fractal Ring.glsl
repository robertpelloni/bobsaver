#version 420

// original https://www.shadertoy.com/view/4stfWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Fractal Ring" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Inside a changing fractal (similar to "Light and Motion", mouseable)

#define AA  0   // optional antialiasing

vec3 HsvToRgb (vec3 c);
vec2 Rot2D (vec2 q, float a);
float Noisefv3 (vec3 p);

vec3 ltPos[2], ltAx;
float tCur, dstFar, rRad, frctAng;
const float pi = 3.14159;
const float itMax = 18.;

float ObjDf (vec3 p) 
{
  vec4 p4;
  float s, r;
  p.xy = Rot2D (p.xy, 0.5 * pi);
  r = length (p.yz);
  p.yz = vec2 (2. * pi * rRad * ((r > 0.) ? atan (p.z, - p.y) / (2. * pi) : 0.), r - rRad);
  p4 = vec4 (p, 1.);
  for (float j = 0.; j < itMax; j ++) {
    p4.xyz = abs (p4.xyz) - vec3 (-0.02, 1.98, -0.02);
    p4 = (2. / clamp (dot (p4.xyz, p4.xyz), 0.4, 1.)) * p4 - vec4 (0.5, 1., 0.4, 0.);
    p4.xz = Rot2D (p4.xz, frctAng);
  }
  return max ((length (p4.xyz) - 0.02) / p4.w, 0.01 - length (p.xz));
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, h, s, sLo, sHi, eps;
  eps = 0.0003;
  s = 0.;
  sLo = 0.;
  dHit = dstFar;
  for (int j = 0; j < 120; j ++) {
    h = ObjDf (ro + s * rd);
    if (h < eps || s > dstFar) {
      sHi = s;
      break;
    }
    sLo = s;
    s += h;
  }
  if (h < eps) {
    for (int j = 0; j < 4; j ++) {
      s = 0.5 * (sLo + sHi);
      h = step (eps, ObjDf (ro + s * rd));
      sLo += h * (s - sLo);
      sHi += (1. - h) * (s - sHi);
    }
    dHit = sHi;
  }
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.0001, -0.0001);
  v = vec4 (ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (vec3 (v.x - v.y - v.z - v.w) + 2. * v.yzw);
}

float ObjSShadow (vec3 ro, vec3 rd, float dMax)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 40; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += min (0.05, 3. * h);
    if (sh < 0.05 || d > dMax) break;
  }
  return 0.2 + 0.8 * sh;
}

float ObjAO (vec3 ro, vec3 rd)
{
  float ao, d;
  ao = 0.;
  for (float j = 1.; j < 4.; j ++) {
    d = 0.03 * j;
    ao += max (0., d - ObjDf (ro + d * rd));
  }
  return clamp (1. - 5. * ao, 0., 1.);
}

vec4 ObjCol (vec3 p)
{
  float pp, ppMin, cn, s, r;
  p.xy = Rot2D (p.xy, 0.5 * pi);
  r = length (p.yz);
  p.yz = vec2 (2. * pi * rRad * ((r > 0.) ? atan (p.z, - p.y) / (2. * pi) : 0.), r - rRad);
  cn = 0.;
  ppMin = 1.;
  for (float j = 0.; j < itMax; j ++) {
    p = abs (p) - vec3 (-0.02, 1.98, -0.02);
    pp = clamp (dot (p, p), 0.4, 1.);
    if (pp < ppMin) {
      cn = j;
      ppMin = pp;
    }
    p = (2. / pp) * p - vec3 (0.5, 1., 0.4);
    p.xz = Rot2D (p.xz, frctAng);
  }
  return vec4 (HsvToRgb (vec3 (mod (0.6 + 1.7 * cn / itMax, 1.), 0.8, 1.)), 0.5);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{ 
  vec4 col4;
  vec3 col, vn, ltDir, rds;
  float dstObj, atten, ao, sh, dfSum, spSum;
  frctAng = 0.5 * pi + 2. * pi * mod (0.005 * tCur, 1.);
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    dfSum = 0.;
    spSum = 0.;
    for (int k = 0; k < 2; k ++) {
      ltDir = ltPos[k] - ro;
      atten = 1. / (1. + 0.3 * dot (ltDir, ltDir));
      ltDir = normalize (ltDir);
      atten *= smoothstep (0.3, 0.4, dot (ltAx, - ltDir));
      dfSum += atten * max (dot (vn, ltDir), 0.);
      spSum += atten * pow (max (0., dot (ltDir, reflect (rd, vn))), 64.);
    }
    ltDir = normalize (0.5 * (ltPos[0] + ltPos[1]) - ro);
    sh = ObjSShadow (ro, ltDir, max (dstObj - 0.2, 0.));
    ao = ObjAO (ro, vn);
    col4 = ObjCol (ro);
    col = (0.1 + 0.4 * sh * dfSum) * col4.rgb + col4.a * sh * spSum * vec3 (1.);
    col *= 0.2 + 0.8 * ObjAO (ro, vn);
    col += vec3 (0.2) * max (dot (- rd, vn), 0.) *
       (1. - smoothstep (0., 0.02, abs (dstObj - mod (0.1 * tCur, 2.))));
  } else {
    if (rd.y < 0.) {
      rd.y = - rd.y;
      rd.xz = vec2 (- rd.z, rd.x);
    }
    rds = floor (2000. * rd);
    rds = 0.00015 * rds + 0.1 * Noisefv3 (0.0005 * rds.yzx);
    for (int j = 0; j < 19; j ++) rds = abs (rds) / dot (rds, rds) - 0.9;
    col = vec3 (0.02, 0.02, 0.05) + 0.8 * vec3 (1., 1., 0.7) * min (1., 0.5e-3 *
       pow (min (6., length (rds)), 5.));
  }
  return clamp (pow (col, vec3 (0.8)), 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col, vd, ori, ca, sa;
  vec2 canvas, uv;
  float el, az, a;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += 0.7 * pi * mPtr.y;
  }
  rRad = 9.9 / (2. * pi);
  a = 0.01 * 2. * pi * tCur;
  ro = rRad * vec3 (cos (a), 0., sin (a));
  ori = vec3 (el, az - a, 0.2 * pi * sin (3. * a));
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x) *
          mat3 (ca.z, - sa.z, 0., sa.z, ca.z, 0., 0., 0., 1.);
  ltPos[0] = ro + vuMat * vec3 (-0.3, 0.3, -0.2);
  ltPos[1] = ro + vuMat * vec3 (0.3, 0.3, -0.2);
  ltAx = vuMat * vec3 (0., 0., 1.);
  dstFar = 10.;
  #if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    rd = normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.),
       0.5 * pi * (a + 0.5)), 3.));
    rd = vuMat * rd;
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (pow (col, vec3 (0.8)), 1.);
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

const float cHashM = 43758.54;

vec4 Hashv4v3 (vec3 p)
{
  vec3 cHashVA3 = vec3 (37., 39., 41.);
  vec2 e = vec2 (1., 0.);
  return fract (sin (vec4 (dot (p + e.yyy, cHashVA3), dot (p + e.xyy, cHashVA3),
     dot (p + e.yxy, cHashVA3), dot (p + e.xxy, cHashVA3))) * cHashM);
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
