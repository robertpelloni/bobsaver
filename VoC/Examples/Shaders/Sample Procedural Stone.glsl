#version 420

// original https://www.shadertoy.com/view/3lj3RG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

// params
#define MARCHING_STEPS 100
#define MATERIAL_COLOR_A vec3(0.2, 0.3, 0.9)
#define MATERIAL_COLOR_B vec3(0.1, 0.2, 0.1)
#define MATERIAL_COLOR_C vec3(0.3, 0.9, 0.1)

#define SHADOW_STEPS 16
#define AO_STEPS 8

// noise
// Volume raycasting by XT95
// https://www.shadertoy.com/view/lss3zr
float hash(in float x) {
  return fract(sin(x) * 43237.5324);
}
vec3 hash3(in float x) {
  return vec3(
      hash(x +   .0),
      hash(x +  53.0),
      hash(x + 117.0)
    );
}
float noise(in vec3 x) {
  vec3 f = fract(x);
  vec3 i = floor(x);
  f = f*f*(3.0-2.0*f);
  float n = i.x*1.0 + i.y*57.0 + i.z*113.0;
  return mix(mix(mix(hash(n +   0.0), hash(n +   1.0), f.x),
                 mix(hash(n +  57.0), hash(n +  58.0), f.x), f.y),
             mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
                 mix(hash(n + 170.0), hash(n + 171.0), f.x), f.y), f.z);
}
mat3 m = mat3( 0.64,  0.80,  0.60,
              -0.80,  0.36, -0.48,
              -0.60, -0.48,  0.64 );
float fbm(in vec3 x) {
  float f = 0.0;
  f += 0.5000*noise(x); x=m*x*2.02;
  f += 0.2500*noise(x); x=m*x*2.03;
  f += 0.1250*noise(x); x=m*x*2.01;
  f += 0.0625*noise(x);
  return f;
}
float usin(in float x) {
  return 0.5 + 0.5*sin(x);
}
vec2 rotate(in vec2 p, in float r) {
  float c=cos(r), s=sin(r);
  return mat2(c, -s, s, c) * p;
}

float box(in vec3 p, in vec3 b) {
  vec3 d = abs(p) - b;
  return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.);
}
float plane(in vec3 p, in vec3 n, in float h) {
  return dot(p, n) - h;
}

float stone(in vec3 p, in float r, in float seed) {
  float b = box(p, vec3(r));
  for(int i=0;i<8;i++) {
    float fi = float(i+1);
    vec3 n = normalize(-1.0+2.0*hash3(fi*seed));
    b = max(b, plane(p, n, 0.5*r+(0.1*hash(fi+seed))));
  }
  return b;
}

vec2 opU(in vec2 d1, in vec2 d2) {
  return d1.x<d2.x ? d1 : d2;
}
vec3 objTx(vec3 p) {
    p.y -= 1.0;
    p.xy = rotate(p.xy, time*0.20);
    p.yz = rotate(p.yz, time*0.14);
    p.zx = rotate(p.zx, time*0.17);
    return p;
}

vec2 map(in vec3 p) {
  float ground = plane(p+vec3(0.,0.2*fbm(p*7.0), 0.), vec3(0.,1.,0.), -1e-4);
  vec3 q = p;
  q = objTx(q);
  float t = time*0.1;
  float ft = fract(t);
  float it = floor(t);

  float s1 = stone(q, 0.5, it);
  float s2 = stone(q, 0.5, it+1.0);
  float obj = mix(s1, s2, ft);
  return opU(vec2(ground, 0.), vec2(obj, 1.0));
}

vec2 march(in vec3 ro, in vec3 rd) {
  float mn=0.0, mx=1000.0;
  float thr = 1e-4;

  float d=0.0, m=-1.0;
  for(int i=0;i<MARCHING_STEPS;i++) {
    vec3 pos = ro + rd*d;
    vec2 tmp = map(pos);
    if(tmp.x<thr || mx<tmp.x) break;
    d += tmp.x*0.5;
    m = tmp.y;
  }
  if(mx<d) m = -1.0;
  return vec2(d, m);
}

vec3 calcNormal(in vec3 p) {
  vec2 e = vec2(1.0, -1.0) * 1e-4;
  return normalize(
      e.xyy * map(p + e.xyy).x +
      e.yxy * map(p + e.yxy).x +
      e.yyx * map(p + e.yyx).x +
      e.xxx * map(p + e.xxx).x
    );
}

