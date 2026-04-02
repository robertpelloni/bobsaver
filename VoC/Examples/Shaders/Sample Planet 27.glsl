#version 420

// original https://www.shadertoy.com/view/ssf3R2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License CC0: Monochrome gas giant
//  I had the idea of creating a monochrome flat gas giant
//  It didn't come out as intended but I liked the result anyway

#define PI              3.141592654
#define TAU             (2.0*PI)
#define TIME            time
#define TTIME           (TAU*TIME)
#define RESOLUTION      resolution
#define ROT(a)          mat2(cos(a), sin(a), -sin(a), cos(a))
#define PSIN(a)         (0.5+0.5*sin(a))
#define L2(x)           dot(x, x)
#define SCA(a)          vec2(sin(a), cos(a))

const vec3  std_gamma = vec3(2.2);
const vec2  miss      = vec2(1E6);
const vec4  sphere    = vec4(vec3(0.0), 0.4);
const vec4  plane     = vec4(normalize(vec3(0.0, 1.0, 0.0)), 0.0);

float tanh_approx(float x) {
//  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

// IQ's ray sphere intersection
vec2 raySphere(vec3 ro, vec3 rd, vec4 sph) {
  vec3 ce  = sph.xyz;
  float ra = sph.w;
  vec3 oc = ro - ce;
  float b = dot( oc, rd );
  float c = dot( oc, oc ) - ra*ra;
  float h = b*b - c;
  if( h<0.0 ) return miss; // no intersection
  h = sqrt(h);
  return vec2( -b-h, -b+h );
}

// IQ's ray plane  intersection
float rayPlane(vec3 ro, vec3 rd, vec4 p) {
  return -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

vec3 toPolar(vec3 p) {
  float r   = length(p);
  float t   = acos(p.z/r);
  float ph  = atan(p.y, p.x);
  return vec3(r, t, ph);
  
}

vec2 hash2(vec2 p) {
  p = vec2 (dot (p, vec2 (127.1, 311.7)),
            dot (p, vec2 (269.5, 183.3)));
  return -1. + 2.*fract (sin (p)*43758.5453123);
}

float noise(vec2 p) {
  float a = sin(p.x);
  float b = sin(p.y);
  float c = 0.5 + 0.5*cos(p.x + p.y);
  float d = mix(a, b, c);
  return d;
}

float fbm(vec2 p) {    
  const mat2 frot = mat2(0.80, 0.60, -0.60, 0.80);
 
  float f = 0.0;
  float a = 1.0;
  float s = 0.0;
  float m = 2.0;

  for (int x = 0; x < 2; ++x) {
    f += a*noise(p); p = frot*p*m;
    m += 0.01;
    s += a;
    a *= 0.5;
  }

  return f/s;
}

float warp(vec2 p, float e, out vec2 v, out vec2 w) {
  vec2 vx = vec2(0.0, 0.5)*e;
  vec2 vy = vec2(3.2, 1.3)*e;

  vec2 wx = vec2(1.7, 9.2)*e;
  vec2 wy = vec2(8.3, 2.8)*e;

  vx *= ROT(TTIME/1000.0);
  vy *= ROT(TTIME/900.0);

  wx *= ROT(TTIME/800.0);
  wy *= ROT(TTIME/700.0);

  v = vec2(fbm(p + vx), fbm(p + vy));
  
  w = vec2(fbm(p + -3.0*v + wx), fbm(p + 3.0*v + wy));
  
  return fbm(p + vec2(2.25, 1.25)*w);
}

vec3 color(vec3 ww, vec3 uu, vec3 vv, vec3 ro, vec2 p) {
  float lp = length(p);
  vec2 np = p + 1.0/RESOLUTION.xy;
  float rdd = (2.0+1.0*tanh_approx(lp));  // Playing around with rdd can give interesting distortions
  vec3 rd = normalize(p.x*uu + p.y*vv + rdd*ww);
  vec3 nrd = normalize(np.x*uu + np.y*vv + rdd*ww);

  vec2 rsi = raySphere(ro, rd, sphere);
  float rpi = rayPlane(ro, rd, plane);
  
  vec3 col = vec3(0.0);
  if (rsi != miss) {
    vec3 pi = ro + rd*rsi.x;
    vec3 ni = normalize(pi - sphere.xyz);
    float d = dot(-rd, ni);
    d -= 0.;
    float oi = smoothstep(0.0, 0.1, d);
    float ii = 1.0-smoothstep(0.1, 0.15, d);
    float f = oi*ii;

    float rings = 1.0;
    for (int i = 0; i < 4; ++i) {
      rings *= sin(5.0*pi.y*sqrt(float(i+3)));
    }

    rings = tanh_approx((rings)*1.5);
    float yf = pow(abs(pi.y)/sphere.w, 3.0);
    rings *= mix(1.0, 0.0, yf);
    vec3 ppi = toPolar(pi.xzy);

    vec2 v;
    vec2 w;
    float h = warp((ppi.zy+vec2(-0.033*TIME, 0.1))*2.0*vec2(1.0, 6.0), rings, v, w);

    h = mix(h, 1.0, yf);

    col += vec3(1.0)*mix(1.0, h*step(0.1, d), 1.0-f);
    col += rings*step(0.1, d);
  }
  
  if (rpi >= 0.0 && rpi < rsi.x) {
    vec3 pi = ro + rd*rpi;
    vec3 npi = ro + nrd*rpi;
    float aa = 2.0*length(npi-pi);
    vec2 pp = pi.xz;
    float r = length(pp);
    float d = circle(pp, 0.65);
    d = abs(d) - 0.06;

    float rings = 1.0;
    for (int i = 0; i < 3; ++i) {
      rings *= sin(100.0*r*sqrt(float(i+3)));
    }
    rings = tanh_approx((rings)*3.0);
    
    col += mix(0.0, 1.0, smoothstep(-aa, aa, -d))*rings;
  }
  
//  col = 1.0- col;
  return col;
}

// Classic post processing
vec3 postProcess(vec3 col, vec2 q) {
  col = clamp(col, 0.0, 1.0);
  col = pow(col, 1.0/std_gamma);
  col = col*0.6+0.4*col*col*(3.0-2.0*col);
  col = mix(col, vec3(dot(col, vec3(0.33))), -0.4);
  col *=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

vec3 effect(vec2 p, vec2 q) {
  vec3 ro   = 0.75*vec3(0.0, 1.0, -2.0);
  vec3 la   = vec3(0.0);
  vec3 up = normalize(vec3(0.25,1.0,0.0));
  vec3 ww = normalize(normalize(la - ro));
  vec3 uu = normalize(cross(up, ww));
  vec3 vv = normalize(cross(ww, uu));

  vec3 col = color(ww, uu, vv, ro, p);
  col = postProcess(col, q);
  return col;
}

void main(void) {
  vec2 q = gl_FragCoord.xy/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;

  vec3 col = effect(p, q);

  glFragColor = vec4(col, 1.0);
}
