#version 420

// original https://www.shadertoy.com/view/flc3zr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pmod(p,m) (mod(p,m)-.5*(m))
#define time (time*.5)
#define fft(oct) 0.0; //(1./1024.)*sqrt(texture(iChannel0, vec2(1024./24000.*pow(2., (oct)))).r)
#define fftint(oct) 0.0; //texture(iChannel0, vec2(1024./24000.*pow(2., (oct)))).g
#define v2Resolution resolution

float ffta(float a, float b) {
  float iter=10.;
  float x=0.;
  for (float i=0.;i<1.;i+=1./iter) x+=fft(mix(a,b,i));
  return x/iter;
}
float fftinta(float a, float b) {
  float iter=10.;
  float x=0.;
  for (float i=0.;i<1.;i+=1./iter) x+=fftint(mix(a,b,i));
  return x/iter;
}

mat2 hexel = mat2(2., 0., -1., sqrt(3.))/3.;
mat2 pixel = mat2(3.,0.,sqrt(3.),2.*sqrt(3.))/2.;

vec3 to_cubic(vec2 p) { return vec3(p.x, -p.y-p.x, p.y); }

vec3 round_cubic(vec3 p, float m) {
  p *= m;
  vec3 r = round(p);
  
  vec3 d = abs(p-r);
  vec3 alt = -r.yzx-r.zxy;
  float big = max(d.x,max(d.y,d.z));
  
  return mix(r, alt, step(big, d))/m;
}

float box(vec3 p, vec3 a) {
  vec3 q = abs(p)-a;
  return length(max(q,0.))+min(0., max(q.x, max(q.y,q.z)));
}

float sphere(vec3 p, float r) {
  return length(p) - r;
}

mat2 rot(float a) {float s=sin(a),c=cos(a); return mat2(c,s,-s,c); }

float boxle(vec3 p, float r, float m) {
  r*=.8;
  float o = .1+ffta(0.,2.);
  float B = box(p, vec3(r))-o;
  
  float S = sphere(p, m*r)-o;
  return max(B,-S);
}
float glow=0.;
float S(vec3 p) {
  // i don't know how to get the equivalent of bonzo's texFFTIntegrated out of this texture
  float t=fract(mix(time, fftinta(7.,9.), 0.));

  //t=mix(t, smoothstep(0.,1.,t),.5);
  glow+=.001;
  float O = 1001.;
  
  for (float i=0.; i<3.; i+=1.) {
    float r=t+i;
    p.xz *= rot(r*.5);
    //p.xy *= rot(r*.8);
    p.yz *= rot(r*.6);

    O = min(O, boxle(p, r, 1.+log(1.+.3*r)));

  }
  return O;
}

#define MISS(d) (d > 1000.)

float ray(vec3 p, vec3 dir) {
  float d=0.;
  for (int i=0;i<500;i++) {
    float c = S(p+d*dir);
    d+=c;
    if (c<.00001) return d;
    if (MISS(d)) return d;
  }
  return 1001.;
}

vec3 normal(vec3 p) {
  mat3 k = mat3(p,p,p)-mat3(1e-4);
  return normalize(S(p) - vec3(S(k[0]), S(k[1]), S(k[2])));
}
#define desat(x, R) mix(x, vec3(x.r+x.g+x.b)/3., R)

#define TAU (2*acos(-1))
#define nsin(x) (.5+.5*sin(TAU*(x)))

vec3 light(vec3 cam, vec3 dir, float dist, vec3 hex) {
  vec3 hit = cam + dir*dist;
  
  vec3 n = normal(hit);
  
  float diff = dot(dir, -n);
  
  vec3 C = diff*reflect(dir,n);  
  
  return C;
}

#define gmix(a, b, q) ((a)*pow((b)/(a), (q))) 

#define tri(x) (abs(fract(x)-.5)*2.)
#define bump(x) (sqrt(abs(sin(x))))

void main(void) {
  vec2 uv = gl_FragCoord.xy / v2Resolution.xy - .5;
  vec2 uu = gl_FragCoord.xy / v2Resolution.xy;
  uv.x *= v2Resolution.x/v2Resolution.y;
  
  uv *= rot(time*.5);
  
  float res = gmix(40., 200., ffta(0., 1.)*10.);
  
  vec2 axial = uv * hexel;
  vec3 cubic = to_cubic(axial);
  
  
  
  vec3 hex = round_cubic(cubic, res);
  
  vec3 cam = vec3(0,0,-2);
  cam -= vec3(0,0,.5);
  vec3 dir = normalize(vec3(hex.xz*pixel, 1));
  vec3 real_dir = normalize(vec3(uv,1));
  
  float dist = ray(cam, dir);
  
    vec3 C;

  
  if (MISS(dist)) {
    C = hex;
  }
  else {
    C = light(cam,dir,dist,hex);
  }
    glow=0.;
  float real_dist = ray(cam+vec3(0,0,.5), real_dir);

  C-=(1.-desat(hex,.5))*glow;
  
  glFragColor = vec4(sqrt(C), 0.);
}
