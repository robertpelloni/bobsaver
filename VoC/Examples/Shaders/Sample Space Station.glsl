#version 420

// original https://www.shadertoy.com/view/3dfSWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
 Space Station.

 The basic model design was taken from:
 https://www.ctvnews.ca/china-launches-first-module-for-future-space-station-1.704462

 Added the Hex (as a living module)
 
 Mostly made from cylinders and boxes. Added bump map to several surfaces (panels in particular).

 As always, the helper functions (noise, intersections) are taken from others (mostly iq).
*/

#define PI 3.14159265359
#define PI2 6.28318530718

#define ROTY(p,al) p.xz = cos(al)*p.xz+ sin(al)*vec2(p.z,-p.x);
#define ROTX(p,al) p.yz = cos(al)*p.yz+ sin(al)*vec2(p.z,-p.y);
#define ROTZ(p,al) p.xy = cos(al)*p.xy+ sin(al)*vec2(p.y,-p.x);

float hash(in vec2 st) {
return fract(sin(dot(st.xy,
vec2(12.9898,78.233)))
* 43758.5453123);
}

float noise2d(vec2 st) {
  vec2 ist = floor(st);
  vec2 fst = fract(st);

  vec2 u = 3.*fst*fst - 2.*fst*fst*fst;

  float ll = hash(ist);
  float lr = hash(ist + vec2(1.,0.));
  float tl = hash(ist + vec2(0.,1.));
  float tr = hash(ist + vec2(1.,1.));

  float f = mix(mix(ll,lr,u.x),
    mix(tl,tr,u.x),u.y);

  return f;

}

float noise2d(in vec2 st, in vec2 m) {
vec2 i = floor(st);
vec2 f = fract(st);

// Four corners in 2D of a tile
float a = hash(mod(i,m));
float b = hash(mod(i + vec2(1.0, 0.0),m));
float c = hash(mod(i + vec2(0.0, 1.0),m));
float d = hash(mod(i + vec2(1.0, 1.0),m));

// Smooth Interpolation

// Cubic Hermine Curve. Same as SmoothStep()
vec2 u = f*f*(3.0-2.0*f);
// u = smoothstep(0.,1.,f);

// Mix 4 coorners porcentages
return mix(a, b, u.x) +
(c - a)* u.y * (1.0 - u.x) +
(d - b) * u.x * u.y;
}

vec2 hash22( in vec2 x )  // replace this by something better
{
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    return -1.0 + 2.0*fract( 16.0 * k*fract( x.x*x.y*(x.x+x.y)) );
}

float hash12(in vec2 p) {
    float h = dot(p,vec2(127.1,311.7));    
    return fract(sin(h)*437.545);
}

float hash12_b(in vec2 p, in int b) {
    p = mod(p, vec2(b, b));
    return hash12(p);
}

/*
float noised_b( in vec2 p, in float b )
{
    p *= b;
    vec2 i = floor( p );
    vec2 f = fract( p );

#if 1
    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    vec2 du = 30.0*f*f*(f*(f-2.0)+1.0);
#else
    // cubic interpolation
    vec2 u = f*f*(3.0-2.0*f);
    vec2 du = 6.0*f*(1.0-f);
#endif    
    
    vec2 ga = hash22( mod(i + vec2(0.0,0.0), vec2(b,b)) );
    vec2 gb = hash22( mod(i + vec2(1.0,0.0), vec2(b,b)) );
    vec2 gc = hash22( mod(i + vec2(0.0,1.0), vec2(b,b)) );
    vec2 gd = hash22( mod(i + vec2(1.0,1.0), vec2(b,b)) );
    
    float va = dot( ga, f - vec2(0.0,0.0) );
    float vb = dot( gb, f - vec2(1.0,0.0) );
    float vc = dot( gc, f - vec2(0.0,1.0) );
    float vd = dot( gd, f - vec2(1.0,1.0) );

    return va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd);
}

float noisev_b(in vec2 p, in float b) {
    int ib = int(b);
    p *= b;
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    float flb = hash12_b(i + vec2(0.,0.), ib);
    float flu = hash12_b(i + vec2(0., 1.), ib);
    float frb = hash12_b(i + vec2(1., 0.), ib);
    float fru = hash12_b(i + vec2(1., 1.), ib);
    
    #if 1
    // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.0-15.0)+10.0);
    #else
    // cubic interpolation
    vec2 u = f*f*(3.0-2.0*f);
    #endif  
    
    float fv = mix(mix(flb, frb, u.x), mix(flu, fru, u.x), u.y);
    
    return fv;
}
*/

float hash(in vec3 p)
{
return fract(sin(dot(p,
vec3(12.6547, 765.3648, 78.653)))*43749.535);
}

