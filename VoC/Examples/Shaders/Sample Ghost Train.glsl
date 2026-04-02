#version 420

// original https://www.shadertoy.com/view/msKGzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// CC0: Ghost train
//  Applying the "light model" I used for the necropolis shader
//  to the "amazing surface" borrowed from https://www.shadertoy.com/view/XsBXWt
//  turned out good enough to share.

#define TIME                time
#define RESOLUTION          resolution

#define PI                  3.141592654
#define TAU                 (2.0*PI)
#define TOLERANCE           0.0001
#define MAX_RAY_LENGTH      12.0
#define MAX_RAY_MARCHES     60
#define MAX_SHADOW_MARCHES  24
#define NORM_OFF            0.001
#define ROT(a)              mat2(cos(a), sin(a), -sin(a), cos(a))
#define REPS                4

// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
const vec4 hsv2rgb_K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 hsv2rgb(vec3 c) {
  vec3 p = abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www);
  return c.z * mix(hsv2rgb_K.xxx, clamp(p - hsv2rgb_K.xxx, 0.0, 1.0), c.y);
}
// License: WTFPL, author: sam hocevar, found: https://stackoverflow.com/a/17897228/418488
//  Macro version of above to enable compile-time constants
#define HSV2RGB(c)  (c.z * mix(hsv2rgb_K.xxx, clamp(abs(fract(c.xxx + hsv2rgb_K.xyz) * 6.0 - hsv2rgb_K.www) - hsv2rgb_K.xxx, 0.0, 1.0), c.y))

const float hoff= 0.35;
const vec3 ecol = HSV2RGB(vec3(hoff+0.65, 0.9, 0.025));
const vec3 bcol = HSV2RGB(vec3(hoff+0.45, 0.85, 0.051));
const vec3 dcol = HSV2RGB(vec3(hoff+0.58, 0.666, 0.666));
const vec3 scol = HSV2RGB(vec3(hoff+0.58, 0.5  , 2.0));
const vec3 gcol = HSV2RGB(vec3(hoff+0.35, 0.36 , 5.0));
const vec3 skyCol = (0.125*gcol+dcol)*0.5; 
const vec2 csize  = vec2(4.5);

const vec3 lightDir = normalize(vec3(-1, 1.0, 0.25));

float g_near = 0.0;

// License: Unknown, author: Unknown, found: don't remember
float hash(float co) {
  return fract(sin(co*12.9898) * 13758.5453);
}

// License: Unknown, author: nmz (twitter: @stormoid), found: https://www.shadertoy.com/view/NdfyRM
vec3 sRGB(vec3 t) {
  return mix(1.055*pow(t, vec3(1./2.4)) - 0.055, 12.92*t, step(t, vec3(0.0031308)));
}

// License: Unknown, author: Matt Taylor (https://github.com/64), found: https://64.github.io/tonemapping/
vec3 aces_approx(vec3 v) {
  v = max(v, 0.0);
  v *= 0.6f;
  float a = 2.51f;
  float b = 0.03f;
  float c = 2.43f;
  float d = 0.59f;
  float e = 0.14f;
  return clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0f, 1.0f);
}

