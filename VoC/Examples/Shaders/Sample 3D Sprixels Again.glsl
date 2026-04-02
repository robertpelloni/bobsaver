#version 420

// original https://www.shadertoy.com/view/NdyXWd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define I (1.)
#define O (0.)
#define time (time*.5)

vec2 uv;

float[16] T1 = float[16](
  I,O,O,O,
  O,O,O,O,
  O,O,I,O,
  O,O,O,O
);

float[16] T2 = float[16](
  O,O,I,O,
  O,I,O,O,
  I,O,O,O,
  O,I,O,O
);

float[16] T3 = float[16](
  O,I,I,O,
  I,O,I,I,
  O,I,O,I,
  O,O,I,O
);

float[16] T4 = float[16](
  I,I,I,I,
  I,O,I,I,
  I,I,I,I,
  I,I,O,I
);

float px(float[16] arr, vec2 p) {
  p = fract(p);//mod(p, 1.);
  int x = int(p.x*4.);
  int y = int((1.-p.y)*4.);
  return arr[4*y+x];
}

mat2 rot(float x) { float s=sin(x),c=cos(x); return mat2(c,s,-s,c); }

#define nsin(x) (.5+.5*sin(x))
#define pmod(x,j) (mod(x,j)-.5*(j))

#define MISS(x) (x>1000.)

float sphere(vec3 p, float r) { return length(p)-r; }
float box(vec3 p, vec3 a) {
  vec3 q = abs(p)-a;
  return length(max(q, 0.)) + min(max(q.x,max(q.y,q.z)),0.);
}

float boxle(vec3 p, float r, float q) {
  return max(box(p, vec3(r)),-sphere(p,q*r));
}

float S(vec3 p) {
  //p+=vec3(.2,.2,2);
  float rad = fract(time);
  float S = 1001.;
  
  float ft=1.;
  
  for (float i=0.;i<=2.;i+=1.){
    float r=rad+i;
    p.xz *= rot(r*.35);
    p.xy *= rot(r*.1);
    p.xy *= rot(r*.05);

    S = min(S, boxle(p, r, 1.+.07*r*r*r));
  }
 

  return S;
}

float ray(vec3 p, vec3 dir) {
  float d=0.;
  for(int i=0;i<50;i++){
    float c=S(p+d*dir);
    d+=c;
    if (c<.1) return d;
    if (MISS(d)) return d;
  }
  
  return d;
}

vec3 normal(vec3 p) {
  mat3 k = mat3(p,p,p)-mat3(1e-3);
  return normalize(S(p)-vec3(S(k[0]), S(k[1]),S(k[2])));
}

float light(vec3 o, vec3 dir, float dist) {
  vec3 hit = o+dir*dist;
  vec3 n = normal(hit);
  
  float diff = dot(dir,-n);
  
  return diff;
}
vec3 HUE = vec3(0);

float pxsel(float x, vec2 p) {
  x *= 3.5;
  x-=.1;
  
  if (x<1.) { HUE=vec3(0, p); return px(T1,p); }
  if (x<2.) { HUE=vec3(p,0); return px(T2,p); }
  if (x<3.) { HUE=vec3(p.y,0,p.x);return px(T3,p); }
  return px(T4,p);
}

#define tri(x) (2.*abs(.5-fract(x)))

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
     uv = gl_FragCoord.xy/resolution.xy;
    uv-=.5;
    uv.x *= resolution.x/resolution.y;
    
    vec3 C;
    
    float RES=mix(4., 64., tri(.1*time+.3));
    
    
    vec2 px_aln = uv;
    px_aln *= RES;
    px_aln = floor(px_aln);
    px_aln /= RES;
    
    vec3 o = vec3(0,0,-5);
    vec3 dir = normalize(vec3(px_aln,1));
    
    float dist = ray(o,dir);
    float l = light(o,dir,dist);

    if (MISS(dist)) {
      C=pxsel(.5, uv*RES)+HUE*.02;
      C*=.5;
    }
    else {
      float pix = pxsel(light(o,dir,dist),RES*(uv-px_aln));
      C = vec3(rot(time)*uv+1.,0)*pix;
    }
    
    C = C.zxy;
    
    // Output to screen
    glFragColor = vec4(sqrt(C),1.0);
}
