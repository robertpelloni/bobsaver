#version 420

// original https://www.shadertoy.com/view/MtKyzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer; // previous scene texture

out vec4 glFragColor;

//----- Ray-tracing parameters
const int   MAX_TRACE_STEP  = 100;
const float MAX_TRACE_DIST  = 300.;
const float NO_HIT_DIST     = 100.;
const float TRACE_PRECISION = .001;
const float FUDGE_FACTOR    = .9;
const int   RAY_TRACE_COUNT = 8;

// -- lighting parameters
const int   GI_TRACE_STEP = 4;
const float GI_LENGTH = 1.6;
const float GI_STRENGTH = 1.;
const float AO_STRENGTH = .4;
const int   SS_MAX_TRACE_STEP = 7;
const float SS_MAX_TRACE_DIST = 50.;
const float SS_MIN_MARCHING = .3;
const float SS_SHARPNESS = 1.;
const float CS_STRENGTH = 0.2;
const float CS_SHARPNESS = 0.2;

//----- Demo parameters
const float BPM = 120.;
const vec3 BG = vec3(.5);

//----- Constant
const vec3 PI = vec3(1.5707963,3.1415927,6.2831853);
const vec3 V  = vec3(0,TRACE_PRECISION,1);

//----- Structures
struct Material {
  vec3  kd, tc;
  float rl, rr; // diffusion, transparent-color, reflectance, refractive index
};
float rr2rl(float rr) { float v=(rr-1.)/(rr+1.); return v*v; }
Material matt(vec3 kd) { return Material(kd, vec3(0), 0., 1.); }
Material mirror(vec3 kd, float rl) { return Material(kd, vec3(0), rl, 0.); }
Material glass(vec3 tc, float rr) { return Material(vec3(0), tc, rr2rl(rr), rr); }

struct Surface {
  float d;      // distance
  Material mat; // material
};
Surface near(Surface s,Surface t) { if (s.d<t.d) return s; return t; }
Surface near(Surface s,Surface t,Surface u) { return near(near(s, t), u); }
Surface near(Surface s,Surface t,Surface u,Surface v) { return near(near(s,t),near(u,v)); }
Surface NO_HIT = Surface(NO_HIT_DIST, Material(vec3(0), vec3(0), 0., 1.));

struct Ray {
  vec3  org, dir, col;     // origin, direction, color
  float len, stp, rr, sgn; // length, marching step, refractive index of current media, sign of distance function
};
Ray ray(vec3 o, vec3 d) { return Ray(o,d,vec3(1),0.,0.,1.,1.); }
Ray ray(vec3 o, vec3 d, vec3 c, float rr, float s) { return Ray(o,d,c,0.,0.,rr,s); }
vec3 _pos(Ray r) { return r.org+r.dir*r.len; }

struct Hit {
  vec3 pos, nml; // position, normal
  Ray ray;       // ray
  Surface srf;   // surface
  bool isTransparent, isReflect;  // = (len2(srf.mat.tc) > 0.001, srf.mat.rl > 0.01)
};
Hit nohit(Ray r) { return Hit(vec3(0), vec3(0), r, NO_HIT, false, false); }

struct Camera {
  vec3  pos, tgt, rol;  // position, target, roll
  float fcs;            // focal length
};
mat3 cameraMatrix(Camera c) { vec3 w=normalize(c.pos-c.tgt),u=normalize(cross(w,c.rol)); return mat3(u,normalize(cross(u,w)),w); }

struct Light {
  vec3 dir, col, amb;    // direction, color
};
Light amb = Light(vec3(0,1,0), vec3(1.0), vec3(0.02));

//----- ray trace caluclations
Ray rayScreen(in vec2 p, in Camera c) { return ray(c.pos, normalize(cameraMatrix(c) * vec3(p.xy, -c.fcs))); }
Ray rayReflect(in Hit h, in float rl) { return ray(h.pos+h.nml*.01, reflect(h.ray.dir, h.nml), h.ray.col*rl, h.ray.rr, h.ray.sgn); }
Ray rayRefract(in Hit h, in float rr) {
  vec3 r = refract(h.ray.dir, h.nml, h.ray.rr/rr);
  if (length(r)<.01) return rayReflect(h, 1.);
  return ray(h.pos-h.nml*.01, r, h.ray.col*h.srf.mat.tc, rr, -h.ray.sgn);
}