float noise3(in vec3 p)
{
vec3 pi = floor(p);
vec3 pf = fract(p);

pf = pf*pf*(3.-2.*pf);

float a = hash(pi + vec3(0., 0., 0.));
float b = hash(pi + vec3(1., 0., 0.));
float c = hash(pi + vec3(0., 1., 0.));
float d = hash(pi + vec3(1., 1., 0.));

float e = hash(pi + vec3(0., 0., 1.));
float f = hash(pi + vec3(1., 0., 1.));
float g = hash(pi + vec3(0., 1., 1.));
float h = hash(pi + vec3(1., 1., 1.));

return mix(mix(mix(a,b,pf.x),mix(c,d,pf.x),pf.y),
mix(mix(e,f,pf.x),mix(g,h,pf.x),pf.y), pf.z);
}

float fbm(vec3 p) {

  float f = 0.;
  float ampl = 0.5;
  float freq = 1.;
  float off = 0.;

  int i = 0;
  for (i = 0; i < 6; i++) {
    f += ampl*noise3(p*freq + off);
    ampl*= 0.5;
    freq *= 2.;
    off += 12.274739;
  }

  return f;
}

float fbmH(vec3 p) {

  float f = 0.;
  float ampl = 0.5;
  float freq = 1.;
  float off = 0.;

  int i = 0;
  for (i = 0; i < 8; i++) {
    f += ampl*noise3(p*freq + off);
    ampl*= 0.5;
    freq *= 2.;
    off += 12.274739;
  }

  return f;
}

float sdBox( vec3 p, vec3 b )
{
  //p.xz = cos(time)*p.xz+ sin(time)*vec2(p.z,-p.x);
   vec3 d = abs(p) - b;
return length(max(d,0.0));
// + min(max(d.x,max(d.y,d.z)),0.0);
// remove this line for an only partially signed sdf }
}

float sdRoundCone( in vec3 p, in float r1, float r2, float h ) { vec2 q = vec2( length(p.xz), p.y ); float b = (r1-r2)/h; float a = sqrt(1.0-b*b); float k = dot(q,vec2(-b,a)); if( k < 0.0 ) return length(q) - r1; if( k > a*h ) return length(q-vec2(0.0,h)) - r2; return dot(q, vec2(a,b) ) - r1; }

float sminC( float a, float b, float k ) { float h = max( k-abs(a-b), 0.0 )/k; return min( a, b ) - h*h*h*k*(1.0/6.0); }
float sdVerticalCapsule( vec3 p, float h, float r ) { p.y -= clamp( p.y, 0.0, h ); return length( p ) - r; }

float hex(in vec2 p) {
   vec3 vhex = vec3(0.5, -0.5773503, 0.866025);
   
   float alpha = atan(p.y, p.x) + 0.833333*PI;
   float len = length(p);
      
   float new_alpha = mod(alpha, PI / 3.) + PI / 3.;
    
   vec2 ap = len*vec2(cos(new_alpha), sin (new_alpha));
    
   float f = ap.y;
    
   return length(f);
}

vec2 hexSquares(in vec2 p, in float dist) {
   vec3 vhex = vec3(0.5, -0.5773503, 0.866025);
   
   float alpha = atan(p.y, p.x) + 0.83333*PI;
   float len = length(p);
   
    
   float new_alpha = mod(alpha, PI / 3.) + PI/3.;
    
   vec2 ap = len*vec2(cos(new_alpha), sin (new_alpha));
   
   // this one should be used if new_alpha is adjusted to + PI.
   mat2 m = mat2(vhex.xy, vec2(vhex.y, -vhex.x));
   vec2 vp = ap*m;
   float f = abs(vp.y);
    
   f = ap.y;
   vec2 cp = vec2(ap.x, ap.y-dist);
   float modv = 0.8;//len/6.;
   cp.x = mod(abs(cp.x) - 0.5*modv, modv) - 0.5*modv;
   cp.x = abs(cp.x) - 0.12;
   
   return cp;
}

vec3 noiseNorm(in vec2 uv) {
  vec2 e = vec2(0.001,0.0);

  vec3 norm;

  norm.x = .1*(noise2d(uv + e.xy) - noise2d(uv - e.xy));
  norm.y = .1*(noise2d(uv + e.yx) - noise2d(uv - e.yx));
  norm.z = 2.*e.x;

  return normalize(norm);
}

vec2 panelNormal(in vec2 st) {
  float mrg = 0.1;
   float inv_mrg = 10.;
  float st1 = step(mrg,st.x);
  float st2 = step(mrg,1.-st.x);
  float normx = (1.-st1)*6.*st.x*(1.-st.x*inv_mrg)*inv_mrg;
  normx -= (1.-st2)*6.*(1.-st.x)*(1.-(1.-st.x)*inv_mrg)*inv_mrg;
  float normz = clamp(step(0.01,normx)/normx,0.,1.) +
                step(0.99,1.-normx);
  return normalize(vec2(normx,normz));
}

