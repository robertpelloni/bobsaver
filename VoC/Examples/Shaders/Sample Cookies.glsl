#version 420

// original https://www.shadertoy.com/view/tlBSzR

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "Cookies" by dr2 - 2019
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

float PrCylDf (vec3 p, float r, float h);
vec2 PixToHex (vec2 p);
vec2 HexToPix (vec2 h);
float Minv3 (vec3 p);
float SmoothMin (float a, float b, float r);
vec2 Rot2D (vec2 q, float a);
vec2 Hashv2v2 (vec2 p);
float Fbm2 (vec2 p);
vec3 VaryNf (vec3 p, vec3 n, float f);

mat3 flMat;
vec3 ltDir, flPos;
vec2 gId;
float tCur, dstFar, hgSize, bRad, nArm, armDir, armFrq;
bool isOcc;
const float pi = 3.14159, sqrt3 = 1.7320508;

float ObjDf (vec3 p)
{
  vec3 q;
  float d, bLen, h, r;
  d = dstFar;
  if (isOcc) {
    bLen = 0.5;
    p.y -= 0.02;
    p.xz -= HexToPix (gId * hgSize);
    q = p;
    r = length (q.xz);
    q.xz = Rot2D (q.xz, armDir * (0.1 * pi * r * (1. + 0.1 * sin (2. * pi * armFrq * r))
       - 0.03 * pi * q.y * (1. + sin (2. * pi * 1.5 * r))));
    q.xz = Rot2D (q.xz, 2. * pi * (floor (nArm * atan (q.z, - q.x) / (2. * pi) + 0.5) / nArm));
    q.x += bLen;
    h = 0.25 * (1. - q.x / bLen);
    h = 0.3 * (1. - 3.2 * h * h);
    q.y -= h + 0.05;
    d = length (max (abs (q) - vec3 (bLen, h, 0.001 * (1. + 12. * q.x) * (4. - 20. * q.y)), 0.)) - 0.05;
    q = p;
    q.y -= 0.35;
    d = SmoothMin (d, PrCylDf (q.xzy, 0.01, 0.35), 0.03);
    q = p;
    q.y -= -1.25;
    d = 0.8 * SmoothMin (d, - SmoothMin (min (bRad - length (q), q.y - 1.25), 2.2 * bLen -
       r, 0.05), 0.05);
  }
  return d;
}

void SetGrObjConf ()
{
  vec2 fRand;
  float emFrac;
  emFrac = 0.02;
  fRand = Hashv2v2 (gId * vec2 (37.3, 43.1) + 27.1);
  isOcc = (fRand.y >= emFrac);
  if (isOcc) {
    nArm = 6. + floor (20. * fRand.x);
    armDir = 2. * floor (mod (32. * fRand.x, 2.)) - 1.;
    fRand.y = (fRand.y - emFrac) / (1. - emFrac);
    armFrq = 2. + 6. * fRand.y;
  }
}

float ObjRay (vec3 ro, vec3 rd)
{
  vec3 vri, vf, hv, p;
  vec2 edN[3], pM, gIdP;
  float dHit, d, s, eps;
  eps = 0.0005;
  edN[0] = vec2 (1., 0.);
  edN[1] = 0.5 * vec2 (1., sqrt3);
  edN[2] = 0.5 * vec2 (1., - sqrt3);
  for (int k = 0; k < 3; k ++) edN[k] *= sign (dot (edN[k], rd.xz));
  vri = hgSize / vec3 (dot (rd.xz, edN[0]), dot (rd.xz, edN[1]), dot (rd.xz, edN[2]));
  vf = 0.5 * sqrt3 - vec3 (dot (ro.xz, edN[0]), dot (ro.xz, edN[1]),
     dot (ro.xz, edN[2])) / hgSize;
  pM = HexToPix (PixToHex (ro.xz / hgSize));
  gIdP = vec2 (-99.);
  dHit = 0.;
  for (int j = 0; j < 160; j ++) {
    hv = (vf + vec3 (dot (pM, edN[0]), dot (pM, edN[1]), dot (pM, edN[2]))) * vri;
    s = Minv3 (hv);
    p = ro + dHit * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId.x != gIdP.x || gId.y != gIdP.y) {
      gIdP = gId;
      SetGrObjConf ();
    }
    d = ObjDf (p);
    if (dHit + d < s) {
      dHit += d;
    } else {
      dHit = s + eps;
      pM += sqrt3 * ((s == hv.x) ? edN[0] : ((s == hv.y) ? edN[1] : edN[2]));
    }
    if (d < eps || dHit > dstFar || p.y < 0.) break;
  }
  if (d >= eps) dHit = dstFar;
  return dHit;
}