vec2 uv;
float tick, pick;
vec4  gamma(vec4 c){return vec4(pow(c.rgb,vec3(1./2.2)),c.a);}
vec3  hsv(float h,float s,float v){return((clamp(abs(fract(h+vec3(0,2,1)/3.)*6.-3.)-1.,0.,1.)-1.)*s+1.)*v;}
float fresnel(float r, float dp) {return r+(1.-r)*pow(1.-abs(dp),5.);}
vec2  circle(float a){return vec2(cos(a),sin(a));}
mat3  euler(float h, float p, float r){float a=sin(h),b=sin(p),c=sin(r),d=cos(h),e=cos(p),f=cos(r);return mat3(f*e,c*e,-b,f*b*a-c*d,f*d+c*b*a,e*a,c*a+f*b*d,c*b*d-f*a,e*d);}
float dfPln(vec3 p, vec3 n, float z){return dot(p,n)+z;}
float dfRoom(vec3 p, vec3 s) {vec3 v=s-abs(p); return min(v.x, min(v.y, v.z));}
float dfBox(vec3 p, vec3 b, float r){return length(max(abs(p)-b,0.))-r;}
vec3  doRep(vec3 p, vec3 r){ return mod(p+r*.5,r)-r*.5; }
float dfp2l(vec3 p, vec3 d, vec3 c) { return length(dot(c-p,d)*d+p-c); }
float checker(vec3 u, vec3 s){return mod(floor(u.x/s.x)+floor(u.y/s.y)+floor(u.z/s.z),2.);}

vec3 lightpos[3];
vec3 lightcol[3];

Surface map(in vec3 p) {
    vec3 c = mix(vec3(0.1), vec3(0.5), checker(p, vec3(6)));
    Surface s = Surface(dfRoom(p, vec3(37.1)), mirror(c,0.5));
    vec3 q = doRep(p, vec3(30));
    return  near(s, Surface(dfBox(q*euler(pick/16.,pick/7.,0.), vec3(3.5), .8), glass(hsv(tick/64.,.4,.9),1.6)));
}

vec3 background(in Ray ray) {
    return BG;
}

//----- Lighting
vec3 emittance(in Ray ray, in Light lit) {
    return pow(dfp2l(ray.org, ray.dir, lit.dir)*40., -1.5) * lit.col;
}

vec3 diffusion(in vec3 nml, in Light lit) {
    return max(dot(nml, lit.dir) * lit.col, 0.);
}

vec4 shading(in vec3 pos, in vec3 dir) {
  vec3 color;
  float shade = 1.0, len = SS_MIN_MARCHING;
  for (int i=SS_MAX_TRACE_STEP; i!=0; --i) {
    Surface s = map(pos + dir*len);
    color = s.mat.tc;
    shade = min(shade, SS_SHARPNESS * s.d / len);
    len += max(s.d, SS_MIN_MARCHING);
    if (s.d<TRACE_PRECISION || len>SS_MAX_TRACE_DIST) break;
  }
  shade = clamp(shade, 0., 1.);
  return vec4(pow((1.-shade), CS_SHARPNESS) * color * CS_STRENGTH, shade);
}

vec4 occlusion(in vec3 pos, in vec3 nml) {
  vec3 color;
  float occl;
  for (int i=GI_TRACE_STEP; i!=0; --i) {
    float hr = .01 + float(i) * GI_LENGTH / 4.;
    Surface s = map(nml * hr + pos);
    occl += (hr - s.d);
    color += s.mat.kd * (hr - s.d);
  }
  return vec4(color * GI_STRENGTH / GI_LENGTH, clamp(1.-occl * AO_STRENGTH / GI_LENGTH, 0., 1.));
}