vec3 panelNormal3(in vec2 st) {
  float mrg = 0.05;
  float inv_mrg = 20.;
  float stx1 = step(mrg,st.x);
  float stx2 = step(mrg,1.-st.x);
  float normx = (1.-stx1)*6.*st.x*(1.-st.x*inv_mrg)*inv_mrg;
  normx -= (1.-stx2)*6.*(1.-st.x)*(1.-(1.-st.x)*inv_mrg)*inv_mrg;
  float sty1 = step(mrg,st.y);
  float sty2 = step(mrg,1.-st.y);
  float normy = (1.-sty1)*6.*st.y*(1.-st.y*inv_mrg)*inv_mrg;
  normy -= (1.-sty2)*6.*(1.-st.y)*(1.-(1.-st.y)*inv_mrg)*inv_mrg;
  normx *= (step(0.999,abs(sty1*sty2)));
  normy *= (step(0.999,abs(stx1*stx2)));
  return normalize(vec3(normx,normy,1.));
}

vec3 dCirculNorm(in vec2 uv,in vec2 grid) {
  vec2 center = vec2(0.5,0.5);
  vec2 fuv = fract(uv*grid);
  vec2 iuv = floor(uv*grid);
  float rad = length(fuv - center);
  float step1 = 10.;
  float step2 = 10.;
  float r1 = clamp(6.*(rad-0.1)*(1.-(rad-0.1)*step1)*step1,0.,1.);
  r1 += clamp(6.*(rad-0.3)*(1.-(rad-0.3)*step2)*step2,0.,1.);

  vec2 r2 = vec2(1.) - (step(1.,iuv)*step(1.,grid-iuv-1.));
  r2.x = r2.y = float(bool(r2.x)||bool(r2.y));
  vec3 norm = normalize(vec3(r1*r2,1./(1.+0.01)));
  //norm = normalize(vec3(rad,rad,1./(rad+0.001)));
  return norm;
}

/*float hash12(in vec2 i) {
    return fract((dot(sin(i), vec2(139243.1251234,7719.119348))));
}*/

float cpattern(in vec2 p) {
    vec2 grid = vec2(0.2);
    vec2 ip = floor((p - grid/2.)/grid + 1.);
    vec2 pp = mod(p - grid/2., grid) - grid / 2.;
    float rad = length(pp);
    float iff = hash12(ip);
    float f = smoothstep(0.96, 0.97, 1.-rad)*step(0.7, iff);
    return f;
}

vec3 pattNorm(in vec2 uv) {
  vec2 e = vec2(0.001,0.0);

  vec3 norm;

  norm.x = .1*(cpattern(uv + e.xy) - cpattern(uv - e.xy));
  norm.y = .1*(cpattern(uv + e.yx) - cpattern(uv - e.yx));
  norm.z = 2.*e.x;

  return normalize(norm);
}

vec3 camera(in vec3 o, in vec3 d, in vec3 tar) {
  vec3 dir = normalize(o - tar);
  vec3 right = cross(vec3(0.,1.,0.),dir);
  vec3 up = cross(dir,right);

  mat3 view = mat3(right,up,dir);
  return view*d;
}

vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec2 sphIntersect( in vec3 ro, in vec3 rd, in vec3 ce, float ra )
{
    vec3 oc = ro - ce;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - ra*ra;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0); // no intersection
    h = sqrt( h );
    return vec2( -b-h, -b+h );
}

vec2 boxIntersect( in vec3 ro, in vec3 rd, in vec3 boxSize, out vec3 outNormal ) 
{
    vec3 m = 1.0/rd; // can precompute if traversing a set of aligned boxes
    vec3 n = m*ro;   // can precompute if traversing a set of aligned boxes
    vec3 k = abs(m)*boxSize;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN>tF || tF<0.0) return vec2(-1.0); // no intersection
    outNormal = -sign(rd)*step(t1.yzx,t1.xyz)*step(t1.zxy,t1.xyz);
    return vec2( tN, tF );
}

