#version 420

// original https://www.shadertoy.com/view/3tc3zN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by mrange/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Technique from: https://www.shadertoy.com/view/4slGWH

// Messed around with cogwheels distance functions and applied it the IQ's Fractal Nyancat 

#define PI  3.141592654
#define TAU (2.0*PI)

const float cogRadius = 0.02;
const float smallWheelRadius = 0.30;
const float bigWheelRadius = 0.55;
const float wheelOffset = smallWheelRadius + bigWheelRadius -cogRadius;
const vec3 baseCol = vec3(240.0, 115.0, 51.0)/vec3(255.0);

float mod1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize, size) - halfsize;
  return c;
}

float modMirror1(inout float p, float size) {
  float halfsize = size*0.5;
  float c = floor((p + halfsize)/size);
  p = mod(p + halfsize,size) - halfsize;
  p *= mod(c, 2.0)*2.0 - 1.0;
  return c;
}

vec2 toPolar(vec2 p) {
  return vec2(length(p), atan(p.y, p.x));
}

vec2 toRect(vec2 p) {
  return vec2(p.x*cos(p.y), p.x*sin(p.y));
}

float unevenCapsule(vec2 p, float r1, float r2, float h) {
  p.x = abs(p.x);
  float b = (r1-r2)/h;
  float a = sqrt(1.0-b*b);
  float k = dot(p,vec2(-b,a));
  if( k < 0.0 ) return length(p) - r1;
  if( k > a*h ) return length(p-vec2(0.0,h)) - r2;
  return dot(p, vec2(a,b) ) - r1;
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

void rot(inout vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  p = vec2(p.x*c + p.y*s, -p.x*s + p.y*c);
}

float softMin(float a, float b, float k) {
  float res = exp( -k*a ) + exp( -k*b );
  return -log( res )/k;
}

float smallCogwheel(vec2 p) {
  rot(p, -time*2.0 + TAU/32.0);
  vec2 op  = p;
  float dc = circle(p, 0.25);  
  vec2 pp = toPolar(p);
  mod1(pp.y, TAU/16.0);
  pp.y += PI/2.0;
  vec2 cp = toRect(pp);
  float ds = unevenCapsule(cp, 0.05, cogRadius, smallWheelRadius);
  float dcw = softMin(ds, dc, 100.0);
  float dic = circle(p, 0.125/2.0);
  pp = toPolar(p);
  mod1(pp.y, TAU/6.0);
  vec2 ip = toRect(pp);
  float dic2 = circle(ip - vec2(0.15, 0.0), 0.125/2.0);
  float di = min(dic, dic2);
  return max(dcw, -di);
}

float bigCogwheel(vec2 p) {
  rot(p, time);
  vec2 op  = p;
  float dc = circle(p, 0.5);  
  vec2 pp = toPolar(p);
  mod1(pp.y, TAU/32.0);
  pp.y += PI/2.0;
  vec2 cp = toRect(pp);
  float ds = unevenCapsule(cp, 0.1, cogRadius, bigWheelRadius);
  float dcw = softMin(ds, dc, 100.0);
  float dic = circle(p, 0.125);
  pp = toPolar(p);
  mod1(pp.y, TAU/6.0);
  vec2 ip = toRect(pp);
  float dic2 = circle(ip - vec2(0.3, 0.0), 0.125);
  float di = min(dic, dic2);
  return max(dcw, -di);
}

float cogwheels(vec2 p) {
  p.x += wheelOffset*0.5;
  float dsc = smallCogwheel(p - vec2(wheelOffset, 0.0));
  float dbc = bigCogwheel(p);
  return min(dsc, dbc);
}

float df(vec2 p) {
  float i = modMirror1(p.x, wheelOffset);
  float sy = mix(1.0, -1.0, mod(i, 2.0));
  p.y *= sy;
  float dcs = cogwheels(p);
  return dcs;
}

vec4 sample_(vec2 p) {
  const float borderStep = 0.001;
  vec3 col = baseCol;  
  p *= 4.0;
  float d = df(p);
  float t = smoothstep(-borderStep, 0.0, -d);
  t *= exp(-dot(p, p)*0.005);
  return vec4(col, t);
}

vec3 saturate(vec3 col) {
  return clamp(col, 0.0, 1.0);
}

vec3 postProcess(in vec3 col, in vec2 q)  {
  col = saturate(col);
  col=pow(clamp(col,0.0,1.0),vec3(0.75)); 
  col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
  col=mix(col, vec3(dot(col, vec3(0.33))), -0.4);  // satuation
  col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
  return col;
}

void main(void) {
  vec2 q = gl_FragCoord.xy/resolution.xy;
  vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;

  p = vec2(0.5, -0.05) + p*0.75*pow(0.9, 20.0*(0.5+0.5*cos(0.3*sqrt(2.0)*time*sqrt(0.5))));

  vec4 col = vec4(0.0);
  vec3 ss = mix(vec3(0.2, 0.2, 0.5), vec3(0.2,-0.2,1.0), 2.2 + 1.25*sin(time*0.5));

  vec2 c = vec2(-0.76, 0.15);
  rot(c, 0.2*sin(time*sqrt(3.0)/12.0));
  float f = 0.0;
  vec2 z = p;

  float transparency = 1.0;

  vec3 bg = vec3(0.0);

  float minTrap = 10000.0;

  const int maxIter = 100;
  const float maxIterF = float(maxIter);
  for(int i=0; i<=maxIter; ++i)
  {
    float re2 = z.x*z.x;
    float im2 = z.y*z.y;
    if((re2 + im2>4.0) || (transparency<0.1)) break;
    float reim = z.x*z.y;

    z = vec2(re2 - im2, 2.0*reim) + c;
    minTrap = min(minTrap, length(z - c));

    float fi = f/maxIterF;
    float shade = pow(1.0-0.5*fi, 1.5);

    vec4 sample_ = sample_(ss.xy + ss.z*z);
    float ff = mix(0.0, 0.5, pow(fi, 0.5));
    sample_.xyz = pow(sample_.xyz, mix(vec3(1.0), vec3(75.0, 0.5, 0.0), ff));
    sample_.xyz = mix(bg, sample_.xyz, shade);

    transparency *= 1.0 - clamp(sample_.w, 0.0, 1.0);
    vec4 newCol = vec4(col.xyz + sample_.xyz*(1.0 - col.w)*sample_.w, 1.0 - transparency);

    col = newCol;
    
    f += 1.0;
  }
  
  bg= vec3(0.3, 0.25, 0.4)*max(0.5 - sqrt(minTrap), 0.0);
  col.xyz = mix(bg, col.xyz, col.w);
  float fade = smoothstep(0.0, 3.0, time);
  glFragColor = vec4(fade*postProcess(col.xyz, q), 1.0);
}
