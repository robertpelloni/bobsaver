#version 420

// original https://neort.io/art/bpmlvgc3p9fbkbq846lg

//Inspired by https://www.shadertoy.com/view/tt3XR7 , https://www.shadertoy.com/view/wldXWr

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;
const float pi = acos(-1.);
const float pi2 = pi*2.;

float hash( float n ) { return fract(sin(n)*753.5453123); }

float hash(vec3 p)  // replace this by something better
{
    p  = 17.0*fract( p*0.3183099+vec3(.11,.17,.13) );
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}
//https://www.shadertoy.com/view/4sfGzS
float noise( in vec3 x )
{
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);

    return mix(mix(mix( hash(i+vec3(0,0,0)),
                        hash(i+vec3(1,0,0)),f.x),
                   mix( hash(i+vec3(0,1,0)),
                        hash(i+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(i+vec3(0,0,1)),
                        hash(i+vec3(1,0,1)),f.x),
                   mix( hash(i+vec3(0,1,1)),
                        hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}

mat2 rot(float r)
{
  float s = sin(r),c = cos(r);
  return mat2(c,s,-s,c);
}

vec3 pmod(vec2 p,float r)
{
  float a = atan(p.x,p.y)+pi/r;
  float n = pi2/r;
  float id = floor(a/n);
  a = id*n;
  return vec3(p*rot(-a),id);
}

float rand(vec2 p)
{
  return fract(sin(dot(p,vec2(12.34,56.78)))*12335.678);
}

float smin(float d1, float d2, float k){
    float h = exp(-k * d1) + exp(-k * d2);
    return -log(h) / k;
}

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

float noise(vec2 p)
{
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 k = vec2(0.,1.);

  float a = rand(i);
  float b = rand(i+k.yx);
  float c = rand(i+k.xy);
  float d = rand(i+k.yy);

  vec2 u = smoothstep(0.,1.,f);

  return mix(mix(a,b,u.x),mix(c,d,u.x),u.y);
}

float fbm(vec2 p)
{
  float val=0;
  float amp=.5;

  for(int i = 0;i<3;i++)
  {
    val += noise(p)*amp;
    p *= 2.;
    amp *= .5;
  }
  return val;
}

float sphere(vec3 p,float r)
{
  return length(p)-r;
}

float box(vec3 p,vec3 r)
{
  p = abs(p)-r;
  return length(max(p,0.)) + min(max(max(p.x,p.y),p.z),0.);
}

float rbox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

//https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = max(k-abs(-d1-d2),0.0);
    return max(-d1, d2) + h*h*0.25/k;
    //float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    //return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float dist(vec3 p)
{
  float d= 9999.;
  float k = 8.;
  vec3 pp = p;
  p.y += time;

  p.xy *= rot(1.);

  vec3 i = floor(p/k);
  float r0 = hash(i),r1 = hash(i+1.);

  p = mod(abs(p),k)-k*.5;
  p.x += cos(time+r0*100.)*r1;
  p.z += sin(time+r0*200.)*r0;
  p.xz *= rot(time*(0.1+r0*.5));
  p.yz *= rot(time*(0.1+r1*.5));

  float n = noise(p*5.);
  d = min(d,sphere(p,.8+r0*0.2+n*0.2));
  vec3 aaa =pmod(p.xz,8.);
  p.xz = aaa.xy;
  float pid = aaa.z;
  p.yz = pmod(p.yz,12.).xy;
  float r2 = sin(hash(pid)*100.+time+r0*100.)*0.3;
  p.xz *= rot(r2*0.25);
  d = smin(d,rbox(p,vec3(.01,.01,1.75-r2),.001),10.);
  d = smin(d,sphere(p-vec3(0.,0.,1.75-r2),0.012),8.);
  d = opSmoothSubtraction(sphere(p-vec3(0.,0.,1.76-r2),0.07),d,0.1);

  d = smin(d,pp.y+fbm(pp.xz+time*0.4)*0.2-0.03*sin(time),5.);
  d = min(d,-(length(pp.xz)-15.-noise(pp+vec3(0.,time*0.4,0.))));

  return d;
}

vec3 normal(vec3 p )
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
   float fb = fbm(vec2(time*.3,time*.2));
    vec3 ro = vec3(4.,14.,-14.+fb*2.),ta = vec3(0.);
    ro.xz *= rot(time*0.1);

    vec3 fo = normalize(ta-ro);
    vec3 le = normalize(cross(vec3(0.,1.,0.),fo));
    vec3 up = normalize(cross(fo,le));
    vec3 rd = normalize(fo*1.8+up*uv.y+le*uv.x);
    float t = 0.01,d;
    vec3 pos,col;
    int ma;

    for(int i = 0;i<60;i++)
    {
      ma = i;
      pos = ro + rd*t;
      d = dist(pos);
      if(d<0.01)
      {
        col = vec3(.5);
        vec3 n = normal(pos);
        vec3 ld = normalize(vec3(0.,-1.,0.));
        vec3 la = vec3(dot(n,ld));
        float le = (0.22+sin(time)*0.02)/length(pos.y-0.05);
        if(pos.y>0.)
         {
           la = la * vec3(2.,.8,.3);
         }
        float spec = pow(clamp(dot(reflect(ld,n),rd),0.,1.),10.);
        col+= vec3(la+spec*vec3(2.,.8,.3)+le*vec3(2.,.8,.3));

        break;
      }
      t += d;
    }

    float fog = max(0.,(1./50.)*float(ma))*1.4;
    col = col*fog;
    col *= vignette(uv2);

    glFragColor = vec4(col, 1.0);
}
