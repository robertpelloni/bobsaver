#version 420

// original https://www.shadertoy.com/view/flcSz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define pi acos(-1.)
float t;

float[10] acum;
// https://www.shadertoy.com/view/3tcGDs
// Alkama <3
float noise(vec2 p){
  return 0;
}
#define h(d) fract(sin(d*56.6)*67.)
float c(float t){
  return mix(h(floor(t)),h(floor(t+1.)),pow(smoothstep(0., 1., fract(t)), 20.));
}
float tt;
float st(vec3 p, vec2 s){return length(vec2(length(p.xy)-s.x, p.z))-s.y;}
float sb(vec3 p, vec3 s){
  p=abs(p)-s;
  return length(max(p,0.)) + min(0.,max(max(p.x, p.y),p.z)) - 4.;
  }
float smin(float a, float b, float k){
  float h= max(0., k-abs(a-b));
  return min(a,b)-h*h*k*.25;
}

vec2 m1(vec3 p){
  float ss = sin(tt+p.y*.45);
  mat2 aa2= rot(radians(pi*24.));
  p.xy *= aa2;
  vec3 p1=p;
  vec2 dt=vec2(1.),dh;
  mat2 aa  = rot(p1.y*.0471+t);
  p1.xz*=aa;
  p1=abs(abs(p1)-2.)-1.-sin(tt+p.y*.41)*.5;
  p-=vec3(0., 4., 0.);
  dt = vec2(length(p)-sin(p.y*.15+tt)*4.455-15.5-ss*.25, 0.);
  acum[0]+=.1/(.1+dt.x*dt.x);
  dh = vec2(length(p1.xz)-3.-ss, 1.);
  dt.x = max(dt.x,-(length(p-vec3(0., -15., 0.))-15.-ss));
  dh.x = p.y > dh.x ? p.y : dh.x;
  dh.x = smin(dh.x, dt.x,1.);
  return vec2(dh.x,0.);
}
vec2 m2(vec3 p){
  
  vec3 p1=p;
  float fl = 20.+p1.y+noise(p.xz);
  vec2 dt,dh=m1(p);
  dt = vec2(fl, 1.);
  
  vec3 p2 = p;
  p2.y -= 50.;
  p2.x -= tt*5.;
  float ss = 20.;
  vec2 gid = (floor(p2.xz/ss-.5));
  p2.xz = (fract(p2.xz/ss-.5)-.5)*ss;
  float a = fract(sin(dot(gid, gid.yx*vec2(22.5,30.22))*52.));
  p2.yz*=rot(pi*a*.65);
  p2.yz*=rot(a-3.458*pi*.56);
  p2.xy*=rot(a+2.7656*pi*.657);
  p2.xz*=rot(a+2.6715*pi*.56);
  float cc = sb(p2, vec3(3.)*a*a+10.);
  vec3 p3 = p;
  p3.x-=tt*5.;
  p3.xz=(fract(p3.xz/ss-.5)-.5)*ss;
  p3-=vec3(0.,42.,0.);
  p3.xz*=rot(.454);
  float cc2 = length(p3+vec3(0., 3., 0.))-8.;
  dt.x = min(cc, dt.x);
  dt.x = max(.1-cc2, dt.x);
  dt.x *= .55;
  return dh.x < dt.x ? dh:dt;
}

vec2 m3(vec3 p){
  vec2 dt,dh=m2(p);
  vec2 ss = vec2(120.,70.);
  p.xz=p.xz-70.;
  p.xz -= tt*7.;
  p.xz=(fract(p.xz/ss-.5)-.5)*ss;
  p.xy *= rot(2.5);
  dt=vec2(length(p.xz)-10.,3.);
  dt.x = max(dt.x, p.y-1.);
  acum[1] += .35/(5.+dt.x*dt.x);
  return dh;
}

vec2 m(vec3 p){
  vec2 dt,dh=m3(p);
  p.yz = abs(p.yz)-1.;
  p.x -= sin(p.x*.45+t*20.);
  p.xz *= rot(-1.);
  p.x -= 0.5;
  p.y -= 5.;
  p.yx *= rot(p.z*.245);
  p.y += sin(p.z*.145+t*10.)*2.25-1.25;
  p.x += sin(p.z*.167+t*10.)*2.12-1.12;
  
  p.xy = abs(p.xy)-2.;
  
  dt = vec2(length(p.xy)-.1,4.);
  acum[2] += .1/(.1+dt.x*dt.x);
  dt.x*=.55;
  dh.x = smin(dt.x,dh.x,.25);
  return dh;
}
void main(void)
{
  t= mod(time, 100.)*.75;
  tt= c(t)+t*8.;
    
  vec2 uv = ((gl_FragCoord.xy/resolution.xy)-0.5) / vec2(resolution.y / resolution.x, 1);
  uv*=2.;
  float ph = .135+.135;
  uv.y -= cos(sin(t*.45+uv.x*.645)*2.25-.25+t*.245)*ph + sin(cos(t*.25+uv.y*.435)*2.25-.25+t*.256)*ph;
  vec3 s = vec3(0.01, 10.01,-80.);
  mat2 aa = rot(sin(t*.125)*pi*2.);
  s.xz*=aa;
  vec3 p = s;
  vec3 cz = normalize(vec3(0.,-1.,0.)-s);
  vec3 cx = normalize(cross(cz,vec3(0., -1., 0.)));
  vec3 cy = normalize(cross(cx,cz));
  vec3 r = mat3(cx,cy,cz)*normalize(vec3(uv, 1.));
  vec3 co = vec3(0.144);
  vec2 dt,dh,e=vec2(.01,0.);
  float i;
  vec3 n, l = normalize(vec3(-1., -2.,-3.));
  l.xz *= aa;
  for(i = 0.;i < 64.; i++){
    dt = m(p);
    dh.x = dt.x;
    if(abs(dh.x) < .001){
      n = normalize(m(p).x - vec3(m(p-e.xyy).x, m(p-e.yxy).x,m(p-e.yyx).x));
      float dif = max(0., dot(l, n));
      float sp = pow(max(.0,dot(reflect(-l,n), -r)), 50.);
      float fr = pow(1.+dot(l,n),4.);
      co = vec3(dif + sp )*min(.45,fr);
      if(dt.y == 0.){
          r=reflect(r, n)*.1;
          p+=5.;
      }
      if(dt.y == 1. ){
          r=refract(r, n,.65)*.11;
          p+=20.;
      }
    }
    if(dh.y > 150.) break;
    dh.y += dh.x;
    p+=dh.x*r;
  }
  vec3 COL_M = vec3(0.434)*.025;
  vec3 COL_L = vec3(0.3, 0.0853, 0.75)*2.;
  vec3 COL_LL = vec3(.1, .1, .73);
  
  co += acum[0]*COL_M*.31;
  co += acum[1]*COL_L*.91;
  co += acum[2]*COL_LL;
  co += pow((i/100.),.4545)*vec3(0.34,0.1,0.96)*.63595;
  co = pow(co, vec3(.453434));
  
  co *= 1.-max(0., length(p-s)/40.)*(1.-vec3(.34, .15, 0.75)*.86);
    glFragColor = sqrt(vec4(co, 1.));
}
