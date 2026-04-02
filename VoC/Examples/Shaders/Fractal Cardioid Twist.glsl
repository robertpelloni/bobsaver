#version 420

// original https://www.shadertoy.com/view/4fSBzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 center = vec2(0.,0.);
float radius = 1.5;
float angle = radians(0.);

const float pi = radians(180.);

float abs2(vec2 z) {
  return dot(z,z);
}
float arg(vec2 z) {
  return atan(z.y, z.x);
}
vec2 cmul(vec2 a, vec2 b) {
  return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x);
}
vec2 cdiv(vec2 a, vec2 b) {
  return vec2(dot(a,b), a.y*b.x-a.x*b.y)/abs2(b);
}
vec2 cinv(vec2 b) {
  return vec2(b.x, b.y)/abs2(b);
}
vec2 cexp(vec2 z) {
  float e = exp(z[0]);
  return vec2(e*cos(z[1]), e*sin(z[1]));
}
vec2 cln(vec2 z) {
  return vec2(log(sqrt(abs2(z))), arg(z));
}
vec2 cpow(vec2 b, vec2 e) {
  return cexp(cmul(e,cln(b)));
}
vec2 csqrt(vec2 z) {
  return cpow(z, vec2(.5,0.));
}

// https://github.com/hughsk/glsl-hsv2rgb/blob/master/index.glsl
vec3 hsv2rgb(in vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

// coloring:
vec4 phase(vec2 z) {
  return hsv2rgb(vec3(arg(z)/pi, 1., 1.)).xyzz;
}
vec4 axies(vec2 z) {
  float t = arg(z)/pi;
  float a = mod(2.*t+2., 2.)-1.;
  a = abs(2.*a)-1.;
  a = asin(a)/pi+.5;
  return vec4(a,a,a, 1.);
}
vec4 icolor(int i) {
  float x = float(i);
  return vec4(sin(x*100.), sin(x*200.), sin(x*300.), 0.);
}
vec4 black = vec4(0., 0., 0., 1.);
vec4 white = vec4(1., 1., 1., 1.);

vec2 p2c(vec2 p) {
  vec2 wh2 = resolution.xy/2.;
  float pr = min(wh2.x, wh2.y);
  vec2 c = (p - wh2)/pr;
  vec2 r = radius * vec2(cos(angle), sin(angle));
  return cmul(r,c) + center;
}

vec4 f(vec2 c) {
  int n = 1000;
  const vec2 one = vec2(1.,0.);
  float di = 1.5*(1.+cos(time/3.));
  c = cinv(csqrt(one-4.*c)) - vec2(0.,di);
  c = 0.25*(one-cinv(cmul(c,c)));
  vec2 z = c;
  vec2 dz = vec2(0.,0.);
  vec2 phi = z;
  for(int i=0; i<n; ++i) {
    dz = 2.*cmul(z,dz);
    z = cmul(z,z)+c;
    vec2 a = cdiv(z,z-c);
    float s = pow(0.5, float(i));
    phi = cmul(phi, cpow(a, vec2(s,0.)));
    if(abs2(z) > 10000.) {
      return white*clamp(abs2(z)/pow(2.,float(i)/(1.+di)),0.,1.);
    }
  }
  return phase(z);
}

void main(void) {
  vec2 z = p2c(gl_FragCoord.xy);
  glFragColor = f(z);
}
