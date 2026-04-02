#version 420

// original https://www.shadertoy.com/view/tdjGRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// 3D Lissajous figures
//
////////////////////////////////////////////////////////////////////////////////

bool dorotate = true;
bool dophase = false;
bool docos = false;

const float PI = 3.14159;

struct Ray {
  vec3 q;               // origin
  vec3 d;               // direction
};

struct Hit {
  float t;      // solution to p=q+t*d
  vec3 n;       // (unnormalized) normal
  int id;       // what was hit
};

struct Sphere {
  float r2;      // radius squared
  vec3 p;       // centre
  int id;
};

bool intersectSphere(Sphere s, Ray ray, out Hit hit) {
  vec3 p = s.p;
  float r2 = s.r2;
  float c2 = dot(p,p);
  vec3 q = ray.q-s.p, d = ray.d;
  // |q + t*d|^2 = r^2
  float B = dot(q,d);
  float C = dot(q,q)-r2;
  float D = B*B - C;
  if (D < 0.0) return false;
  D = sqrt(D);
  float t,t1;
  if (B >= 0.0) {
    t = -B-D; t1 = C/t;
  } else {
    t1 = -B+D; t = C/t1;
  }
  if (t < 0.0) t = t1;
  if (t < 0.0) return false;
  // Normal is the radial vector of sphere
  // We normalize it later
  hit = Hit(t, q+t*d, s.id);
  return true;
}

vec2 rotate(vec2 p, float t) {
  return p * cos(-t) + vec2(p.y, -p.x) * sin(-t);
}

vec3 transform(in vec3 p) {
  /*
  if (mouse*resolution.xy.x > 0.0) {
    float theta = (2.0*mouse*resolution.xy.y-resolution.y)/resolution.y*PI;
    float phi = (2.0*mouse*resolution.xy.x-resolution.x)/resolution.x*PI;
    p.yz = rotate(p.yz,theta);
    p.zx = rotate(p.zx,phi);
  }
  */
  if (dorotate) {
    float t = time;
    //p.xy = rotate(p.xy,t*0.123);
    p.zx = rotate(p.zx,t*0.2);
  }
  return p;
}

int imod(int n, int m) {
  return n - n/m*m;
}

float P = 3.0;
float Q = 2.0;
float R = 1.0;
float NN = 200.0;
bool intersectScene(Ray ray, out Hit hit) {
  float k = 0.5*(1.0+cos(0.2*time));
  hit.t = 1e8;
  NN = (P+Q+R)*20.0;
  for (float i = 0.0; i < max(-time,NN); i++) {
    float r = 0.1;
    float t = i*2.0*PI/NN;
    t += 0.1*time;
    float phase = 0.0;
    if (dophase) phase += 0.123*time;
    if (docos) phase += 0.5*PI;
    vec3 p = vec3(sin(P*t),sin(Q*t),sin(R*t+phase));
    Sphere s = Sphere(r*r,p,int(i));
    Hit hits;
    if (intersectSphere(s,ray,hits) && hits.t < hit.t) {
      hit = hits;
    }
  }
  return hit.t < 1e8;
}

vec3 light;
float ambient;
float diffuse;

vec3 hsv2rgb(float h, float s, float v) {
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing       
  return v * mix( vec3(1.0), rgb, s);
}

vec4 solve(Ray r) {
  Hit hit;
  if (!intersectScene(r,hit)) {
    return vec4(0,0,0,1);
  } else {
    vec3 n = normalize(hit.n);
    if (dot(r.d,n) > 0.0) n *= -1.0;
    vec3 baseColor = hsv2rgb(float(hit.id)/NN,0.5,1.0);
    vec3 color = vec3(0);
    color += baseColor.xyz*ambient;
    color += baseColor*diffuse*max(0.0,dot(light,n));
    float specular = pow(max(0.0,dot(reflect(light,n),r.d)),10.0);
    color += 1.0*specular*baseColor;
    color *= clamp(1.0 - (hit.t-3.0)/5.0,0.0,1.0);
    return vec4(sqrt(color),1.0);
  }
}

const int CHAR_C = 67;
const int CHAR_P = 80;
const int CHAR_R = 82;

void main(void) {
  vec2 uv = gl_FragCoord.xy/resolution.y;
  uv.y = 1.0-uv.y;
  uv *= 5.0;
  vec2 pq = floor(uv)+1.0;
  P = pq.x, Q = pq.y;
  uv = 2.0*fract(uv)-1.0;;
  vec3 p = vec3(0,0,-4.0);
  vec3 d = vec3(uv.x, uv.y, 2.0);
  p = transform(p);
  d = transform(d);
  d = normalize(d);
  light = vec3(0.5,1.0,-1.0);
  light = transform(light);
  light = normalize(light);
  ambient = 0.6;
  diffuse = 0.2;
  glFragColor = solve(Ray(p,d));
}
