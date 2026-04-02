#version 420

// original https://www.shadertoy.com/view/MdffRS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Mandel Oct Vox" by dr2 - 2017
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

// Truncated octahedral voxel tracer distilled from culdevu's shader.
// Architecture from "Mandel City" which used a cubic voxel tracer.

vec3 ltDir, cMid;
float dstFar, fcId;
const float pi = 3.14159;

bool HitMand (vec3 p)
{
  vec3 q;
  vec2 v, w;
  float h;
  h = 0.;
  p.xz *= 0.03;
  p.x -= 0.85;
  q = 0.01 * floor (100. * p);
  if (length (q.xz + vec2 (0.25, 0.)) > 0.45 &&
     length (q.xz + vec2 (1., 0.)) > 0.2 &&
     (q.x < 0. || abs (q.z) > 0.04)) {
    v = q.xz;
    h = 80.;
    for (int j = 0; j < 80; j ++) {
      w = v * v;
      if (w.x + w.y > 4.) {
        h = float (j + 1);
        break;
      } else v = q.xz + vec2 (w.x - w.y, 2. * v.x * v.y);
    }
  }
  return (0.3 * h > q.y);
}

vec3 FcVec (float k)
{
  vec3 u;
  const vec3 e = vec3 (1., 0., -1.);
  if (k <= 3.) u = (k == 1.) ? e.xyy : ((k == 2.) ? e.yxy : e.yyx);
  else if (k <= 5.) u = 0.5 * ((k == 4.) ? e.xxx : e.zxx);
  else u = 0.5 * ((k == 6.) ? e.xzx : e.xxz);
  return u;
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 p, cm, fv;
  float dHit, d, dd, s;
  cMid = sign (ro) * floor (abs (ro) + 0.5);
  cm = mod (cMid, 2.);
  s = cm.x + cm.y + cm.z;
  if (s == 1. || s == 2.)
     cMid += step (abs (cm.yzx - cm.zxy), vec3 (0.5)) * sign (ro - cMid);
  dHit = 0.;
  for (int j = 0; j < 220; j ++) {
    p = cMid - (ro + dHit * rd);
    fcId = 0.;
    d = dstFar;
    for (float k = 1.; k <= 7.; k ++) {
      fv = FcVec (k);
      s = dot (fv, rd);
      if (s != 0.) {
        dd = dot (p + sign (s) * fv, fv)  / s;
        if (dd < d) {
          d = dd;
          fcId = sign (s) * k;
        }
      }
    }
    cMid = floor (cMid + 2. * sign (fcId) * FcVec (abs (fcId)) + 0.5);
    dHit += d;
    if (HitMand (cMid) || dHit > dstFar) break;
  }
  return dHit;
}

vec3 HsvToRgb (vec3 c)
{
  vec3 p;
  p = abs (fract (c.xxx + vec3 (1., 2./3., 1./3.)) * 6. - 3.);
  return c.z * mix (vec3 (1.), clamp (p - 1., 0., 1.), c.y);
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 vn, col;
  float dstObj;
  dstObj = ObjRay (ro, rd);
  ro += rd * dstObj;
  if (length (ro.xz - vec2 (8., 0.)) > 50.) dstObj = dstFar;
  if (dstObj < dstFar) {
    vn = - normalize (sign (fcId) * FcVec (abs (fcId)));
    col = HsvToRgb (vec3 (mod (0.039 * cMid.y, 1.), 1., 1.));
    col = col * (0.1 + 0.1 * max (vn.y, 0.) + 0.8 * max (dot (vn, ltDir), 0.)) +
       0.2 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 128.);
    col = pow (clamp (col, 0., 1.), vec3 (0.5));
  } else {
    col = vec3 (0.9, 0.9, 1.) * (0.6 + 0.4 * rd.y);
  }
  return col;
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float az, el, tCur;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  //mPtr = mouse*resolution.xy;
  //mPtr.xy = mPtr.xy / canvas - 0.5;
  //if (mPtr.z > 0.) {
  //  az = 1.5 * pi * mPtr.x;
  //  el = -0.3 * pi + 0.7 * pi * mPtr.y;
  //} else {
    az = 0.6 * pi * sin (0.03 * pi * tCur);
    el = -0.3 * pi + 0.1 * pi * sin (0.05 * pi * tCur);
  //}
  el = clamp (el, -0.45 * pi, -0.05 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  rd = vuMat * normalize (vec3 (uv, 2.2));
  ro = vuMat * vec3 (0., -5., -120.);
  ltDir = vuMat * normalize (vec3 (1., 2.5, -1.));
  dstFar = 200.;
  if (0.5 * abs (uv.x) < canvas.y / canvas.x) {
    ro.xy += vec2 (8., 5.);
    col = ShowScene (ro, rd);
  } else col = vec3 (0.9, 0.9, 1.) * (0.6 + 0.4 * rd.y);
  glFragColor = vec4 (col, 1.);
}
