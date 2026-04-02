#version 420

// original https://www.shadertoy.com/view/4dVyzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Supercoiled Helix Bundle" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

vec2 Rot2D (vec2 q, float a);

vec3 ltDir;
float tCur, dstFar;
const float pi = 3.14159;

float ObjDf (vec3 p)
{
  float cvOrd, a;
  cvOrd = 7.;
  a = atan (p.z, p.x) / (2. * pi);
  p.xz = Rot2D (vec2 (length (p.xz) - 2., mod (p.y + 2. * a + 2., 2.) - 1.),
     2. * pi * (cvOrd - 1.) * a);
  return 0.4 * (length (Rot2D (p.xz, - (floor ((0.5 * pi - atan (p.x, p.z)) + pi / cvOrd))) -
     vec2 (0.6, 0.)) - 0.15);
}

float ObjRay (vec3 ro, vec3 rd)
{
  float dHit, d;
  dHit = 0.;
  for (int j = 0; j < 200; j ++) {
    d = ObjDf (ro + rd * dHit);
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

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    col = vec3 (0.7, 0.7, 0.8) * (0.2 + 0.8 * max (dot (vn, ltDir), 0.)) +
       0.4 * vec3 (1., 1., 0.7) * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
  } else {
    col = vec3 (0.6, 0.6, 1.) * (0.2 + 0.2 * (rd.y + 1.) * (rd.y + 1.));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec2 mPtr;
  vec3 ro, rd;
  vec2 canvas, uv, ori, ca, sa;
  float el, az;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  mPtr = mouse*resolution.xy;
  mPtr.xy = mPtr.xy / canvas - 0.5;
  az = 0.;
  el = 0.;
  //if (mPtr.z > 0.) {
  //  az += 3. * pi * mPtr.x;
  //  el += pi * mPtr.y;
  //} else {
    az -= 0.1 * pi * tCur;
    el -= 0.35 * pi * sin (0.07 * pi * tCur);
  //}
  el = clamp (el, -0.4 * pi, 0.4 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -20.);
  rd = vuMat * normalize (vec3 (uv, 5. + 2. * sin (0.05 * pi * tCur)));
  dstFar = 100.;
  ltDir = vuMat * normalize (vec3 (1., 1., -1.));
  glFragColor = vec4 (ShowScene (ro, rd), 1.);
}

vec2 Rot2D (vec2 q, float a)
{
  return q * cos (a) + q.yx * sin (a) * vec2 (-1., 1.);
}
