#version 420

// original https://www.shadertoy.com/view/ss2Szm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License CC0: Sunday threads
// Result after a bit of random coding on sunday afternoon

#define PI              3.141592654
#define TAU             (2.0*PI)
#define TIME            time
#define RESOLUTION      resolution
#define ROT(a)          mat2(cos(a), sin(a), -sin(a), cos(a))

#define TOLERANCE       0.0001
#define MAX_RAY_LENGTH  8.0
#define MAX_RAY_MARCHES 80
#define NORM_OFF        0.001

#define PATHA vec2(0.1147, 0.2093)
#define PATHB vec2(13.0, 3.0)

const mat2 rot0             = ROT(0.00);
const vec3 std_gamma        = vec3(2.2);

mat2 g_rot  = rot0;
int g_hit   = 0;

// From https://www.shadertoy.com/view/XdcfR8
vec3 cam_path(float z) {
  return vec3(sin(z*PATHA)*PATHB, z);
}

vec3 dcam_path(float z) {
  return vec3(PATHA*PATHB*cos(PATHA*z), 1.0);
}

vec3 ddcam_path(float z) {
  return vec3(-PATHA*PATHA*PATHB*sin(PATHA*z), 0.0);
}

float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0 );
  return mix( b, a, h ) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

float tanh_approx(float x) {
//  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// From: http://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// From: https://stackoverflow.com/a/17897228/418488
vec3 hsv2rgb(vec3 c) {
  const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 postProcess(vec3 col, vec2 q) {
  col = clamp(col, 0.0, 1.0);
  col = pow(col, 1.0/std_gamma);
  col = col*0.6+0.4*col*col*(3.0-2.0*col);
  col = mix(col, vec3(dot(col, vec3(0.33))), -0.4);
  col *=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

float df(vec3 p) {
  vec3 cam = cam_path(p.z);
  vec3 dcam = normalize(dcam_path(p.z));
  p.xy -= cam.xy;
  p -= dcam*dot(vec3(p.xy, 0), dcam)*0.5*vec3(1,1,-1);

  float dc = length(p.xy) - 0.45;
  vec3 pp = p;
  mat2 rr = ROT(p.z*0.5);
  pp.xy   *= rr;
  rr      *= g_rot;
  
  float d = 1E6;

  const float ss = 0.45;
  const float oo = 0.125;
  float s = 1.0;

  vec2 np = mod2(pp.xy, vec2(0.75));
  for (int i = 0; i < 3; ++i) {
    pp = abs(pp);
    pp -= oo*s;
    float dp = length(pp.xy) - 0.75*ss*oo*s;
    if (dp < d) {
      d = dp;
      g_hit = i;
    }
    s *= ss; 
    pp.xy *= rr;
  }
  return max(d, -dc);
}

float rayMarch(vec3 ro, vec3 rd, out int iter) {
  float t = 0.0;
  int i = 0;
  for (i = 0; i < MAX_RAY_MARCHES; i++) {
    float d = df(ro + rd*t);
    if (d < TOLERANCE || t > MAX_RAY_LENGTH) break;
    t += d;
  }
  iter = i;
  return t;
}

vec3 normal(vec3 pos) {
  vec2  eps = vec2(NORM_OFF,0.0);
  vec3 nor;
  nor.x = df(pos+eps.xyy) - df(pos-eps.xyy);
  nor.y = df(pos+eps.yxy) - df(pos-eps.yxy);
  nor.z = df(pos+eps.yyx) - df(pos-eps.yyx);
  return normalize(nor);
}

float softShadow(vec3 pos, vec3 ld, float ll, float mint, float k) {
  const float minShadow = 0.25;
  float res = 1.0;
  float t = mint;
  for (int i=0; i<24; i++) {
    float d = df(pos + ld*t);
    res = min(res, k*d/t);
    if (ll <= t) break;
    if(res <= minShadow) break;
    t += max(mint*0.2, d);
  }
  return clamp(res,minShadow,1.0);
}

vec3 render(vec3 ro, vec3 rd) {
  vec3 lightPos = cam_path(ro.z+0.75);

  float alpha   = 0.05*TIME;
  vec3 tnor     = normalize(vec3(1.0, 0.0, 0.0));
  
  vec3 skyCol = vec3(0.0);

  int iter    = 0;
  g_hit       = 0;
  float t     = rayMarch(ro, rd, iter);
  int hit     = g_hit;

  float ifade = 1.0-tanh_approx(2.0*float(iter)/float(MAX_RAY_MARCHES));

  vec3 pos    = ro + t*rd;    
  
  if (t >= MAX_RAY_LENGTH) {
    return skyCol*ifade;
  }

  float h    = 0.4*smoothstep(-0.1, 0.1, sin(2.0*pos.z+0.5*float(hit)));
  h          += float(hit)*-0.125;
  vec3 hsv   = (vec3(h+0.25*t, 1.0-ifade, 1.0));
  vec3 color = hsv2rgb(hsv);

  vec3 nor  = normal(pos);

  vec3 lv   = lightPos - pos;
  float ll2 = dot(lv, lv);
  float ll  = sqrt(ll2);
  vec3 ld   = lv / ll;
  float sha = softShadow(pos, ld, ll, 0.01, 64.0);

  float dm  = min(1.0, 40.0/ll2);
  float dif = max(dot(nor,ld),0.0)*dm;
  float spe = pow(max(dot(reflect(-ld, nor), -rd), 0.), 10.);
  float l   = dif*sha;

  float lin = mix(0.2, 1.0, l);

  vec3 col = lin*color + spe*sha;

  float f = exp(-10.0*(max(t-3.0, 0.0) / MAX_RAY_LENGTH));
    
  return (mix(skyCol, col , f))*ifade;
}

vec3 effect(vec2 p, vec2 q) {
  float z   = TIME;
  g_rot     = ROT(0.25*TIME); 
  vec3 cam  = cam_path(z);
  vec3 dcam = dcam_path(z);
  vec3 ddcam= ddcam_path(z);
  
  vec3 ro = cam;
  vec3 ww = normalize(dcam);
  vec3 uu = normalize(cross(vec3(0.0,1.0,0.0)+ddcam*2.0, ww ));
  vec3 vv = normalize(cross(ww,uu));
  vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );

  return render(ro, rd);
}

void main(void) {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = effect(p, q);

  col = postProcess(col, q);

  glFragColor = vec4(col, 1.0);
}