float shuttle(in vec3 p)
{
vec3 op = p;
//p.xz = cos(time)*(p.xz)+ sin(time)*vec2(p.z,-p.x);
float lenxz = length(p.xz);

//cylw
op = p;
op.y -= 2.;
op.x = abs(p.x) - 2.2;
float brad = length(op.zy);
float blen = abs(op.x);
//float bli = clamp(pow(blen*0.7,8.),0.,brad*0.2);
float fc1 = max(brad - .8,(blen-1.5+brad*0.8));

//cylwf
op = p;
op.y -= 2.;
op.x = abs(p.x) - 5.;

brad = length(op.zy);
blen = abs(op.x);

float fc2 = max(brad - .4,(blen-2.));

//central sphere
op = p - vec3(0.,2.,0.);
float fc3 = length(op) - 0.65;

//wingc
op = p - vec3(0.,2.,0.);
float f1 = max(length(op.yz)-0.25,abs(op.x)-1.4);
float f2 = max(lenxz-0.25,abs(op.y)-1.4);
float fc4 = min(f1,f2);

//rear1
op = p - vec3(0.,.85,0.);
float fr1 = max(lenxz-0.6,abs(op.y)-0.5+0.5*lenxz*lenxz);

//rear2
float fr2 = sdVerticalCapsule(p+vec3(0.,0.6,0.),0.6,0.45);

//rear3
op = p + vec3(0.,.9,0.);
blen = abs(op.y);
float fr3 = max(lenxz - 0.6 -0.1*pow(blen*2.,8.)*step(0.,-op.y),blen - 0.5);

//forward 1
op = p - vec3(0.,4.2,0.);
float fw1 = max(lenxz-0.6,abs(op.y)-1.8+1.4*lenxz);

//forward 2
op = p - vec3(0.,5.7,0.);
float fw2 = max(lenxz-0.9,abs(op.y)-.9+0.35*lenxz*lenxz);

//forward 3+
op = p - vec3(0.,6.7,0.);
float rad = lenxz;
f2 = max(rad-0.8,abs(op.y)-.4);
op.y +=0.3;
float f3 = max(rad - 0.7,abs(op.y)-.8);
op.y -=1.35;
float f4 = max(rad - .7,abs(op.y)-.6 +0.5*rad);
op.y += 0.7;
float f5 = max(rad - .3,abs(op.y)-.6);
op.y -= 1.3;
float f6 = max(rad - .5,abs(op.y)-.4);
float fw3 = min(min(min(min(f3,f2),f4),f5),f6);

//solar panel rear
op = vec3(abs(p.x)-1.9,p.y+.94,p.z);
float fpr = sdBox(op,vec3(1.,0.36,.02));

// solar panel wing center
op = vec3(abs(p.x)-6.,p.y-2.,abs(p.z) - 2.);
float fpc = sdBox(op,vec3(0.02,0.5,1.4));

//solar panel forward
op = vec3(abs(p.x)-1.3,p.y-8.5,p.z);
float fpw = sdBox(op,vec3(.7,0.2,.02));

// solar panel c4
op = vec3(p.x,p.y-4.,abs(p.z)-2.1);
float ft = sdBox(op,vec3(0.02,0.7,1.4));

op = vec3(abs(p.x)-2.1,p.y-4.,p.z);
float fp4 = min(ft,sdBox(op,vec3(1.4,0.7,0.02)));

// rear panel connect
op = vec3(abs(p.x)-0.68,p.y+.95,p.z);
float lenyz = length(op.yz);
blen = abs(op.x);
f1 = max(lenyz-.05,blen-0.1);
op.x -= 0.17;
op.y = abs(op.y) - 0.15;
ROTZ(op,PI/3.);
lenyz = length(op.yz);
blen = abs(op.x);
f2 = max(lenyz-0.02,blen-0.1);
float frc = sminC(f1,f2,0.1);

// panel connect
op = vec3(abs(p.x)-0.65, abs(p.y-4.)-0.3,p.z);
float r1 = length(op)-0.03;
float r2 =  length(vec3(p.x, abs(p.y-4.)-0.3,abs(p.z)-0.65))-0.03;
float frc1 = min(r1,r2);

// wing connect
op = vec3(abs(p.x)-6.,p.y-2.,p.z);
ROTX(op,PI/8.);
f1 = max(length(op.xy)-0.02,abs(op.z)-.7);
ROTX(op,-PI/4.);
f2 = max(length(op.xy)-0.02,abs(op.z)-.7);
float frc2 = min(f1,f2);

// forward panel connect
op = vec3(abs(p.x)-0.5,p.y-8.5,p.z);
lenyz = length(op.yz);
blen = abs(op.x);
f1 = max(lenyz-.02,blen-0.05);
op.x -= 0.06;
op.y = abs(op.y) - 0.06;
ROTZ(op,PI/3.);
lenyz = length(op.yz);
blen = abs(op.x);
f2 = max(lenyz-0.02,blen-0.05);
float frc3 = sminC(f1,f2,0.05);
    
// hex
op = vec3(p.x, p.y - 6.7, p.z);
ROTY(op, time*.05);
float hfr = max(lenxz - .8, abs(op.y) - 0.5);
float hff = max(length(op.zy) - .2, abs(op.x) - 3.);
vec2 qf = vec2(hex(op.xz) - 3., op.y); 
hff = sminC(hff, hfr, 0.1);
float hf = sminC(hex(qf) - .6, hff, 0.1);
    
vec2 windHex = hexSquares(op.xz, 3.6);
    
vec2 hexwind = vec2(max(abs(windHex.x)-0.01, abs(windHex.y)-0.05),op.y);
hexwind.y = abs(hexwind.y) - 0.2;
float hfwind = max(abs(hexwind.x)-0.08, abs(hexwind.y)-0.07);
hf = max(hf, -hfwind);

vec2 topHex = hexSquares(op.xz, 3.2);    
vec2 hextop = vec2(max(abs(topHex.x)-0.3, abs(topHex.y)-0.3),op.y);
hextop.y = abs(hextop.y) - 0.4;
float hftop = max(abs(hextop.x)-0.08, abs(hextop.y)-0.07);
hf = max(hf, -hftop);

float of = min(min(min(fc1,fc2),fc3),fc4);
of = min(min(fr2,min(of,fr1)),fr3);
of = min(min(min(of,fw1),fw2),fw3);
of = min(of,min(fpr,min(fpw,min(fp4,fpc))));
of = sminC(of, hf, 0.1);
    
of = sminC(of,frc,0.08);
of = sminC(of,frc1,0.1);
of = sminC(of,frc2,0.1);
of = sminC(of,frc3,0.05);
//of = mix(-of, df,0.54);

return of;
//p.xz = cos(time)*p.xz+ sin(time)*vec2(p.z,-p.x);
//p.y -=abs(p.x)*1.5*(2.-p.y);
}