vec3 ObjNf (vec3 p)
{
  vec4 v;
  vec2 e = vec2 (0.001, -0.001);
  v = vec4 (- ObjDf (p + e.xxx), ObjDf (p + e.xyy), ObjDf (p + e.yxy), ObjDf (p + e.yyx));
  return normalize (2. * v.yzw - dot (v, vec4 (1.)));
}

float ObjSShadow (vec3 ro, vec3 rd)
{
  vec3 p;
  vec2 gIdP;
  float sh, d, h;
  sh = 1.;
  d = 0.1;
  gIdP = vec2 (-99.);
  for (int j = 0; j < 30; j ++) {
    p = ro + d * rd;
    gId = PixToHex (p.xz / hgSize);
    if (gId.x != gIdP.x || gId.y != gIdP.y) {
      gIdP = gId;
      SetGrObjConf ();
    }
    h = ObjDf (p);
    sh = min (sh, smoothstep (0., 0.05 * d, h));
    d += clamp (h, 0.03, 0.3);
    if (sh < 0.05) break;
  }
  return 0.5 + 0.5 * sh;
}

vec3 ShowScene (vec3 ro, vec3 rd)
{
  vec4 col4;
  vec3 col, vn;
  float dstObj, s;
  bool needSh;
  bRad = 1.75;
  needSh = false;
  dstObj = ObjRay (ro, rd);
  if (dstObj < dstFar) {
    ro += dstObj * rd;
    vn = ObjNf (ro);
    s = length (ro - vec3 (HexToPix (gId * hgSize), 0.02 - 1.25).xzy) - bRad - 0.003;
    col4 = mix (mix (vec4 (0.7, 0.4, 0., 0.05), vec4 (0.3, 0.1, 0., 0.1),
       step (0.6, Fbm2 (16. * ro.xz))), vec4 (1., 1., 1., 0.5), smoothstep (0., 0.02, s));
    s = step (0., s);
    vn = VaryNf ((8. + 56. * s) * ro, vn, 4. - 3. * s);
    col = col4.rgb * (0.2 + 0.8 * max (dot (vn, ltDir), 0.)) +
       col4.a * pow (max (dot (normalize (ltDir - rd), vn), 0.), 16.);
    needSh = true;
  } else if (rd.y < 0.) {
    dstObj = - ro.y / rd.y;
    ro += dstObj * rd;
    vn = vec3 (0., 1., 0.);
    col = vec3 (0.6, 0.6, 0.7) * (0.2 + 0.8 * max (dot (vn, ltDir), 0.)) +
       0.3 * pow (max (dot (normalize (ltDir - rd), vn), 0.), 32.);
    if (dstObj < dstFar) {
      gId = PixToHex (ro.xz / hgSize);
      SetGrObjConf ();
      s = length (ro.xz - HexToPix (gId * hgSize));
      if (isOcc) col *= 0.7 + 0.3 * smoothstep (1., 1.2, s);
      else if (s < 1.) col = mix (col, vec3 (0.7, 0.4, 0.),
         step (1.2, Fbm2 (32. * ro.xz) + Fbm2 (32. * Rot2D (ro.xz, 0.22 * pi))) *
         (1. - smoothstep (0.5, 1.5, s)));
      needSh = true;
    }
  } else {
    col = vec3 (0.6, 0.6, 0.6);
  }
  if (needSh) col *= ObjSShadow (ro, ltDir);
  return clamp (col, 0., 1.);
}

