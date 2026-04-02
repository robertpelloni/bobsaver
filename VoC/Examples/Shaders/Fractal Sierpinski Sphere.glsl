#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3sfcRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Sierpinski Gasket on a sphere, with some randomization.
//
////////////////////////////////////////////////////////////////////////////////

const float AA = 2.0;
bool dorotate = true;
bool gasketonly = false;
bool docolor = true;
int depth = 10; // Levels of triangle
float pcolorchange = 0.25; // Probability of color change at a given level

const float PI = 3.14159265;

void assert(bool b);
vec3 hsv2rgb(vec3 c);
vec3 transform(in vec3 p);

// From Chris Wellons: https://nullprogram.com/blog/2018/07/31/
uint ihash(uint x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

uint randseed = 1U;
uint xorshift() {
  // Xorshift*32
  // From George Marsaglia: http://www.jstatsoft.org/v08/i14/paper
  randseed ^= randseed << 13;
  randseed ^= randseed >> 17;
  randseed ^= randseed << 5;
  return randseed;
}

float rand() {
  return float(xorshift())/pow(2.0,32.0);
}

vec3 getspherecolor(vec3 p) {
  uint index = uint(p.x<0.0)+(uint(p.y<0.0)<<1)+(uint(p.z<0.0)<<2);
  p = abs(p);
  p /= dot(p,vec3(1));
  vec2 z = p.xy;
  float E = 10.0;
  float t = 0.5*time;
  uint epoch = uint((t+0.5*E+1.0)/(E+2.0));
  t = mod(t,E+2.0)-1.0;
  t = max(t,0.0);
  if (t > 0.5*E) t = max(0.5*E,t-1.0);
  t = min(t,E-t); // t < 0.5*E
  randseed = ihash(epoch^index+1U); // 0 hashes to 0!
  vec3 col = hsv2rgb(vec3(rand(),0.8,1));
  for (int i = 0; i < depth; i++) {
    int j;
    if  (z.x > 0.5) { j = 0; z = 2.0*vec2(z.x-0.5,z.y); }
    else if (z.y > 0.5) { j = 1; z = 2.0*vec2(z.x,z.y-0.5); }
    else if (z.x + z.y < 0.5) { j = 2; z = 2.0*z; }
    else { j = 3; z = 0.5-z; }
    if (i > 0 && j == 3 && (gasketonly || rand() < 2.0*t/E)) return vec3(0);
    index = (index << 2) + uint(j);
    randseed = ihash(epoch^index+1U); // 0 hashes to 0!
    if (rand() < pcolorchange) col = hsv2rgb(vec3(rand(),0.8,1));
  }
  return docolor ? col : vec3(0.8);
}

struct Ray {
  vec3 q;               // origin
  vec3 d;               // direction
};

struct Hit {
  float t;      // solution to p=q+t*d
  vec3 n;       // normal
};

struct Sphere {
  vec3 p;       // centre
  float r;      // radius
};

bool intersectSphere(Sphere s, Ray ray, out Hit hit[2]) {
  vec3 p = s.p;
  float r = s.r;
  float c = length(p);
  vec3 q = ray.q, d = ray.d;
  // Formula for x^2 + 2Bx + C = 0
  // |q + t*d - p|^2 = r^2
  float B = dot(q-p,d);
  float C = dot(q,q)-2.0*dot(q,p)+(c+r)*(c-r);
  float D = B*B - C;
  if (D < 0.0) return false;
  D = sqrt(D);
  float t0,t1;
  if (B >= 0.0) {
    t0 = -B-D; t1 = C/t0;
  } else {
    t1 = -B+D; t0 = C/t1;
  }
  hit[0] = Hit(t0,(q+t0*d-p)/r);
  hit[1] = Hit(t1,-(q+t1*d-p)/r);
  return true;
}

bool intersectScene(Ray r, out Hit hit[2]) {
  Sphere s = Sphere(vec3(0),1.0);
  if (intersectSphere(s,r,hit)) {
    return true;
  }
  return false;
}

vec3 light;

// Smooth HSV to RGB conversion 
// Function by iq, from https://www.shadertoy.com/view/MsS3Wc
vec3 hsv2rgb( in vec3 c ) {
  vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    
  return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 solve(Ray r,vec2 uv) {
  Hit hit[2];
  vec3 c = vec3(0);
  if (intersectScene(r,hit)) {
    for (int i = 0; i < 2; i++) {
      vec3 n = hit[i].n;
      assert(dot(r.d,n) <= 0.0);
      vec3 basecolor = getspherecolor(hit[i].n);
      if (basecolor == vec3(0)) continue;
      vec3 color = vec3(0);
      float ambient = 0.5;
      float diffuse = 0.5;
      color += basecolor*ambient;
      color += basecolor*diffuse*max(0.0,dot(light,n));
      float specular = pow(max(0.0,dot(reflect(light,n),r.d)),5.0);
      vec3 speccolor = basecolor; //vec3(1);
      color += 1.0*specular*speccolor;
      if (i == 1) color *= 0.25;
      return color;
    }
  }
  return c;
}

const int CHAR_A = 65;
const int CHAR_B = 66;
const int CHAR_C = 67;
const int CHAR_D = 68;
const int CHAR_F = 70;
const int CHAR_G = 71;
const int CHAR_I = 73;
const int CHAR_M = 77;
const int CHAR_O = 79;
const int CHAR_Q = 81;
const int CHAR_R = 82;
const int CHAR_S = 83;
const int CHAR_T = 84;
const int CHAR_V = 86;
const int CHAR_X = 88;
const int CHAR_Z = 90;

const int KEY_PAGE_UP = 33;
const int KEY_PAGE_DOWN = 34;
const int KEY_LEFT = 37;
const int KEY_UP = 38;
const int KEY_RIGHT = 39;
const int KEY_DOWN = 40;

vec2 rotate(vec2 p, float t) {
  return p * cos(-t) + vec2(p.y, -p.x) * sin(-t);
}

vec3 transform(in vec3 p) {
  if (dorotate) {
    p.yz = rotate(p.yz,time * 0.125);
    p.zx = rotate(p.zx,time * 0.2);
  }
  return p;
}

bool check = false;
void assert(bool b) { if (!b) check = true; }

void main(void) {
  dorotate = true;
  pcolorchange *= exp(-0.1);
  depth = max(0,8);
  gasketonly = false; //key(CHAR_G);
  docolor = true; //!key(CHAR_C);
  light = vec3(0.5,1.0,-1.0);
  light = normalize(light);
  light = transform(light);
  vec3 p = vec3(0,0,-6);
  p.z *= exp(-0.1);
  p = transform(p);
  vec3 col = vec3(0);
  for (float i = 0.0; i < AA; i++) {
    for (float j = 0.0; j < AA; j++) {
      vec2 uv = (2.0*(gl_FragCoord.xy+vec2(i,j)/AA)-resolution.xy)/resolution.y;
      vec3 r = vec3(uv,6);
      r = transform(r);
      r = normalize(r);
      col += solve(Ray(p,r),uv);
    }
  }
  glFragColor = vec4(pow(col/(AA*AA),vec3(0.4545)),1);
  if (check) glFragColor = vec4(1,0,0,1);
}
