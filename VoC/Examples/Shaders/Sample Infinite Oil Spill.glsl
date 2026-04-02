#version 420

// original https://www.shadertoy.com/view/NsKBRy

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define frame frames
#define resolution resolution.xy
const float pi = acos(-1.);
#define tri(x) abs(2.*fract(x)-1.)
#define sin1(x) (sin(x)*.5+.5)
mat2 rot(float a)
{
  float c=cos(a),s=sin(a);
  return mat2(c,-s,s,c);
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
const mat3 M =mat3(
    .74,-.52,.42,
    .64,.73,-.23,
    -.19,.45,.88
);
float fbm(vec3 p)
{
    float f = 0.0;
    f += 0.5000*noise( p ); p*=M*2.02;
    f += 0.2500*noise( p ); p*=M*2.03;
    f += 0.1250*noise( p ); p*=M*2.01;
    f += 0.0625*noise( p );
    f /= 0.9375;
    return f;
}
vec2 fan(vec2 p, int n)
{
  float N=float(n);
  float a = atan(p.y,p.x);
  a=mod(a,pi*2./N)-pi/N;
  return length(p)*vec2(cos(a),sin(a));
}
float box(vec2 p, vec2 s)
{
  vec2 d = abs(p)-s;
  return min(max(d.x,d.y),0.)+length(max(d,0.));
}
float line( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

void main(void)
{
        float mx = max(resolution.x, resolution.y);
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/mx;
    vec3 col = vec3(0);
    float w=fwidth(uv.y);
 float d=1e3;
 float t=float(frame)/60.;
 vec2 p=uv,q=uv;
 float a=atan(uv.y,uv.x);
 float k=length(p);
 col=vec3(1,2,3)*15.;
 t-=500.;
 int T=5;
 for(int i=0;i<T;++i)
 {
 p=
     sin1(p*pi*2.+t*float(i+1)*.03);
 p*=rot(float(i+1)*pi*2./float(T)-t*.3+k*5.);
 col=cross(col.zyx,vec3(p,k));
 }
 col=normalize(col)*.5+.5;
 col=col*1.2-.2;
 col=pow(col,vec3(1./2.2));
    glFragColor = vec4(col, 1.0);
}