float shuttle(in vec3 p,inout vec3 norm, out vec3 col)
{
vec3 op = p;
//p.xz = cos(time)*(p.xz)+ sin(time)*vec2(p.z,-p.x);
float lenxz = length(p.xz);

//cylw
op = p;
op.y -= 2.;
op.x = abs(p.x) - 2.2;
float brad = length(op.zy);
float blen = abs(op.x);
//float bli = clamp(pow(blen*0.7,8.),0.,brad*0.2);
float fc1 = max(brad - .8,(blen-1.5+brad*0.8));

//cylwf
op = p;
op.y -= 2.;
op.x = abs(p.x) - 5.;

brad = length(op.zy);
blen = abs(op.x);

float fc2 = max(brad - .4,(blen-2.));

//central sphere
op = p - vec3(0.,2.,0.);
float fc3 = length(op) - 0.65;

//wingc
op = p - vec3(0.,2.,0.);
float f1 = max(length(op.yz)-0.25,abs(op.x)-1.4);
float f2 = max(lenxz-0.25,abs(op.y)-1.4);
float fc4 = min(f1,f2);

//rear1
op = p - vec3(0.,.85,0.);
float fr1 = max(lenxz-0.6,abs(op.y)-0.5+0.5*lenxz*lenxz);

//rear2
float fr2 = sdVerticalCapsule(p+vec3(0.,0.6,0.),0.6,0.45);

//rear3
op = p + vec3(0.,.9,0.);
blen = abs(op.y);
float fr3 = max(lenxz - 0.6 -0.1*pow(blen*2.,8.)*step(0.,-op.y),blen - 0.5);

//forward 1
op = p - vec3(0.,4.2,0.);
float fw1 = max(lenxz-0.6,abs(op.y)-1.8+1.4*lenxz);

//forward 2
op = p - vec3(0.,5.7,0.);
float fw2 = max(lenxz-0.9,abs(op.y)-.9+0.35*lenxz*lenxz);

//forward 3+
op = p - vec3(0.,6.7,0.);
float rad = lenxz;
f2 = max(rad-0.8,abs(op.y)-.4);
op.y +=0.3;
float f3 = max(rad - 0.7,abs(op.y)-.8);
op.y -=1.35;
float f4 = max(rad - .7,abs(op.y)-.6 +0.5*rad);
op.y += 0.7;
float f5 = max(rad - .3,abs(op.y)-.6);
op.y -= 1.3;
float f6 = max(rad - .5,abs(op.y)-.4);
float fw3 = min(min(min(min(f3,f2),f4),f5),f6);

//solar panel rear
op = vec3(abs(p.x)-1.9,p.y+.94,p.z);
float fpr = sdBox(op,vec3(1.,0.36,.02));

// solar panel wing center
op = vec3(abs(p.x)-6.,p.y-2.,abs(p.z) - 2.);
float fpc = sdBox(op,vec3(0.02,0.5,1.4));

//solarop = vec3(p.x,p.y-4.,abs(p.z)-2.1); panel forward
op = vec3(abs(p.x)-1.3,p.y-8.5,p.z);
float fpw = sdBox(op,vec3(.7,0.2,.02));

// solar panel c4
op = vec3(p.x,p.y-4.,abs(p.z)-2.1);
float ft = sdBox(op,vec3(0.02,0.7,1.4));

op = vec3(abs(p.x)-2.1,p.y-4.,p.z);
float fp4 = min(ft,sdBox(op,vec3(1.4,0.7,0.02)));

// rear panel connect
op = vec3(abs(p.x)-0.68,p.y+.95,p.z);
float lenyz = length(op.yz);
blen = abs(op.x);
f1 = max(lenyz-.05,blen-0.1);
op.x -= 0.17;
op.y = abs(op.y) - 0.15;
ROTZ(op,PI/3.);
lenyz = length(op.yz);
blen = abs(op.x);
f2 = max(lenyz-0.02,blen-0.1);
float frc = sminC(f1,f2,0.1);

// panel connect
op = vec3(abs(p.x)-0.65, abs(p.y-4.)-0.3,p.z);
float r1 = length(op)-0.03;
float r2 =  length(vec3(p.x, abs(p.y-4.)-0.3,abs(p.z)-0.65))-0.03;
float frc1 = min(r1,r2);

// wing connect
op = vec3(abs(p.x)-6.,p.y-2.,p.z);
ROTX(op,PI/8.);
f1 = max(length(op.xy)-0.02,abs(op.z)-.7);
ROTX(op,-PI/4.);
f2 = max(length(op.xy)-0.02,abs(op.z)-.7);
float frc2 = min(f1,f2);

// forward panel connect
op = vec3(abs(p.x)-0.5,p.y-8.5,p.z);
lenyz = length(op.yz);
blen = abs(op.x);
f1 = max(lenyz-.02,blen-0.05);
op.x -= 0.06;
op.y = abs(op.y) - 0.06;
ROTZ(op,PI/3.);
lenyz = length(op.yz);
blen = abs(op.x);
f2 = max(lenyz-0.02,blen-0.05);
float frc3 = sminC(f1,f2,0.05);

// hex
op = vec3(p.x, p.y - 6.7, p.z);
ROTY(op, time*.05);
float hfr = max(lenxz - .8, abs(op.y) - 0.5);
float hff = max(length(op.zy) - .2, abs(op.x) - 3.);
vec2 qf = vec2(hex(op.xz) - 3., op.y); 
hff = sminC(hff, hfr, 0.1);
float hf = sminC(hex(qf) - .6, hff, 0.1);
    
vec2 windHex = hexSquares(op.xz, 3.6);
    
vec2 hexwind = vec2(max(abs(windHex.x)-0.01, abs(windHex.y)-0.05),op.y);
hexwind.y = abs(hexwind.y) - 0.2;
float hfwind = max(abs(hexwind.x)-0.08, abs(hexwind.y)-0.07);
hf = max(hf, -hfwind);

vec2 topHex = hexSquares(op.xz, 3.2);    
vec2 hextop = vec2(max(abs(topHex.x)-0.3, abs(topHex.y)-0.3),op.y);
hextop.y = abs(hextop.y) - 0.4;
float hftop = max(abs(hextop.x)-0.08, abs(hextop.y)-0.07);
hf = max(hf, -hftop);

float of = min(min(min(fc1,fc2),fc3),fc4);
of = min(min(fr2,min(of,fr1)),fr3);
of = min(min(min(of,fw1),fw2),fw3);
of = min(of,min(fpr,min(fpw,min(fp4,fpc))));
of = sminC(of, hf, 0.1);
    
of = sminC(of,frc,0.08);
of = sminC(of,frc1,0.1);
of = sminC(of,frc2,0.1);
of = sminC(of,frc3,0.05);
//of = mix(-of, df,0.54);

if ((of == fpr) && abs(norm.z) > 0.5) {
   vec2 uof = vec2(abs(p.x)-0.95,p.y+.94)/vec2(2.,0.72);
   vec2 nuv = panelNormal(fract(uof*5.));
   norm *= vec3(nuv.x,0.,nuv.y);
   col = vec3(0.12,0.,0.23);

} else if ((of == fpw) && abs(norm.z) > 0.5) {
   vec2 uof = vec2(abs(p.x)-0.65,p.y-8.5)/vec2(1.4,0.4);
   vec2 nuv = panelNormal(fract(uof*5.));
   norm *= vec3(nuv.x,0.,nuv.y);
   col = vec3(0.12,0.,0.23);
} else if (of==fp4 && abs(norm.z) > 0.5) {
   vec2 uof = vec2(abs(p.x)-2.1,p.y-4.)/vec2(1.4,0.7);
   norm = panelNormal3(fract(uof*3.))*sign(norm);
   col = vec3(0.12,0.,0.23);
} else if (of==fp4 && abs(norm.x) > 0.5) {
   vec2 uof = vec2(abs(p.z)-2.1,p.y-4.)/vec2(1.4,0.7);
   norm.zyx = panelNormal3(fract(uof*3.))*sign(norm.x);
   col = vec3(0.12,0.,0.23);
} else if (of==fpc && abs(norm.x) > 0.5) {
   vec2 uof = vec2(abs(p.z) - 2.,p.y-2.)/vec2(1.4,0.5);
   vec2 nuv = panelNormal(fract(uof*5.))*sign(norm.x);
   norm = vec3(nuv.y,nuv.x,0.);
   col = vec3(0.12,0.,0.23);
} else if (of == fc2) {
   vec2 uof = vec2(abs(p.x)-5.,p.y-2.);
   float ang = 0.5*(atan(p.z,uof.y)/PI)+0.5;
   float h = clamp((abs(p.x) - 3.)/6.,0.,1.);
   float fnoise = noise2d(vec2(h, ang)*20., vec2(20.));
   col = vec3(0.4,0.6,0.8)*(1.+fnoise*0.1);
} else if (of == fc1) {
   vec2 uof = vec2(abs(p.x)-2.2,p.y-2.);
   float ang = 0.5*(atan(p.z,uof.y)/PI)+0.5;
   float h = clamp((abs(p.x) - 1.4)/1.6,0.,1.);
   vec2 uv = vec2(ang,h);
   vec3 v1 = vec3(1.,0.,0.);
   vec3 v2 = cross(norm,v1);
   vec2 cuv = vec2(uv.x*16.,uv.y*3.);
   vec3 nnorm = noiseNorm(uv*100.);
   vec3 anorm = panelNormal3(fract(cuv));
   //vec3 cnorm = dCirculNorm(fract(cuv),vec2(4.,6.));

   norm = (mat3(v1,v2,norm)*(anorm+nnorm));

   col = vec3(0.4,0.6,0.8);
   //norm = vec3(1.);
} else if (of == fc4) {
   col = vec3(0.5,0.52,0.2);
} else if (of == fw2) {
   vec2 uof = vec2(p.x,p.y-5.7);
   float ang = 0.5*(atan(p.z,p.x)/PI)+0.5;
   float h = clamp((abs(p.y) - 5.2)/1.,0.,1.);
   vec2 uv = vec2(ang,h);
   vec3 v1 = vec3(0.,1.,0.);
   vec3 v2 = cross(norm,v1);
   vec2 cuv = vec2(uv.x*16.,uv.y*4.);
   vec3 anorm = panelNormal3(fract(cuv));
   vec3 nnorm = noiseNorm(uv.yx*100.);
   //vec3 cnorm = dCirculNorm(fract(cuv),vec2(4.,6.));

   norm = mat3(v1,v2,norm)*(anorm+nnorm);
   col = vec3(0.5,0.6,0.87);
} else if (of == fw1) {
    vec3 uop = p - vec3(0.,4.2,0.);
    float h = clamp((uop.y+1.5)/3., 0., 1.);
    float ang = 0.5*(atan(uop.z, uop.x)/PI) + 0.5;
    vec3 v1 = normalize(vec3(p.x, 0., p.z));
    vec3 v2 = vec3(0., 1., 0.);
    vec3 v3 = cross(v1, v2);
    
    vec3 anorm = pattNorm(vec2(ang, h));
    norm = mat3(v3, v2, v1)*anorm;
    col = vec3(0.5,0.6,0.87);
} else {
   float ang = 0.5*(atan(p.z,p.x)/PI)+0.5;
   col = vec3(0.5,0.6,0.87);
}

return of;
//p.xz = cos(time)*p.xz+ sin(time)*vec2(p.z,-p.x);
//p.y -=abs(p.x)*1.5*(2.-p.y);
}