// License: Unknown, author: Claude Brezinski, found: https://mathr.co.uk/blog/2017-09-06_approximating_hyperbolic_tangent.html
float tanh_approx(float x) {
  //  Found this somewhere on the interwebs
  //  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}
// License: MIT OR CC-BY-NC-4.0, author: mercury, found: https://mercury.sexy/hg_sdf/
vec2 mod2(inout vec2 p, vec2 size) {
  vec2 c = floor((p + size*0.5)/size);
  p = mod(p + size*0.5,size) - size*0.5;
  return c;
}

// License: MIT, author: Inigo Quilez, found: https://www.iquilezles.org/www/articles/smin/smin.htm
float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/articles/distfunctions/
float capsule(vec3 p, vec2 t) {
  float h = t.x;
  float r = t.y;
  p.y -= clamp( p.y, 0.0, h );
  return length( p ) - r;
}

// License: MIT, author: Inigo Quilez, found: https://iquilezles.org/articles/distfunctions/
float torus(vec3 p, vec2 t) {
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

// "Amazing Surface" fractal
//  "borrowed" from https://www.shadertoy.com/view/XsBXWt
vec4 formula(vec4 p) {
  p.xz = abs(p.xz+1.)-abs(p.xz-1.)-p.xz;
  p.y-=.25;
  const mat2 r = ROT(radians(35.)); 
  p.xy*=r;
  p=p*2./clamp(dot(p.xyz,p.xyz),.2,1.-0.125);
  return p;
}

float surface(vec3 pos) {
  pos.z = abs(pos.z);
  pos.z = pos.z-1.0;
  mod1(pos.x, 6.0);
  pos.xz = pos.zx;
  
  float hid=0.;
  vec3 tpos=pos;
  vec4 p=vec4(tpos,1.);

  for (int i=0; i<REPS; i++) {
    p=formula(p);
  }

  float fr=(length(max(vec2(0.),p.yz-1.5))-1.)/p.w;

  float ro=max(abs(pos.x+1.)-.3,pos.y-.35);
  ro=max(ro,-max(abs(pos.x+1.)-.1,pos.y-.5));
  pos.z=abs(.25-mod(pos.z,.5));
  ro=max(ro,-max(abs(pos.z)-.2,pos.y-.3));
  ro=max(ro,-max(abs(pos.z)-.01,-pos.y+.32));

  float d=min(fr,ro);

  return d;
}

float train(vec3 p) {
  const float rw = 0.25;
  const float mw = 60.0;
 
  vec3 p3 = p;
  p3.z = abs(p3.z);
  p3.z -= 0.3;
  p3.y -= 0.5;
  float d3 = length(p3.zy)-0.05; 
 
  p.x -= TIME*8.0;
  float nx = mod1(p.x, mw);
  p.x += 0.75*mw*(hash(nx)-0.5);
  vec3 p4 = p;
  p4.x -= 2.4;
  p4.y -= 0.9;
  float d4 = length(p4.zy)-0.2;
  float d5 = length(p4-vec3(-0.6,0.0,0.0))-0.1;
  float d2 = max(p.x-(1.0), -p.x+rw);
  p = p.zxy;
  p.z -= 0.7;
  vec3 p0 = p;
  vec3 p1 = p;
  mod1(p1.y, rw);
  float d1 = torus(p1, 0.5*vec2(1.0, 0.025));
  float d0 = capsule(p0, vec2(1.5, 0.5));
  d1 = max(d1, d2);
  float d = d0;
  d = pmax(d, -(d1-0.05), 0.05);
  d = max(d, -d3);
  d = min(d, d1);
  d = pmax(d, -d4, 0.05);
  d = min(d, d5);
  g_near = min(g_near, min(d1, d5));
  return d;
}

float df(vec3 p) {
  float d0 = surface(p);
  float d1 = train(p);
  float d = d0;
  d = min(d, d1);
  return d;
}

vec3 normal(vec3 pos) {
  vec2  eps = vec2(NORM_OFF,0.0);
  vec3 nor;
  nor.x = df(pos+eps.xyy) - df(pos-eps.xyy);
  nor.y = df(pos+eps.yxy) - df(pos-eps.yxy);
  nor.z = df(pos+eps.yyx) - df(pos-eps.yyx);
  return normalize(nor);
}

float rayMarch(vec3 ro, vec3 rd, float initt, out int iter) {
  float t = initt;
  const float tol = TOLERANCE;
  vec2 dti = vec2(1e10,0.0);
  int i = 0;
  for (i = 0; i < MAX_RAY_MARCHES; ++i) {
    float d = df(ro + rd*t);
    if (d<dti.x) { dti=vec2(d,t); }
    if (d < TOLERANCE || t > MAX_RAY_LENGTH) {
      break;
    }
    t += d;
  }
  if(i==MAX_RAY_MARCHES) { t=dti.y; };
  iter = i;
  return t;
}

float softShadow(vec3 ps, vec3 ld, float mint, float k) {
  float res = 1.0;
  float t = mint*2.0;
  for (int i=0; i<MAX_SHADOW_MARCHES; ++i) {
    vec3 p = ps + ld*t;
    float d = df(p);
    res = min(res, k*d/t);
    if (res < TOLERANCE) break;
    
    t += max(d, mint);
  }
  return clamp(res, 0.0, 1.0);
}

vec3 render(vec3 ro, vec3 rd) {
  int iter;
  float initt = -(ro.y-1.5)/rd.y;
  initt = max(initt, 0.0);
  float bott  = -(ro.y-0.5)/rd.y;
  bott = max(bott, 0.0);
  g_near = 1E4;
  float t = rayMarch(ro, rd, initt, iter);
  float near = g_near;
  vec3 col = skyCol;
  vec3 bp = ro+rd*bott;
  vec3 p = ro+rd*t;
  vec3 n = normal(p);
  vec3 r = reflect(rd, n);
  float sd = softShadow(p, lightDir, 0.025, 4.0);
  float dif = max(dot(lightDir, n), 0.0);
  dif *= dif;
  dif *= dif;
  float spe = pow(max(dot(lightDir, r), 0.0), 10.0);
  float ii = float(iter)/float(MAX_RAY_MARCHES);
  if (t < MAX_RAY_LENGTH) {
    col = dcol;
    col += gcol*tanh_approx(1.0*ii*ii);
    col *= mix(0.05, 1.0, dif*sd);
    col += spe*sd*scol;
  }
 
  float gd = abs(abs(bp.z) - .3);
  gd -= mix(0.0025, 0.01, 0.5+0.5*(sin(13.0*bp.x+2.0*TIME)*sin(6.0*bp.x+3.0*TIME)));

  float ef = 1.0/(max(near*near, 0.00025*bott+0.000125));
  ef *= mix(0.25, 1.0, smoothstep(0.125, 0.33, ii));
  col += ecol*ef;  
  col += bcol/max(gd+.5*max(bott-t, 0.001), 0.0002*bott*bott);

  float c = tanh_approx(p.y*p.y*5.0);
  col = mix(skyCol, col, exp(-mix(0.25, 0.125, c)*max(t-initt, 0.)-0.25*max(t-5.0, 0.)));
  return col;
}

vec3 effect(vec2 p, vec2 pp) {
  vec3 ro = vec3(3.0, 2., 0.0);
  ro.x -= 0.3*TIME;
  const vec3 up = normalize(vec3(0.0, 1.0, 0.0));
  const vec3 ww = normalize(vec3(-3.0, -2.5, 0.0));
  vec3 uu = normalize(cross(up, ww ));
  vec3 vv = (cross(ww,uu));
  const float fov = tan(TAU/6.);
  vec3 rd = normalize(-p.x*uu + p.y*vv + fov*ww);

  float ll = length(pp);
  vec3 col = render(ro, rd);
  col -= 0.1*vec3(0.0, 1.0, 2.0).zyx*(ll+0.3);
  col *= smoothstep(1.5, 1.0-0.5, ll);
  col = aces_approx(col); 
  col = sRGB(col);
  return col;
}

void main(void) {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  vec2 pp = p;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = effect(p,pp);
  glFragColor = vec4(col, 1.0);
}
