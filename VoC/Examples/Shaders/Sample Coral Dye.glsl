#version 420

// original https://www.shadertoy.com/view/mdlGRn

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define resolution resolution.xy
#define frame frames
#define touch mouse*resolution.xy.xy
const float pi=3.14159;
const float tau=pi*2.;
const float EPSILON=.0005;
const float PRECISION =.00025;
#define pi_(n) (pi/(n))

#define replim(p,c,a,b) ((p)-(c)*clamp(round((p)/(c)),(a),(b)))

mat2 rot(float a)
{
float c=cos(a),s=sin(a);
return mat2(c,-s,s,c);
}

float rand(vec2 n) {
return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float noise(vec2 p)
{
vec2 ip = floor(p);
vec2 u = fract(p);
u = u*u*(3.0-2.0*u);
float res = mix(
mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
return res*res;
}

float fbm(vec2 p)
{
const mat2 M =mat2(
.74,-.52,
.64,.73
);
    float f = 0.0;
    f += 0.5000*noise( p ); p*=M*2.02;
    f += 0.2500*noise( p ); p*=M*2.03;
    f += 0.1250*noise( p ); p*=M*2.01;
    f += 0.0625*noise( p );
    f /= 0.9375;
    return f;
}

vec3 hash3( float n )
{return fract(sin(vec3(n,n+1.0,n+2.0))*vec3(43758.5453123,22578.1459123,19642.3490423));}
float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}

float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

const mat3 M3 =mat3(
.74,-.52,.42,
.64,.73,-.23,
-.19,.45,.88
);

float fbm(vec3 p)
{
    float f = 0.0;
    f += 0.5000*noise( p ); p*=M3*2.02;
    f += 0.2500*noise( p ); p*=M3*2.03;
    f += 0.1250*noise( p ); p*=M3*2.01;
    f += 0.0625*noise( p );
    f /= 0.9375;
    return f;
}

vec2 fan(vec2 p,float n)
{
float a=atan(p.y,p.x);
a=mod(a,pi*2./n)-pi/n;
return length(p)*vec2(cos(a),sin(a));
}

float smin(float a, float b, float k)
{
    float x = exp(-k * a);
    float y = exp(-k * b);
    return (a * x + b * y) / (x + y);
}

float smax(float a, float b, float k)
{
    return smin(a, b, -k);
}

float line(vec3 p,vec3 a,vec3 b )
{
vec3 pa = p-a, ba = b-a;
float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
return length( pa - ba*h );
}

float box( vec3 p, vec3 b )
{
vec3 d = abs(p) - b;
return min(max(d.x,max(d.y,d.z)),0.0)
+ length(max(d,0.0));
}

float sdTriPrism( vec3 p, vec2 h ) { vec3 q = abs(p); return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5); }

float map(vec3 p)
{
float t=float(frame)/60.;
//t=3.1;
t*=.3;
float d=1e3;
p*=1.2;
vec3 q=p;
p.xz*=rot(t*1.13);
p.yx*=rot(t*2.17);
d=box(p,vec3(.25));
//d-=fbm(p.xz*5.)*.05;
//d*=.8;

float e=length(q)-.325;
d=mix(d,e,-1.25);
d-=.05;
d*=.5;
//d=smin(d,e+.15,.15);
d=smin(d,e,14.);
d=min(d,e+.15);
//d=min(d,line(p,vec3(0,0,-1),vec3(0,0,1))-.05);
//d=min(d,line(p,vec3(0,-1,0),vec3(0,1,0))-.05);
//d=min(d,line(p,vec3(-1,0,0),vec3(1,0,0))-.05);
d*=.6;

//d*=.7;

//d=min(d,q.y+.5);
//d*=.85;
//d*=.8;
return d;
}

float softShadow(vec3 ro, vec3 rd,
float mint, float tmax) {
  float res = 1.0;
  float t = mint;

  for(int i = 0; i < 16; i++) {
    float h = map(ro + rd * t);
      res = min(res, 8.0*h/t);
      t += clamp(h, 0.02, 0.10);
      if(h < PRECISION || t > tmax) break;
  }

  return clamp( res, 0.0, 1.0 );
}

vec3 normal(in vec3 p) {
vec2 e = vec2(1, -1) * EPSILON;
return normalize(
e.xyy * map(p + e.xyy)
+ e.yyx * map(p + e.yyx)
+ e.yxy * map(p + e.yxy)
+ e.xxx * map(p + e.xxx));
}
mat3 camera(vec3 ro, vec3 ta)
{
vec3 cd = normalize(ta-ro);
vec3 cr = normalize(
cross(vec3(0,1,0),cd));
vec3 cu = normalize(cross(cd,cr));
return mat3(-cr,cu,-cd);
}

void main(void)
{

vec3 bgcol=vec3(.6,.7,.8);
vec2 uv = gl_FragCoord.xy / resolution.xy;
vec2 q=(gl_FragCoord.xy-.5*resolution)/resolution.x;
vec2 s=abs(q)-vec2(.175);
if(max(s.x,s.y)>0.)
{
    glFragColor.rgb = pow(bgcol,vec3(1./2.2));
    return;
}
// if(length(q)>.175)discard;
//if(frame>1)discard;

vec3 col=vec3(0);
float t=0.;
bool hit=false;
vec2 tc=(2.*touch-resolution)/resolution.x;
vec3 ro=vec3(0.,0.,4);
ro*=1.;
float dt=float(frame)/60.;
//dt=0.;
ro.xz*=rot(dt);
ro.y+=3.;
//ro.yz*=rot(tc.y*2.);
vec3 ta=vec3(0,0,0);
vec3 rd=camera(ro,ta)
*normalize(vec3(q,-1.5));
int i=0;
float d=1e3;
for(i=0;i<1500;++i)
{
  d=map(ro+rd*t);
  t+=d;
  if(d<PRECISION/5.)
  {hit=true;break;}
  if(t>200.)
  {break;}
}
vec3 hitcol=vec3(0);

vec3 p=ro+rd*t;
vec3 n=normal(p);
if(hit)
{
vec3 light=vec3(4,9,2)*.4;
  vec3 lig=normalize(light-p);
  float dif=dot(n,lig)*.5+.5;
  float spe=pow(max(0.,
  dot(n,normalize(lig-rd))),180.);

float fresnel = pow(clamp(1. -
dot(n, -rd), 0., 1.), 5.);

float sha=clamp(
softShadow(p,lig,
.075,3.),
.1,1.);

  hitcol=vec3(0)
  +mix(
   vec3(.3,.8,.4),
  vec3(.9,.2,.1),
  dif)
   ;
   hitcol=pow(hitcol,vec3(2.));
  hitcol+=spe*.9;
  hitcol+=fresnel*.5;
  dt*=.3;
  p.xz*=rot(dt*1.13);
  p.yx*=rot(dt*2.17);
  hitcol*=cos(vec3(2,3,5)
  *fbm(p*32.*fbm(p*8.))*pi*4.)*.5+.5;
  hitcol=pow(hitcol,vec3(1./1.2));
  hitcol*=sha;
}
col=hitcol;
//OUTLINE
#if 0
float tm=smoothstep(0.,.1,
pow(float(i)/pow(th,50.),50.)
);
//tm=float(c-1)/120.;
//tm=smoothstep(.15,.1,tm);
col=mix(hitcol,col,tm);
#endif

//FOG
#if 1
  col = mix(col, bgcol, 1.0 - exp(-0.0002 * t*t*t)); // fog
#endif

col=pow(col,vec3(1./2.2));

// col*=smoothstep(.15*1.01,.15,length(q));

glFragColor = vec4(col, 1.0);
}