const vec4 planet_center = vec4(-23., -15., -3., 12.);
float planet(in vec3 p)
{
    return length(p - planet_center.xyz) - planet_center.w;
}

/*float planet_b(in vec3 p) {
    //return rock(p);
    vec2 tuv = vec2(atan(p.y,p.x)/PI2 + 0.5,
                    asin(p.z/length(p))/PI + 0.5);
    // scale the amplitude so that it's smaller at the poles.
       float ascale = 0.01 + smoothstep(0., 1.,1.-abs(0.5-tuv.y)*2.);
    
    float ampl = planet_center.w/3.;
    float freq = 2.;
    float nf = 0.;
    
    for (int i = 0; i < 4; i++) {
        nf += ampl*ascale*clamp(noised_b(tuv, freq),0.,1.);
        ampl *= 0.5;
        freq *= 2.;
        tuv += 0.94;
    }
    return 0.8*(length(p - planet_center.xyz) - planet_center.w -nf);
}

float planet_bh(in vec3 p) {
    //return rock(p);
    vec2 tuv = vec2(atan(p.y,p.x)/PI2 + 0.5,
                    asin(p.z/planet_center.w)/PI + 0.5);
    // scale the amplitude so that it's smaller at the poles.
       float ascale = 0.01 + smoothstep(0., 1.,1.-abs(0.5-tuv.y)*2.);
    
    float ampl = planet_center.w/3.;
    float freq = 2.;
    float nf = 0.;
    
    for (int i = 0; i < 16; i++) {
        nf += ampl*ascale*clamp(noised_b(tuv, freq),0.,1.);
        ampl *= 0.5;
        freq *= 2.;
        tuv += 0.94;
    }
    return (length(p - planet_center.xyz) - planet_center.w -nf);
}*/

