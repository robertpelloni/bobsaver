#version 420

// original https://neort.io/art/bmv9a5s3p9f7m1g039dg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const float PI = acos(-1.);
const float TAU = PI * 2.;

#define saturate(x) clamp(x,0.,1.)
#define _tail2x(p,n) (mod(p,2.)-1.)

float Hash( vec2 p, in float s ){
    return fract(sin(dot(vec3(p.xy,10.0 * abs(sin(s))),vec3(27.1,61.7, 12.4)))*273758.5453123);
}

float noise(in vec2 p, in float s){
  vec2 i = floor(p);
  vec2 f = fract(p);
  return mix(
    mix(Hash(i + vec2(0.,0.), s), Hash(i + vec2(1.,0.), s),f.x),
    mix(Hash(i + vec2(0.,1.), s), Hash(i + vec2(1.,1.), s),f.x),f.y) * s;
}

float fbm(vec2 p){
  float v = 0.0;
  v += noise(p*34., .1);
  v += noise(p*20., .04);
  return v;
}

vec2 mPolar(vec2 p){
  float a = atan(p.y, p.x);
  float r = length(p);
  return vec2(a, r);
}

vec2 tailY2x(vec2 p,float n){p*=n;return vec2(p.x,_tail2x(p.y,n));}
mat2 rot(float a){float c=cos(a),s=sin(a);return mat2(c,-s,s,c);}

highp float rand(vec2 p){
  highp float a = 12.9898;
  highp float b = 78.233;
  highp float c = 43758.5453;
  highp float dt= dot(p ,vec2(a,b));
  highp float sn= mod(dt,3.14);
  return fract(sin(sn) * c);
}

// signed distance
float sd(float d,float r){return r-d;} 
float sd(float d){return 1.-d;} 
// glow + fill
float gf(float d,float r){return r/d;} 
float gf(float d){return 1./d;} 

float fill_na(float d){return step(0.,d);}
float fill(float d){return smoothstep(0.,0.01,d);}
float stroke(float d,float w){return 1.-smoothstep(w,w+0.01,abs(d));}
float strokeInner(float d,float w){return stroke(d-w,w);}
float strokeOuter(float d,float w){return stroke(d+w,w);}

float lSquare(vec2 p){p = abs(p);return max(p.x,p.y);}     

float lPoly(vec2 p,float n){
  float a = atan(p.x,p.y)+PI;
  float r = TAU/n;
  return cos(floor(.5+a/r)*r-a)*length(p)/cos(r*.5);
}

float strokeStar(vec2 p,float n,float w){
  float l =strokeInner(sd(lPoly(p,n*.5)),w);
  l+=strokeInner(sd(lPoly(mod(n,2.)!=0.?vec2(-p.x,p.y):p*rot(TAU/n),n*.5)),w);
  return l;
}

vec2 mPoly(vec2 p,float n,float s){
  float r = TAU / n;
  float a = floor(atan(p.y,p.x)/r)*r+r*.5;
  return (vec2(cos(a),sin(a))*s-p)*rot(-a-PI*.5);
}

float wsaw(float x){return fract(x*.5+.5)*2.-1.;}
float wtri(float x){return abs(2.*fract(x*.5-.25)-1.)*2.-1.;}
float utri(float x){return abs(2.*fract(x*.5-.5)-1.);}
float wtrz(float x,float w){return clamp(wtri(x*2.)*w,-1.,1.);} // 台形波 trapezoidal wave

// ease
float o2(float t){t=1.-t;return 1.-t*t;}
float oN(float t,float n){return 1.-pow(1.-t,n);}

float dot2(vec2 p){return dot(p,p);}

vec2 mSimplePerspective(vec2 p){p.y+=.2;p.y*=3.;return p;}

float ring(vec2 p,float t){
  float alpha =    fract(-t);
  float l = 0.;
  vec2 p3=mPoly(p*rot(PI*.5),10.,1.);
  l+=saturate(gf(abs(p3.x),.03)*fill(sd(length(p),1.1+fract(t)))*(1.-fill(sd(length(p),.9+fract(t))))*alpha);
  
  l+=saturate(.02/abs(sd(length(p),1.1+fract(t)))*alpha);
  vec2 p4=mPolar(p*(.57-oN(t,1.3)*.28)).yx;
  p4.x-=.65;
  l+= saturate(abs(1./((p4.x + fbm( p4 + vec2(sin(t*.2),t*0.1))) * 50.0))*sd(dot2(tailY2x(p4+vec2(.1,0.),12.)),.9)*alpha);
  return l;
}

float summoningCircle(vec2 p){
  float l=0.;
  l+=fill(sd(lSquare(p*rot(PI/3.*1.5)*vec2(100.,1.)),1.));
  l+=fill(sd(lSquare(p*rot(PI/3.*2.5)*vec2(100.,1.)),1.));
  l+=fill(sd(lSquare(p*rot(PI/3.*3.5)*vec2(100.,1.)),1.));
  l=saturate(l);
  l-=fill(sd(lPoly(p,3.)));
  l=saturate(l);
  float r = atan(p.y,p.x);
  l+=strokeOuter(sd(length(p),.98),.008+wtrz(r/TAU*3.,12.)*.005);
  l+=strokeInner(sd(length(p),.95),.005);
  l+=strokeInner(sd(lPoly(p,3.)),.01);
  l+=strokeInner(sd(lPoly(p,3.),.88),.02);
  l+=strokeInner(sd(lPoly(p,6.),.53),.01);
  vec2 q=mPoly(p*rot(PI*.5),3.,.5);
  l+=fill(sd(lPoly(q,3.),.3));
  vec2 q2=mPoly(p*rot(PI/3.+PI*.5),3.,.7);
  l+=fill(sd(lPoly(q2,3.),.1));
  l+=strokeInner(sd(lPoly(p*rot(PI),3.),.5),.02);
  l+=fill(sd(length(p),.05));
  vec2 q3=mPoly(p*rot(PI*.5),3.,1.);
  l=saturate(l);
  l-=fill(sd(length(q3),.2));
  l=saturate(l);
  l+=strokeInner(sd(length(q3),.18),.005);
  l+=strokeInner(sd(length(q3),.15),.005);
  l+=strokeStar(q3*rot(PI)*7.,6.,.1);
  return l;
}

float render(vec2 p){
  p=mSimplePerspective(p);
  p*=rot(time);
  p*=2.;
  float tt = time*.75;
  float l2 = ring(p,o2(fract(tt)));
  l2+=ring(p*rot(PI/3.),o2(fract(tt+.5)));
  float l=0.;
  l = summoningCircle(p*=rot(time*1.5));
  return l+l2;
}

void main(void) {
  vec2 p = (gl_FragCoord.xy * 2.0 - resolution) / max(resolution.x, resolution.y);
  float l=0.;
  l = (render(p)+render(p+vec2(0.,1./min(resolution.x, resolution.y))))*.5;
  glFragColor = vec4(l*vec3( 0.75, 0.5, .05 )*2., 1.0);
}
