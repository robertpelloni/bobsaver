#version 420

// original https://www.shadertoy.com/view/7tGXDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define time time
#define saturate(a) (clamp((a),0.,1.))
#define linearstep(a,b,t) (saturate(((t)-(a))/((b)-(a))))
#define BEAT (time*170.0/60.0)
float seed;

float hash13(vec3 p3)
{
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}
vec3 hash31(float p) {
    vec3 p2 = fract(p * vec3(5.3983, 5.4427, 6.9371));
    p2 += dot(p2.zxy, p2.xyz + vec3(21.5351, 14.3137, 15.3219));
    return fract(vec3(p2.x * p2.y * 95.4337, p2.y * p2.z * 97.597, p2.z * p2.x * 93.8365));
}

vec3 spline(vec3 a, vec3 b, vec3 c, vec3 d, float p)
{
    // CatmullRoms are cardinals with a tension of 0.5
    vec3 P = -a + (3. * (b - c)) + d;
    vec3 Q = (2. * a) - (5. * b) + (4. * c) - d;
    vec3 R = c - a;
    vec3 S = 2. * b;

    float p2 = p * p;
    float p3 = p * p2;

    return .5 * ((P * p3) + (Q * p2) + (R * p) + S);
}

vec3 getPos ( float t) {

  float n  = floor(t);
  
  

 float u = 4.;
  
  vec3 s = spline(
      hash31(n)    * u,
      hash31(n+1.) * u,
      hash31(n+2.) * u,
      hash31(n+3.) * u,
      fract(t)
   );
 
  return s;
}