float maxHei = 5.8;
float calcSoftShadow(in vec3 ro, in vec3 rd, in float tmn, in float tmx) {
  // bouding volume
  float tp = (maxHei - ro.y)/rd.y;
  if(tp>0.0) tmx = min(tmx, tp);

  float res = 1.0;
  float t = tmn;
  for(int i=0;i<SHADOW_STEPS;i++) {
    float h = map(ro + rd*t).x;
    res = min(res, 8.0*h/t);
    t += clamp(h, 0.02, 0.1);
    if(res<0.005 || tmx<res) break;
  }
  return clamp(res, 0., 1.);
}
float calcAO(in vec3 pos, in vec3 nor) {
  float occ = 0.0;
  float sca = 1.0;
  for(int i=0;i<AO_STEPS;i++) {
    float hr = 0.01 + 0.12*float(i)/4.0;
    vec3 aopos = nor*hr + pos;
    float dd = map(aopos).x;
    occ += -(dd-hr)*sca;
    sca *= 0.95;
  }
  return clamp(1.0-3.0*occ, 0., 1.) * (0.5+0.5*nor.y);
}

vec3 render(in vec3 ro, in vec3 rd){
  // ray march and get position/normal/reflect vector.
  vec2 res = march(ro, rd);
  float d=res.x, m=res.y;
  vec3 pos = ro + rd * d;
  vec3 nor = calcNormal(pos);
  vec3 ref = reflect(rd, nor);

  // material
  vec3 color = vec3(0.0);
  if(m==0.0) {
    color = mix(vec3(0.3, 0.13, 0.02), vec3(0.3, 0.8, 0.1),
    pow(fbm(pos*0.5), 2.0));
  }
  else if(m==1.0) {
    vec3 mtlpos = objTx(pos);
    color = (
      MATERIAL_COLOR_A*fbm(mtlpos*vec3(0., 0., 1.)*42.0) +
      MATERIAL_COLOR_B*fbm(mtlpos*vec3(1.)*15.0) +
      MATERIAL_COLOR_C*fbm(mtlpos*vec3(1.)* 1.0)
    ) ;
  }

  // lighting
  /*
    reference :
    "Raymarching - Primitives" by iq 
    https://www.shadertoy.com/view/Xds3zN
  */
  float occ = calcAO(pos, nor);
  vec3 lp = vec3(cos(time), 1.+5.0*usin(time*0.3), sin(time));
  vec3 ld = normalize(lp - pos);
  float lr = 1.0;
  vec3 hal = normalize(ld - rd);
  float amb = sqrt(clamp(0.5+0.5*nor.y, 0., 1.));
  float dif = clamp(dot(nor, ld), 0., 1.);
  float bac = clamp(dot(nor, normalize(vec3(-ld.x, 0., -ld.y))), 0., 1.) * clamp(1.0-pos.y, 0., 1.);
  float dom = smoothstep(-0.2, 0.2, ref.y);
  float fre = pow(clamp(1.0+dot(nor, rd), 0., 1.), 2.);
  // calc SoftShadow
  dif *= calcSoftShadow(pos, ld, 0.02, 2.5);
  dom *= calcSoftShadow(pos, ref, 0.02, 2.5);
  // calc specular
  float spe = pow(clamp(dot(nor, hal), 0., 1.), 16.0) * dif * (0.04+0.96*pow(clamp(1.0+dot(hal, rd), 0., 1.), 5.0));
  // calc 'light n?' from lighting params
  vec3 lin = vec3(0.);
  lin += 5.80 * dif*vec3(1.0);
  lin += 2.85 * amb*vec3(1.0) * occ;
  lin += 0.55 * bac*vec3(1.0) * occ;
  lin += 0.85 * dom*vec3(1.0) * occ;
  lin += 0.25 * fre*vec3(1.0) * occ;
  // add distance attenuation
  float att = 1.0/pow(length(ld)/lr + 1.0, 2.0);
  lin *= att;
  color *= lin;
  if(m==1.0) color += 7.0 * spe*vec3(1.0, 1.0, 1.0);

  color *= exp(-0.001*d*d*d);
  return color;
}

void main(void) {
  vec2 uv = gl_FragCoord.xy/resolution.xy;
  vec2 p = (gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x, resolution.y);
  vec3 color = vec3(0.);
  float t = time * 0.3;

  vec3 ro = vec3(cos(t), 1.+usin(t*0.3), sin(t));
  ro.xz *= 1.0;
  vec3 tar = vec3(0., 1., 0.);
  vec3 cz = normalize(tar - ro);
  vec3 cx = normalize(cross(cz, vec3(0., 1., 0.)));
  vec3 cy = normalize(cross(cx, cz));
  vec3 rd = mat3(cx, cy, cz) * normalize(vec3(p, 1.0));

  color = render(ro, rd);

  glFragColor = vec4(color, 1.);
}
