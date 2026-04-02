#version 420

// original https://neort.io/art/bpmlt043p9fbkbq846hg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;
const float pi = acos(-1.);
const float pi2 = pi*2.;
#define TIMESCALE .8

mat2 rot(float r)
{
  float s = sin(r),c = cos(r);
  return mat2(c,s,-s,c);
}

float sphere(vec3 p,float r)
{
  return length(p)-r;
}

float box(vec3 p,float r)
{
  p = abs(p)-r;
  return max(max(p.x,p.y),p.z);
}

float rand(vec2 p)
{
  return fract(sin(dot(p,vec2(12.345,45.67)))*12345.235);
}

float noise(vec2 p)
{
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = smoothstep(0.,1.,f);
  vec2 k = vec2(0.,1.);
  float a = rand(i);
  float b = rand(i+k.yx);
  float c =rand(i+k.xy);
  float d = rand(i+k.yy);

  return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}

float fbm(vec2 p)
{
  float amp=.5;
  float val;
  for(int i = 0;i<4;i++)
  {
    val += noise(p)*amp;
    p *= 2.;
    amp*.5;
  }
  return val;
}

float dist(vec3 p)
{
  float d = 9999.;
  float k = 8.,kk = 50.;
  float r0 =rand(floor(p.xy/k)+100.);
  float t = time*TIMESCALE+r0;

  p.xy = mod(abs(p.xy),k)-k*.5;
  p.z = mod(abs(p.z)-r0*24.,kk)-kk*.5-t;
  float it = 4.;

  for(int i = 1;i<8;i++)
  {
    t += float(i)*(1./6./pi2);
    float it = floor(t);
    float ft = smoothstep(0.,1.,smoothstep(0.,1.,(clamp(fract(t),.25,.75)-.25)*2.));
    //ft = pow(ft,5.);
    d = min(d,sphere(p+vec3(0.,0.,ft+it+float(i)*2.),.5));

  }
  return d;
}

float dist2(vec3 p)
{
  float d= 9999.;
  float k = 8.;
  float r0 =rand(floor(p.xy/k)+100.);
  p.xy = mod(abs(p.xy),k)-k*.5;
  p.xy *= rot(r0*10.+time*0.1+p.y);
  p = abs(p)-.1;

  d = min(d,box(p.xyy,.02));
  return d;
}

float glow(vec3 ro,vec3 rd,float mt)
{
  float t = 0.01,d,ac;
  vec3 pos;
  for(int i = 0;i<60;i++)
  {
    if(t>mt)
    {
      break;
    }
    pos = ro+rd*t;
    d = dist(pos);
    ac += exp(-d*8.);
    t += 2.+sin(time*0.01);
  }
  return ac;
}

vec3 hsv(float r)
{
  return sin((vec3(0.,2./3.,-2./3.)+r)*pi)*.5+.5;
}

vec3 normal (vec3 p)
{
  float e = 0.001;
  vec2 k = vec2(1.,-1.);
  return normalize(
    k.xyy * dist(p+k.xyy*e)+
    k.yxy * dist(p+k.yxy*e)+
    k.yyx * dist(p+k.yyx*e)+
    k.xxx * dist(p+k.xxx*e)
    );
}
//https://www.shadertoy.com/view/lsKSWR
float vignette(vec2 uv)
{

   uv *=  1.0 - uv.yx;   //vec2(1.0)- uv.yx; -> 1.-u.yx; Thanks FabriceNeyret !

   float vig = uv.x*uv.y * 15.0; // multiply with sth for intensity

   vig = pow(vig, 0.45); // change pow for modifying the extend of the  vignette
   return vig;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec2 uv2 =gl_FragCoord.xy / resolution.xy;
    float ti = time*TIMESCALE*0.05;

    vec3 ro = vec3(0.+(fbm(vec2(time*0.05,time*0.01))*2.-1.),6.+1000.+time,-25.),ta = vec3(0.,0.,0.);
    ro.z -= ti;
    ta.z -= ti;
    vec3 fo = normalize(ta-ro),le = normalize(cross(vec3(0.,1.,0.),fo)),up = normalize(cross(fo,le))
    ,rd = normalize(fo*(1.-dot(uv,uv)*0.2)+up*uv.y+le*uv.x),col,pos;
    float t = 0.01,d;
    int ma;

    for(int i = 0;i<60;i++)
    {
      ma = i;
      pos = ro + rd*t;
      d = dist2(pos);
      if(d<0.01)
      {
        //vec3 n = normal(pos);
        //vec3 ld = normalize(vec3(1.,0.,1.));
        //ld.xy *= rot(time);
        //float la = dot(n,ld)*0.5+.5;
        vec3 le =hsv(length(pos.z*2.)*0.001+time*0.1)*((0.25/length(sin(pos.z*0.5+time*0.5))));
        //float spec = pow(clamp(dot(reflect(ld,n),rd),0.,1.),10.);
        col = vec3(le);
        break;
      }
      t += d;
    }
    float fog = max(0.,(1./99.)*float(ma));
    //vec3 fog2 = .007 * vec3(1.,1.,1.)*t;
    col = col*fog;

    col += glow(ro,rd,t)*hsv(length(pos.z*2.)*0.001+time*0.1);
    col *= vignette(uv2);
    col = mix(col,texture2D(backbuffer,uv2).rgb,0.3);

    glFragColor = vec4(col, 1.0);
}