float tor( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
float cylcap( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float hash(in vec3 p)
{
    p = fract(p * vec3(821.35, 356.17, 671.313));
    p += dot(p, p+23.5);
    return fract(p.x*p.y*p.z);
}

float noise(in vec3 p)
{
    vec3 ip = floor(p);
    vec3 fp = fract(p);
    
    float a = hash(ip + vec3(0, 0, 0));
    float b = hash(ip + vec3(1, 0, 0));
    float c = hash(ip + vec3(0, 1, 0));
    float d = hash(ip + vec3(1, 1, 0));
    float e = hash(ip + vec3(0, 0, 1));
    float f = hash(ip + vec3(1, 0, 1));
    float g = hash(ip + vec3(0, 1, 1));
    float h = hash(ip + vec3(1, 1, 1));
    
    vec3 t = smoothstep(vec3(0), vec3(1), fp);
    return mix(mix(mix(a, b, t.x), mix(c, d, t.x), t.y),
               mix(mix(e, f, t.x), mix(g, h, t.x), t.y), t.z);
}

float fbm(in vec3 p)
{   
    float res = 0.0;
    float amp = 0.5;
    float freq = 2.0;
    for (int i = 0; i < 5; ++i)
    {
        res += amp * noise(freq * p);
        amp *= 0.5;
        freq *= 2.0;
    }
    return res;
}

float bi_fbm(in vec3 p)
{
    return 2.0 * fbm(p) - 1.0;
}

vec3 warp(in vec3 p)
{
    p = p + bi_fbm(0.4*p + mod(0.5*time, 100.0));
    p = p + bi_fbm(0.4*p - mod(0.3*time, 100.0));
    return p;
}

float rand(float t) {
  return fract( sin(t * 7361.994) * 4518.442);
}
float rnd(float t) {
  return fract( sin(t * 7361.994) * 4518.442);
}

mat2 rot2d(float t)
{
  return mat2(cos(t),-sin(t),sin(t),cos(t));
}
mat2 rot(float a) {
  float ca=cos(a);
  float sa=sin(a);
  return mat2(ca,sa,-sa,ca);
}
float wave(vec3 p) {

   float elv = 0.;
   for (float i = 0.; i < 11.; i++) {
     p.xz *= rot(rnd(i ));
     p.yz *= rot(rnd(i+1.)*.32*2.);
     p.xy *= rot(i*5.);
    
     float q = 1.3 + abs(sin(11.1/30.)/10.);
     elv += cos((p.x + (i *171.9))/(10./pow(q,i))) * (4./pow(q,i));
     elv += cos((p.z * .61 + (i *61.2))/(10./pow(q,i))) *  (4./pow(q,i));
  
   

   }
   
   return pow(elv,.3);
}
vec3 lattice (float t ) {

 

  float m = t;
  float mx = floor((m-2.)/3.);
  float my = floor((m-1.)/3.);
  float mz = floor((m-0.)/3.);
  
  float n= m+1.;
  float nx = floor((n-2.)/3.);
  float ny = floor((n-1.)/3.);
  float nz = floor((n-0.)/3.);
  
  
 

  vec3 a =  
  mix(
      vec3(
          rand(mx)-.5,
          rand(my)-.5,
          rand(mz)-.5
      ),
      vec3(
          rand(nx)-.5,
          rand(ny)-.5,
          rand(nz)-.5
      ) , 
      fract(t)
  );
  return a;
}

float tick (float t ) {
  float i = floor(t);
  float r = fract(t);
  r = sqrt(r);
  return r + i;

}
vec3 flit(float t) {

  vec3 x = normalize(vec3(1));
  float t1 = tick(t);
  float t2 = tick(t * .71);
  float t3 = tick(t * .55);
  x.yz *= rot(t1);
  x.xz *= rot(t2);
  x.yx *= rot(t3);
  
  return x;
}

vec3 bezier( float t ){
  vec3 one = lattice(floor(t));
  vec3 two = lattice(floor(t+1.));
  float per = fract(t);
  
  return mix(one,two,per);
  
}

vec3 lofi (vec3 a, float b) {
  return floor(a/b) * b;
 
}
 

float fractsin(float v)
{
  return fract(sin(v*121.445)*34.59);
}

float rand()
{
  seed=fractsin(seed);
  return seed;
}

float easeceil(float t, float fac)
{
  return floor(t)+.5+.5*cos(PI*exp(fac*fract(t)));
}

float pi = 3.141592;
float surge (float tt) {

   return (1. - cos(mod(tt*pi,pi))/2.)+floor(tt);
 
}

float slomo ( float x) {
  x = mod(x,10.);
  
  float z = (pow(x-5.,6.)/( pow(x-5.,6.) + 1. ) );
  return z;
}

vec3 kifs(vec3 p) 
{
  
  float t = surge(time);
  float s =10.;
  for ( float i = 0.; i <5.; i++ ) {
 
    p.yz *= rot((t + i));
    p.xz *= rot((t - i) * .7);
    
   
    p = abs(p);
    
    p -= s;
    s *= 0.7;
  }
  return p;
}
float box(vec3 p,vec3 s)
{
  vec3 d=abs(p)-s;
  return length(max(d,0.));
}

float smin(float a, float b, float h) {
  float k=clamp((a-b)/h*0.5+0.5,0.0,1.0);
  return mix(a,b,k)-k*(1.0-k)*h;
}

float sph ( vec3 p, float r) {
  return length(p) - r;
}

vec3 ifs(vec3 p,vec3 rot,vec3 shift)
{
  vec3 pt=abs(p);
  vec3 t=shift;
  for(int i=0;i<6;i++)
  {
    pt=abs(pt)-abs(lofi(t*pow(1.8,-float(i)),1.0/512.0));
    t.yz=rot2d(rot.x)*t.yz;
    t.zx=rot2d(rot.y)*t.zx;
    t.xy=rot2d(rot.z)*t.xy;
    pt.xy=pt.x<pt.y?pt.yx:pt.xy;
    pt.yz=pt.y<pt.z?pt.zy:pt.yz;
    //pt.xz=pt.x<pt.z?pt.zx:pt.xz;
  }
  return pt;
}

float chassi (vec3 p) {
   p.z *= .5;
   float a = tor(vec3(p.x/1.,p.y/1.,p.z/2.) , vec2(3.,1.)) + box(p,vec3(3.4));
   return a * .5;
}
float body (vec3 p) {
    float a =box(p, vec3(3.,0.9,4.));
    float b =box(p - vec3(0,0.5,4.), vec3(3.,0.9,4.) * .9);
    
    vec3 pa = p;
    pa.zy *= rot(.3);
    float c= box(pa - vec3(0,4.4,0), vec3(3.,0.9,4.) * .4);
    
    vec3 pb = p;
    pb.zy *= rot(22.2);
    float d= sph(pb - vec3(0,0.7,0), 2.2);
    float e= sph(pb - vec3(0,0.7,-1.5), 3.0);
    return smin(e,smin(d, smin(c,smin(a,b,2.),5.), 2.),.2);
}

float grav ( vec3 p) {
  
  float a = sph(p + vec3(2.,0,8), 1.2);
  float b = sph(p + vec3(-2.,0,8), 1.2);
  float c = sph(p + vec3(2.,0,-8), 1.2);
  float d = sph(p + vec3(-2.,0,-8), 1.2);
  
  return min(d,min(c,min(a,b)));
}

vec3 opId(vec3 p, vec3 c) {
     return floor(p/c);
}

vec3 opRep(vec3 p, vec3 c) {
  return mod(p, c)- 0.5 * c;
}
float runner (vec3 pt) {

   pt= pt * 4.;
   pt.z *= 1.;
   vec3 p = pt + vec3(0,15.,0);

   
    float ch  = chassi(p);
    float bo = body(p);
    float gr = grav(p);
    return smin(gr,smin(ch,bo,.5),1.4) * .8;
}

float highway (vec3 p , vec3 shape, vec3 off, vec3 dir, float prob) {

  prob *= .4;
  dir *= .47;
  shape *= .11;
  p += off + dir * time * 3.11; 
  vec3 q = opRep(p, vec3(30,30,30)) ;
  vec3 qid = opId(p, vec3(30,30,30));
  float lim = fract(hash(qid * 1.7));
  float s;
  
  prob *=1.;
  
  if ( lim < prob ) {
      return runner(q);
  } else {
      return 10.;
  }

}
int matter = 0;
float map(vec3 p) {

  // geo
  
  vec3 p1 = p;
  vec3 p2 = p;
  vec3 p3 = p;
  vec3 p4 = p;
  vec3 p5 = p;
  vec3 p6 = p;

 
  //float final = R;
  float final=10000.;
  
 vec3 pt=p;
  
  //vec3 pr = p;
  //pr = p + vec3(10,-27.565,243.7 * time)/3.3; 
  //pr = rep(pr, vec3(20,50,20));
  //float run = runner(pr);
  
  
  
  //float width = mix(5.,15., abs(sin(time/100.)));
  float width = 13.;
  float halfwidth = width/2.;
  vec3 haha=lofi(pt,width);
  
  float phase=BEAT/8.0;
  phase+=dot(haha,vec3(2.75,3.625,1.0625));
  phase=easeceil(phase,-10.0);
  
 
  float clampBox=box(pt,vec3(2.));
  
  pt=ifs(pt,vec3(3.6,3.0+0.4+time/11.,3.1),vec3(3.0,2.3,3.5));

  vec3 seed = floor(p/width);
  float uu = hash13(seed);
  float dist;
  
  dist=box(pt,vec3(.17));

  dist=max(dist,clampBox);

  return dist;
 
}

vec3 norm(vec3 p,vec2 d)
{
  return normalize(vec3(
    map(p+d.yxx)-map(p-d.yxx),
    map(p+d.xyx)-map(p-d.xyx),
    map(p+d.xxy)-map(p-d.xxy)
  ));
}

vec3 norm3(vec3 p) {
  vec2 off=vec2(0.01,0.0);
  return normalize(map(p)-vec3(map(p-off.xyy), map(p-off.yxy), map(p-off.yyx))+0.000001);
}

float tock (float t){
  return t + sin(t);
}

void main(void)
{

  vec2 uv = vec2(gl_FragCoord.xy.x / resolution.x, gl_FragCoord.xy.y / resolution.y);
  uv -= 0.5;
  uv /= vec2(resolution.y / resolution.x, 1);
 
  float tt = time;
  
  // nav
  
  vec3 s = vec3(0,0,-5);
  s = lattice(tt) * 10.;
  
  vec3 t =  vec3(0,0,0);
  
   
  
  s *= 1.;(sin(tick(tt*.21)) * .5 + .5) +1.;
  float t1 =tock(tt * 1.21);
  float t2 =tock(tt * 1.0);
  float t3 =tock(tt * .81);
  s.yz *= rot(t1);
  s.xz *= rot(t2);
  
 
 
 
  vec3 cz=normalize(t-s);
  vec3 cx=normalize(cross(cz,vec3(0,1,0)));
  vec3 cy=normalize(cross(cz,cx));
      // fisheye
  cz += dot(uv,uv)/5.;
  
 
  vec3 r=normalize(cx*uv.x+cy*uv.y+cz * .8);
 
  bool hit = false;
  float d;
  float edge = 0.;
  float dd=0.;
  float i = 0.;
  vec3 p=s;
  vec3 n1,n2;
 
  
 
  // march
 
  for(float z=0.;z<100.;z++){ 
  
    i = z;
    d = map(p);

    if ( d < .001 ) {
      hit = true;
      break;
    } 
    
    dd += d;
    p += r * d;

  }
 
  
  
  // hue
  
  vec3 col = vec3(.8, .5, .2);
  float ao = i/100.;
  col -= ao ;

  n2 = norm(p, vec2(0.0, 1E-2 ));// + 3E-2*.01) );
  n1 = norm(p, vec2(0.0, 1.4E-2) );

  edge = saturate(length(n1-n2)/0.1);
  
  col -= edge;

  
  if (! hit){
      col = vec3(.93, .95, .90);
      col = vec3(1);
  }
  
  glFragColor = vec4(col, 1.0);

}