#define FAR 50.
#define VOL_FOG_STEP .15
#define VOL_DENSITY 4.

float star_p(in vec3 p) {
  return FAR - 3. - length(p);   
}

vec2 geom(in vec3 p)
{
    vec2[2] t_vec; 
    t_vec[0].x = shuttle(p);
    t_vec[1].x = planet(p);
    //t_vec[2].x = star_p(p);
    
    vec2 res = vec2(FAR, -1.);
    
    for (int i_t = 0; i_t < 2; i_t++)
    {
        if (t_vec[i_t].x < res.x)
        {
            res.x = t_vec[i_t].x;
            res.y = float(i_t);
        }
    }
        
    return res;
}

vec3 getCentralDiffShuttle(vec3 o, vec3 d, float t)
{
    vec3 norm;
    vec3 e = vec3(0.00001, 0.0, 0.0)*t;

    vec3 p = o + t*d;

    norm.x = shuttle(p + e.xyy) - shuttle(p - e.xyy);
    norm.y = shuttle(p + e.yxy) - shuttle(p - e.yxy);
    norm.z = shuttle(p + e.yyx) - shuttle(p - e.yyx);

    norm = normalize(norm);
    
    return norm;
}

/*
vec3 getCentralDiffPlanet(vec3 o, vec3 d, float t)
{
    vec3 norm;
    vec3 e = vec3(0.0001, 0.0, 0.0)*t;

    vec3 p = o + t*d;

    norm.x = planet_bh(p + e.xyy) - planet_bh(p - e.xyy);
    norm.y = planet_bh(p + e.yxy) - planet_bh(p - e.yxy);
    norm.z = planet_bh(p + e.yyx) - planet_bh(p - e.yyx);

    norm = normalize(norm);
    
    return norm;
}*/

