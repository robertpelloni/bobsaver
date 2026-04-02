#version 420

// original https://www.shadertoy.com/view/fldyzj

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define frame frames
#define resolution resolution.xy

const float pi = acos(-1.);
const float tau=pi*2.;
#define sin1(x) (sin((x))*.5+.5)
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
const mat2 M =mat2(
    .74,-.52,
    .64,.73
);
float fbm(vec2 p)
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
vec3 rgb2hsv(vec3 c)
{
    vec4 X = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, X.wz), vec4(c.gb, X.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}
vec3 hsv2rgb(vec3 c)
{
    vec4 k= vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
    return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
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
 float t=float(frame)/60.;
 vec2 p=uv,q=uv;
 float a=atan(uv.y,uv.x);
 float k=length(p);
 int I=11;
 float F=float(I);
 float d=0.;
 float dt=-t*.7;
 k=sin(sin(k*k*3.+sin(dt*1.)*3.+dt*3.)*1.)*.2+k;
 for(int i=0;i<I;++i)
 {
     float f=float(i);
 d=max(d,pow(sin1(a*6.+dt*3.+(k*15.)+19.*k*f/F),k*k*2.));
 }
 //d=min(d,1.);
 //d+=sin(w*2.);
 p*=rot(dt-pi/2.);
 d=max(d,1.-length(p)+.005);
 d=smoothstep(w,0.,1.-d);
 //hsv2rgb(vec3(a/tau-t*.2,.8,.8));
 col+=d;
 const float aa = 2.;
 float stars = 0.;
 for(float y=0.;y<aa;y++)
 for(float x=0.;x<aa;x++)
 {
 vec2 aauv=uv+vec2(x,y)/aa;
     stars+=smoothstep(w,0.,rand(aauv*250.));
 }
 stars/=aa*aa;
 col += stars;
 //gamma correction
 col=pow(col,vec3(1./2.2));
    glFragColor = vec4(col, 1.0);
}
