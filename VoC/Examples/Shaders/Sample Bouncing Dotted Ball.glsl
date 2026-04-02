#version 420

// original https://www.shadertoy.com/view/sdBXWt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Licence CC0: Bouncing dotted ball
//  I wanted to recreate the classic dotted balls so common during the Amiga era
//  Then I messed around a bit more.

#define PI            3.141592654
#define TAU           (2.0*PI)
#define ROT(a)        mat2(cos(a), sin(a), -sin(a), cos(a))
#define PCOS(x)       (0.5 + 0.5*cos(x))
#define DOT2(x)       dot(x, x)
#define TIME          time
#define RESOLUTION    resolution

// https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

const float beat          = 2.0*60.0/125.0;
const vec3  grid_color    = HSV2RGB(vec3(0.6, 0.6, 1.0)); 
const vec3  plate_color   = HSV2RGB(vec3(0.0, 0.0, 0.125)); 
const vec3  plane_color   = HSV2RGB(vec3(0.7, 0.125, 1.0/32.0)); 
const vec3  light0_color  = 16.0*HSV2RGB(vec3(0.6, 0.5, 1.0)); 
const vec3  light1_color  = 8.0*HSV2RGB(vec3(0.9, 0.25, 1.0)); 
const vec3  sky0_color    = HSV2RGB(vec3(0.0, 0.65, 0.95)); 
const vec3  sky1_color    = HSV2RGB(vec3(0.6, 0.5, 0.5)); 
const vec3  light0_pos    = vec3(3.0, 4.0, 4.0);
const vec3  light1_pos    = vec3(-3.0, 2.0, -8.0);
const vec3  light0_dir    = normalize(light0_pos);
const vec3  light1_dir    = normalize(light1_pos);
const vec4  planet_sph    = vec4(50.0*normalize(light1_dir+vec3(0.025, -0.025, 0.0)), 10.0);
const float truchet_lw    = 0.05;
const mat2[] truchet_rots = mat2[](ROT(0.0*PI/2.0), ROT(1.00*PI/2.0), ROT(2.0*PI/2.0), ROT(3.0*PI/2.0));

const float period        = 18.0;

// IQ's soft minimum: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp( 0.5+0.7*(b-a)/k, 0.0, 1.0);
  return mix(b,a,h) - k*h*(1.0-h);
}