vec4 trace(in vec3 o, in vec3 d)
{
    float threshold = 0.0001;
    // vec4(final distance, current distance, nearest distance, geom type);
    vec4 res = vec4(0., FAR, FAR, 10.);
    for (int i=0;i<192;i++)
    {
       vec3 p = o + res.x*d;
       
       res.yw = geom(p);
       res.z = min(res.z, res.y);
       res.x += res.y;

       if (res.y < threshold*res.x || res.x > FAR) 
       {
           threshold *= res.x;
           break;
       }
    }
    
    return res;
}

vec4 vol_trace(in vec3 o, in vec3 d, in vec3 res_t)
{
    float vol_steps = 0.;
    float valpha = 0.;
    float vol_acc = 0.;
    vec3 vol_col = vec3(0.);
    float threshold = 0.0001*res_t.x;
    
    float v_dist = step(threshold, res_t.y)*FAR + (1.-step(threshold,res_t.y))*res_t.x;
    
    vol_steps = (v_dist / VOL_FOG_STEP)*(exp(-res_t.z*.001));
    vec3 cp = vec3(0.13, 0.34, .886);
    for (int iv = 0; float(iv) < vol_steps; iv++)
    {
        vec3 vp = o + (float(iv)*VOL_FOG_STEP)*d - threshold;
        
        float density = VOL_DENSITY*exp(0.3*
             (planet_center.w - length(vp-planet_center.xyz)));
        valpha = fbm(vp)*density*VOL_FOG_STEP;
        vol_col = valpha*cp + (1.-valpha)*(vol_acc);
        vol_acc = valpha + (1. - valpha)*(vol_acc);
        
        if (vol_acc > 0.98)
            break;
    }
    
    return vec4(vol_col, vol_acc);
}

void cameraSetup(inout vec3 o, inout vec3 d)
{
    o.y = 20.*sin(time*0.2);
    float r = 2. + min(0., 0.5*o.y);
    o = vec3(6.*sin(time),o.y, 6.*cos(time));
    vec3 target = vec3(0., 10.*sin(time*0.065), 0.);
    target = mix(target, vec3(planet_center.x, 0., 0.), pow(cos(0.25*time)*0.5+0.5, 8.));
    d = camera(o, d, target);
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy;

    if (resolution.y > resolution.x)
       uv.y *= resolution.y/resolution.x;
    else
       uv.x *= resolution.x/resolution.y;

    vec3 o = vec3(sin(time),5.,10.);
    vec3 d = normalize(vec3(-1. +2.*(uv-vec2(0.,0.)),-1.));
    
    vec3 col;
    vec3 bc;
    
    float threshold = 0.0001;
    vec4 res_t;
    vec4 vol_col;
    
    cameraSetup(o, d);

    res_t = trace(o, d);
    threshold *= res_t.x;
    
    // volumetric step
    vol_col = vol_trace(o, d, res_t.xyz);
    

    if (res_t.y < threshold && res_t.w < 0.5)
    {
       vec3 specCol;
       vec3 p = o + res_t.x*d;
        
       vec3 norm = getCentralDiffShuttle(o, d, res_t.x);
       shuttle(p,norm,bc);
      
      col += 0.7*bc*(dot(-norm,d));
      specCol = 0.3*vec3(256.*exp(-res_t.x))*
          clamp(pow(max(0., dot(reflect(d, norm), -d)),4.), 0., 1.);
      
      col = clamp(col + specCol, 0., 1.);
    } else if (res_t.y < threshold && res_t.w < 1.5)
    {
        vec3 p = o + res_t.x*d;
        vec3 norm = normalize(p - planet_center.xyz);
        col += vec3(0.83, 0.34, 0.16)*(dot(-norm,d));;
    } else
    {
        vec2 st = sphIntersect(o, d, vec3(0.), 60.);
        vec3 boxNorm;
        vec2 st_b = boxIntersect(o, d, vec3(70.), boxNorm);
          
        vec3 p_sph = o + min(st.x, st.y)*d;
        
        float thr = fbm(p_sph*0.035);
        col = 0.7*vec3(0.,thr*0.95, thr);
        
        vec3 p_box = o +st_b.y*d;
        float shr = fbmH(p_box*0.02);
        shr = pow(shr + 0.3, 16.);
        col = col + vec3(shr, 0.8*shr, shr);
        col = clamp(col, 0., 1.);
    }

    col = mix(col, vol_col.xyz, vol_col.w);

    glFragColor = vec4(pow(col, vec3(2.2)), 1.0);
}