vec3 lighting(in Hit h, in Light lit) {
  if (h.ray.len > MAX_TRACE_DIST) return background(h.ray);
  vec4 occl = occlusion(h.pos, h.nml);
  vec4 shad = shading(h.pos, lit.dir);
  vec3 lin = (diffusion(h.nml, lit) * shad.w + shad.rgb) * occl.w + occl.rgb + lit.amb;
  return  h.srf.mat.kd * lin;
}

//----- Ray trace
vec3 _normal(in vec3 p){
  float d = map(p).d;
  return normalize(vec3(map(p+V.yxx).d - d, map(p+V.xyx).d - d, map(p+V.xxy).d - d));
}

Hit trace(in Ray r) {
  Surface s;
  for(int i=0; i<MAX_TRACE_STEP; i++) {
    s = map(_pos(r));
    s.d *= r.sgn;
    r.len += s.d * FUDGE_FACTOR;
    r.stp = float(i);
    if (s.d < TRACE_PRECISION) break;
    if (r.len > MAX_TRACE_DIST) return nohit(r);
  }
  vec3 p = _pos(r);
  float interior = .5-r.sgn*.5;
  s.mat.rr = mix(s.mat.rr, 1., interior);
  s.mat.tc = max(s.mat.tc, interior);
  return Hit(p, _normal(p)*r.sgn, r, s, (length(s.mat.tc)>.01), (s.mat.rl>.01));
}

vec3 _difColor(inout Hit h, in Light l) {
  if (length(h.srf.mat.kd) < .01) return vec3(0);
  vec3 col = lighting(h, l) * h.ray.col;
  h.ray.col *= 1. - h.srf.mat.kd;
  return col;
}

Ray _nextRay(Hit h) {
  if (h.isTransparent) return rayRefract(h, h.srf.mat.rr);
  return rayReflect(h, fresnel(h.srf.mat.rl, dot(h.ray.dir, h.nml)));
}

vec4 render(in Ray ray) {
  vec3 col=vec3(0), c;
  Hit h0, h1;
  float l0, rl;
  h0 = trace(ray);
  l0 = h0.ray.len;

  col += _difColor(h0, amb);
  if (!h0.isReflect) return vec4(col, l0);
  rl = fresnel(h0.srf.mat.rl, dot(h0.ray.dir, h0.nml));
  h1 = trace(rayReflect(h0, rl));
  col += _difColor(h1, amb);
  h0.ray.col *= 1. - rl;
  if (!h0.isTransparent) h0 = h1;
  for (int i=RAY_TRACE_COUNT; i!=0; --i) {
    if (!h0.isReflect) return vec4(col, l0);
    h0 = trace(_nextRay(h0));
    col += _difColor(h0, amb);
  }
  c = h0.ray.col;
  if (length(c) >= .5) col += background(h0.ray) * c * c;

  return vec4(col, l0);
}

vec4 entryPoint() {
    uv = (gl_FragCoord.xy * 2.-resolution) / resolution.y;
    tick = time * BPM / 60.;
    pick = tick * PI.z;

    lightpos[0] = vec3(cos(pick/11.)*10.+5., cos(pick/16.)*10., sin(pick/8.)*10.);
    lightpos[1] = vec3(cos(pick/8.)*8.+5., cos(pick/6.)*8., sin(pick/7.)*8.);
    lightpos[2] = vec3(cos(pick/4.)*12.+5., cos(pick/11.)*12., sin(pick/9.)*12.);
    lightcol[0] = vec3(5,10,50);
    lightcol[1] = vec3(5,30,5);
    lightcol[2] = vec3(40,8,8);

    Camera camera = Camera(vec3(sin(pick/14.)*5.+3., circle(pick/32.)*20.), vec3(0,0,0), vec3(1,0,0), 1.732);
    Ray ray = rayScreen(uv, camera);

    return gamma(render(ray));
}

void main() {
    glFragColor = entryPoint();
}
