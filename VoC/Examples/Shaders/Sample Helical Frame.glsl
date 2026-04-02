#version 420

// original https://www.shadertoy.com/view/MdKyWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Helical Frame" by dr2 - 2018
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

#define AA  1   // optional antialiasing (0/1 - off/on)

float PrBox2Df (vec2 p, vec2 b);
float PrBoxAn2Df (vec2 p, vec2 b, float w);
vec2 Rot2D (vec2 q, float a);

vec3 ltDir;
float tCur, dstFar;
const float pi = 3.14159;

float ObjDf (vec3 p)
{
  vec3 q;
  float d, a, aa, gz;
  q = p;
  aa = atan (q.z, q.x) / (2. * pi);
  a = 0.5 * sign (q.z) - aa;
  q.y = mod (q.y + 2. * a + 1., 2.) - 1.;
  d = PrBoxAn2Df (Rot2D (vec2 (length (q.xz) - 4., q.y), 6. * pi * aa), vec2 (0.5), 0.05);
  gz = dot (q.zx, sin (2. * pi * ((floor (32. * a) + 0.5) / 32. + vec2 (0.25, 0.))));
  q.xy = Rot2D (vec2 (dot (q.xz, sin (2. * pi * (vec2 (0.25, 0.) - a))) + 4., q.y), 6. * pi  * a);
  d = max (d, - min (PrBox2Df (vec2 (q.x, gz), vec2 (0.35, 0.25)),
     PrBox2Df (vec2 (q.y, gz), vec2 (0.35, 0.25))));
  return 0.6 * d;
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

float ObjSShadow (vec3 ro, vec3 rd)
{
  float sh, d, h;
  sh = 1.;
  d = 0.1;
  for (int j = 0; j < 50; j ++) {
    h = ObjDf (ro + rd * d);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += min (0.2, 3. * h);
    if (sh < 0.001) break;
  }
  return 0.4 + 0.6 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec3 col, vn;
  float dstObj, sh;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    sh = ObjSShadow (ro, ltDir);
    col = vec3 (0.7, 0.6, 0.6) * (0.2 + 0.8 * sh * max (dot (vn, ltDir), 0.)) +
       0.4 * vec3 (0.7, 0.7, 1.) * smoothstep (0.5, 0.8, sh) *
       pow (max (dot (normalize (ltDir - rd), vn), 0.), 64.);
  } else {
    col = vec3 (0.6, 1., 0.6) * (0.2 + 0.2 * (rd.y + 1.) * (rd.y + 1.));
  }
  return clamp (col, 0., 1.);
}

void main(void)
{
  mat3 vuMat;
  vec4 mPtr;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac;
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
    el += 0.8 * pi * mPtr.y;
  } else {
    az += 0.1 * pi * tCur;
    el += 0.35 * pi * sin (0.07 * pi * tCur);
  }
  el = clamp (el, -0.35 * pi, 0.35 * pi);
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  ro = vuMat * vec3 (0., 0., -20.);
  zmFac = 5. + 2. * sin (0.05 * pi * tCur);
  dstFar = 100.;
  ltDir = vuMat * normalize (vec3 (-1., 1., -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 4.;
#endif  
  col = vec3 (0.);
  for (float a = 0.; a < naa; a ++) {
    rd = vuMat * normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.71 / canvas.y, 0.),
       0.5 * pi * (a + 0.5)), zmFac));
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (col, 1.);
}

float PrBox2Df (vec2 p, vec2 b)
{
  vec2 d;
  d = abs (p) - b;
  return min (max (d.x, d.y), 0.) + length (max (d, 0.));
}

float PrBoxAn2Df (vec2 p, vec2 b, float w)
{
  return max (PrBox2Df (p, vec2 (b + w)), - PrBox2Df (p, vec2 (b - w)));
}

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
}
