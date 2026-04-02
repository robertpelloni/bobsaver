#version 420

// original https://www.shadertoy.com/view/4lKcRw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Fibonacci's Cones" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1   // optional antialiasing

float PrSphDf (vec3 p, float r);
vec2 Rot2D (vec2 q, float a);
vec2 Rot2Cs (vec2 q, vec2 cs);

vec3 ltDir;
vec2 sRot;
float tCur, dstFar;
const float pi = 3.14159, phi = 1.618034;

float SphFib (vec3 v, float n)
{   // based on iq's version of Keinert et al's Spherical Fibonnacci Mapping code
  vec4 b;
  vec3 q;
  vec2 ff, c;
  float fk, ddMin, a, z, ni;
  ni = 1. / n;
  fk = pow (phi, max (2., floor (log (n * pi * sqrt (5.) * (1. - v.z * v.z)) / log (phi + 1.)))) / sqrt (5.);
  ff = vec2 (floor (fk + 0.5), floor (fk * phi + 0.5));
  b = 2. * vec4 (ff * ni, pi * (fract ((ff + 1.) * phi) - (phi - 1.)));
  c = floor ((mat2 (b.y, - b.x, b.w, - b.z) / (b.y * b.z - b.x * b.w)) *
     vec2 (atan (v.y, v.x), v.z - (1. - ni)));
  ddMin = 4.1;
  for (int s = 0; s < 4; s ++) {
    a = dot (ff, vec2 (s - 2 * (s / 2), s / 2) + c);
    z = 1. - (2. * a + 1.) * ni;
    q = vec3 (sin (2. * pi * fract (phi * a) + vec2 (0.5 * pi, 0.)) * sqrt (1. - z * z), z) - v;
    ddMin = min (ddMin, dot (q, q));
  }
  return sqrt (ddMin);
}

float ObjDf (vec3 p)
{
  float d;
  d = PrSphDf (p, 1.11);
  if (d < 0.05) {
    p.xz = Rot2Cs (p.xz, sRot);
    d = 0.4 * PrSphDf (p, 1.1 - 0.1 * smoothstep (0.015, 0.07, SphFib (normalize (p), 512.)));
  }
  return d;
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 150; j ++) {
    d = ObjDf (ro + dHit * rd);
    if (d < 0.0005 || dHit > dstFar) break;
    dHit += d;
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

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.05;
  for (int j = 0; j < 30; j ++) {
    h = ObjDf (ro + d * rd);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += max (0.05, h);
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj, sh;
  sRot = sin (0.03 * tCur + vec2 (0.5 * pi, 0.));
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    sh = ObjSShadow (ro, ltDir);
    col = vec3 (0.2, 1., 0.3) * (0.4 + 0.6 * smoothstep (1., 1.02, length (ro)));
    col = col * (0.1 + 0.1 * max (dot (vn, - normalize (vec3 (ltDir.xz, 0.).xzy)), 0.) +
       0.8 * sh * max (dot (vn, ltDir), 0.)) +
       0.2 * smoothstep (0.8, 0.9, sh) * sh * pow (max (dot (normalize (ltDir - rd), vn), 0.), 64.);
  } else {
    col = mix (vec3 (1., 1., 0.5), vec3 (0., 0., 0.3 * (0.7 + 0.3 * rd.y)),
       smoothstep (0.0035, 0.004, SphFib (rd, 8192.)));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = vec4(0.0);//mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = -0.1 * pi;
  if (mPtr.z > 0.) {
    az += 2. * pi * mPtr.x;
    el += pi * mPtr.y;
  }
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -8.);
  dstFar = 20.;
  ltDir = normalize (vec3 (0.5, 3., -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.),
       0.5 * pi * (a + 0.5)), 6.));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (pow (col, vec3 (0.8)), 1.);
}

float PrSphDf (vec3 p, float r)
{
  return length (p) - r;
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}

vec2 Rot2Cs (vec2 q, vec2 cs)
{
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}