// From: http://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// IQ's ray plane intersect: https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
float rayPlane(vec3 ro, vec3 rd, vec4 p) {
  return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

// IQ's ray sphere intersect: https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
vec2 raySphere(vec3 ro, vec3 rd, vec4 sph) {
  vec3 oc = ro - sph.xyz;
  float b = dot( oc, rd );
  float c = dot( oc, oc ) - sph.w*sph.w;
  float h = b*b - c;
  if (h < 0.0) return vec2(-1.0);
  h = sqrt(h);
  return vec2(-b - h, -b + h);
}

vec3 toSpherical(vec3 p) {
  float r   = length(p);
  float t   = acos(p.z/r);
  float ph  = atan(p.y, p.x);
  return vec3(r, t, ph);
}

vec3 toRect(vec3 p) {
  return p.x*vec3(cos(p.z)*sin(p.y), sin(p.z)*sin(p.y), cos(p.y));
}

float tanh_approx(float x) {
//  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

float hash(vec2 co) {
  return fract(sin(dot(co, vec2(12.9898,58.233))) * 13758.5453);
}

float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

float grid(vec2 p, float f, float mf) {
  const float steps = 20.0;
  vec2 gz = vec2(PI/(steps*mf), PI/steps);
  vec2  n = mod2(p, gz);
  p.y     *= f;
  float d = min(abs(p.x), abs(p.y))-0.00125;
  return d;
}

float dots(vec2 p, float f) {
  const vec2 gz = vec2(PI/128.0);
  vec2  n = mod2(p, gz);
  p.y     *= f;
  float d = length(p)-0.00125;
  float r = hash(n+124.0);
  
  return d;
}

float plates(vec2 p, float f, float mf) {
  vec2 gz = vec2(PI/(64.0*mf), PI/64.0);
  vec2  n = mod2(p, gz);
  p.y     *= f;
  float r = hash(n+124.0);
  
  if (-1.5*sin(TAU*TIME/period)+r < f) {
    return 1E6;
  } else {
    return 0.0;
  }
}

float truchet_cell0(vec2 p, float h) {
  float d0  = circle(p-vec2(0.5), 0.5);
  float d1  = circle(p+vec2(0.5), 0.5);

  float d = 1E6;
  d = min(d, d0);
  d = min(d, d1);
  return d;
}

float truchet_cell1(vec2 p, float h) {
  float d0  = abs(p.x);
  float d1  = abs(p.y);
  float d2  = circle(p, mix(0.2, 0.4, h));

  float d = 1E6;
  d = min(d, d0);
  d = min(d, d1);
  d = min(d, d2);
  return d;
}

float truchet(vec2 p, float f, float sections) {
  float z = TAU/sections; 
  
  vec2 hp = p/z;
  hp.x -= sections/4.0;
  vec2 lp = hp;
  lp.x = abs(lp.x);

  
  vec2 hn = mod2(hp, vec2(1.0));
  float r = hash(hn);

  hp *= truchet_rots[int(r*4.0)];
  float rr = fract(r*131.0);
  float cd0 = truchet_cell0(hp, rr);
  float cd1 = truchet_cell1(hp, rr);

  float d = mix(cd0, cd1, float(fract(r*113.0) > 0.5));

  float ld = lp.x-sections/6.0; 

  d = max(d, ld);
  d = min(d, abs(ld));
  d = abs(d) - truchet_lw;

  return d*z;
}

float truchet(vec2 p, float f) {
  float n = floor((TIME-2.0)/period);
  float r = hash(0.1*n+100.0);
  float sections = 11.0+2.0*floor(15.0*r*r);
  float d = truchet(p, f, sections);
  return d;
}

float bounce() {
  float tm = TIME/beat;
  float t = fract(tm*1.0)-0.5;
  return 0.25 - t*t;
}

void lighting(vec3 pos, vec3 nor, vec3 ref, out vec3 ld0, out vec3 dif0, out vec3 ld1, out vec3 dif1) {
  float ll0 = 0.05*DOT2(light0_pos-pos);
  float ll1 = 0.05*DOT2(light1_pos-pos);
  ld0       = normalize(light0_pos-pos);
  ld1       = normalize(light1_pos-pos);
  dif0      = light0_color*max(dot(nor, ld0), 0.0)/ll0;
  dif1      = light1_color*max(dot(nor, ld1), 0.0)/ll1;
}

vec3 renderBackground(vec3 ro, vec3 rd, vec3 nrd, vec4 sph) {
  vec3 sky  = smoothstep(1.0, 0.0, rd.y)*sky1_color+smoothstep(0.5, 0.0, rd.y)*sky0_color;

  vec2 pi = raySphere(ro, rd, planet_sph);

  float lf1 = 1.0;
  if (pi.x > 0.0) {
    vec3 ppos = ro+rd*pi.x;
    float t = 1.0-tanh_approx(1.5*(pi.y - pi.x)/planet_sph.w);
    sky *= mix(0.5, 1.0, t);
    lf1 = t;
  }

  sky += pow(max(dot(rd, light0_dir), 0.0), 800.0)*light0_color; 
  sky += lf1*pow(max(dot(rd, light1_dir), 0.0), 150.0)*light1_color; 

  if(rd.y > 0.0) return sky;

  // As suggested by elenzil in the comments
  float py  = 1.0 + 0.2 * smoothstep(-0.05, 0.1, bounce());
  float t   = rayPlane(ro, rd, vec4(vec3(0.0, py, 0.0), 0.5));

  vec3 pos  = ro + t*rd;
  vec3 npos = ro + t*nrd;
  float aa  = length(npos-pos);

  vec3 nor  = vec3(0.0, 1.0, 0.0);
  vec3 ref  = reflect(rd, nor); 
  vec3 nref = reflect(nrd, nor); 

  vec3 ld0 ;
  vec3 ld1 ;
  vec3 dif0; 
  vec3 dif1;
  lighting(pos, nor, ref, ld0, dif0, ld1, dif1);

  vec2 si0 = raySphere(pos, ld0, sph);

  vec2 pp = pos.xz;
  vec2 op = pp;
  pp += TIME*0.513;
  
  vec2 np = mod2(pp, vec2(0.6));
  
  float sha0 = si0.x < 0.0 ? 1.0 : (1.0-1.0*tanh_approx((si0.y-si0.x)*2.5/(0.5+.5*si0.x)));
  dif0 *= sha0;
  
  vec3 col = vec3(0.0);

  float ll = 2.0*DOT2(op);
  
  float d = pmin(abs(pp.x), abs(pp.y), 0.05);

  float gm = PCOS(-TAU/beat*TIME+0.25*TAU*length(op));
  col += mix(vec3(0.75), 2.0*vec3(3.5, 2.0, 1.25), gm)*exp(-mix(400.0, 100.0, gm)*max(d-0.00125, 0.0));
  col /= (1.0+ll);

  col += plane_color*(dif0+dif1); 

  
  return mix(sky, col, tanh_approx(500.0/(1.0 + DOT2(pos))));
}

vec3 renderBall(vec3 ro, vec3 rd, vec3 nrd, vec4 sph, vec2 t2) {
  vec3 pos  = ro + t2.x*rd;
  vec3 npos = ro + t2.x*nrd;
  float aa  = length(npos-pos);

  vec3 sp   = pos - sph.xyz;
  vec3 nor  = normalize(sp);
  vec3 ref  =reflect(rd, nor); 
  vec3 nref =reflect(nrd, nor); 
  
  vec3 ld0 ;
  vec3 ld1 ;
  vec3 dif0; 
  vec3 dif1;
  lighting(pos, nor, ref, ld0, dif0, ld1, dif1);
  
  sp.yz    *= ROT(TIME*sqrt(0.5));
  sp.xy    *= ROT(TIME*1.234);
  vec3 ssp = toSpherical(sp.zxy);

  vec2  pp = ssp.yz;
  float f  = sin(pp.x); 

  float lf2 = -ceil(log(f)/log(2.0));
  float mf = pow(2.0, lf2);

  float gd = grid(pp, f, mf);
  float dd = dots(pp, f);
  float pd = plates(pp, f, mf);
  float td = truchet(pp, f);

  vec3 rcol= renderBackground(ro, ref, nrd, sph);
  
  vec3 col = vec3(0.0);
  col = mix(col, vec3(1.0), smoothstep(-aa, aa, -dd));
  vec3 gcol = vec3(0.0); 
  gcol -= 0.5*vec3(1.0, 2.0, 2.0)*exp(-100.0*max(td+0.01, 0.0));
  gcol = mix(gcol, vec3(0.1, 0.09, 0.125), smoothstep(-aa, aa, -(td+0.005)));
  gcol += 8.0*vec3(2.0, 1.0, 1.0)*exp(-900.0*abs(td-0.00125));
  gcol = mix(gcol, 0.5*(plate_color*(dif0+dif1)), vec3(pd > 0.0));
  col += clamp(gcol, -1.0, 1.0);
  col = mix(col, grid_color, smoothstep(-aa, aa, -gd));
  
  float b = smoothstep(0.15, 0.0, dot(nor, -rd));
  col *= tanh_approx(1.0*abs(t2.y-t2.x)/sph.w);
  
  return col+rcol*(pd <= 0.0 ? 0.275 : 0.1);
}

vec3 effect(vec2 p, vec2 q) { 
  vec3 ro = 0.65*vec3(2.0, 0, 0.2)+vec3(0.0, 0.5, 0.0);
  ro.xz *= ROT(TIME*0.312);
  vec3 la = vec3(0.0,0.125, 0.0); 

  vec2 np = p + vec2(4.0/RESOLUTION.y); 

  vec3 ww = normalize(la - ro);
  vec3 uu = normalize(cross(vec3(0.0,1.0,0.0), ww));
  vec3 vv = normalize(cross(ww,uu));
  float rdd = 2.0;
  vec3 rd = normalize(p.x*uu + p.y*vv + rdd*ww);
  vec3 nrd= normalize(np.x*uu + np.y*vv + rdd*ww);
  
  vec4 sph= vec4(vec3(0.0, bounce(), 0.0), 0.5);
  
  vec2 si = raySphere(ro, rd, sph);

  if (si.x >= 0.0) {
    return renderBall(ro, rd, nrd, sph, si);
  } else {
    return renderBackground(ro, rd, nrd, sph);
  }
}

vec3 postProcess(vec3 col, vec2 q) {
  col = clamp(col, 0.0, 1.0);
  col = pow(col, vec3(1.0/2.2));
  col = col*0.6+0.4*col*col*(3.0-2.0*col);
  col = mix(col, vec3(dot(col, vec3(0.33))), -0.4);
  col *=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

void main(void) {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1.0 + 2.0*q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = effect(p, q);

  float fi = smoothstep(0.0, 5.0, TIME);
  col = mix(vec3(0.0), col, fi);

  col = postProcess(col, q);
  
  glFragColor = vec4(col, 1.0);
}