vec3 TrackPath (float t)
{
  return t * vec3 (0.1, 0., sqrt (0.99)) + vec3 (2. * cos (0.1 * t), 0., 0.);
}

void VuPM (float t)
{
  vec3 fpF, fpB, vel, acc, va, ort, cr, sr;
  float dt;
  dt = 1.;
  flPos = TrackPath (t);
  fpF = TrackPath (t + dt);
  fpB = TrackPath (t - dt);
  vel = (fpF - fpB) / (2. * dt);
  vel.y = 0.;
  acc = (fpF - 2. * flPos + fpB) / (dt * dt);
  acc.y = 0.;
  va = cross (acc, vel) / length (vel);
  ort = vec3 (0.2, atan (vel.z, vel.x) - 0.5 * pi, 5. * length (va) * sign (va.y));
  cr = cos (ort);
  sr = sin (ort);
  flMat = mat3 (cr.z, - sr.z, 0., sr.z, cr.z, 0., 0., 0., 1.) *
     mat3 (1., 0., 0., 0., cr.x, - sr.x, 0., sr.x, cr.x) *
     mat3 (cr.y, 0., - sr.y, 0., 1., 0., sr.y, 0., cr.y);
}

#define AA  1 

void main(void)
{
  mat3 vuMat;
  vec4 dateCur;
  vec3 ro, rd, col;
  vec2 canvas, uv, ori, ca, sa;
  float el, az, zmFac, sr;
  canvas = resolution.xy;
  uv = 2. * gl_FragCoord.xy / canvas - 1.;
  uv.x *= canvas.x / canvas.y;
  tCur = time;
  dateCur = date;
  tCur = mod (tCur, 2400.) + 30. * floor (dateCur.w / 7200.) + 11.1;
  hgSize = 1.4;
  VuPM (0.9 * tCur);
  az = 0.;
  el = -0.1 * pi;
  ori = vec2 (el, az);
  ca = cos (ori);
  sa = sin (ori);
  vuMat = mat3 (ca.y, 0., - sa.y, 0., 1., 0., sa.y, 0., ca.y) *
          mat3 (1., 0., 0., 0., ca.x, - sa.x, 0., sa.x, ca.x);
  flPos.y += 10.;
  ro = flPos;
  zmFac = 8. + 4. * sin (0.02 * 2. * pi * tCur);
  dstFar = 50.;
  ltDir = normalize (vec3 (-1.3, 0.7, -1.));
#if ! AA
  const float naa = 1.;
#else
  const float naa = 3.;
#endif  
  col = vec3 (0.);
  sr = 2. * mod (dot (mod (floor (0.5 * (uv + 1.) * canvas), 2.), vec2 (1.)), 2.) - 1.;
  for (float a = 0.; a < naa; a ++) {
    rd = normalize (vec3 (uv + step (1.5, naa) * Rot2D (vec2 (0.5 / canvas.y, 0.),
       sr * (0.667 * a + 0.5) * pi), zmFac));
    rd = vuMat * rd;
    rd = rd * flMat;
    col += (1. / naa) * ShowScene (ro, rd);
  }
  glFragColor = vec4 (pow (col, vec3 (0.9)), 1.);
}

float PrCylDf (vec3 p, float r, float h)
{
  return max (length (p.xy) - r, abs (p.z) - h);
}

vec2 PixToHex (vec2 p)
{
  vec3 c, r, dr;
  c.xz = vec2 ((1./sqrt3) * p.x - (1./3.) * p.y, (2./3.) * p.y);
  c.y = - c.x - c.z;
  r = floor (c + 0.5);
  dr = abs (r - c);
  r -= step (dr.yzx, dr) * step (dr.zxy, dr) * dot (r, vec3 (1.));
  return r.xz;
}

vec2 HexToPix (vec2 h)
{
  return vec2 (sqrt3 * (h.x + 0.5 * h.y), (3./2.) * h.y);
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

vec2 Rot2D (vec2 q, float a)
{
  vec2 cs;
  cs = sin (a + vec2 (0.5 * pi, 0.));
  return vec2 (dot (q, vec2 (cs.x, - cs.y)), dot (q.yx, cs));
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
