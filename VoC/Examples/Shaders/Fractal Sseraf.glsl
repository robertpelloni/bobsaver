#version 420

// original https://www.shadertoy.com/view/Ns2Gz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Inspired by:
// - https://www.shadertoy.com/view/MdKyRw kaleidoscopic iterative function by wyatt
// - https://www.shadertoy.com/view/ldB3Rz larval by P_Malin

#define FAITHFUL true

const int Steps = FAITHFUL? 24 : 36;  // accuracy
const int Iterations = FAITHFUL? 16 : 20;  // shape detail
const float Eps = FAITHFUL? 1./16. : 1./64.;  // shading precision

float C3,S3,C2,S2,C1,S1;
float trap;

float map(vec3 p) {
  float len, t = 0.25;
  trap = 0.25;
  for (int i=0; i<Iterations; i++) {
    p.xz = S3*p.xz + C3*vec2(-1.,1.)*p.zx; p = p.yzx;
    p.xz = S2*p.xz + C2*vec2(-1.,1.)*p.zx; p = p.yzx;
    p.xz = S1*p.xz + C1*vec2(-1.,1.)*p.zx; p = p.yzx;
    p.xy = -abs(p.xy);
    len = -(min(min(p.x, p.y), -abs(p.z)));  // box distance
    trap = max(trap,len);
    p.xy += vec2(t, t*.25);
    t *= 0.75;
  }
  return len - 2.*t;
}

// Step along the ray. Return the position of the hit.
float last_dist;
vec3 trace(vec3 pos, vec3 dir) {
  last_dist = 0.;
  for (int i=0; i<Steps; i++) {
    pos += dir * last_dist;
    last_dist = map(pos);
  }
  return pos;
}

void main(void) {
  vec2 v = (gl_FragCoord.xy - .5*resolution.xy) / resolution.y;  // v.y: -0.5..0.5
  if (FAITHFUL) { v = floor(v*200.) / 200.; }  // quantize height to 200 pixels
  v.y = -v.y;
  v *= 0.78125298 / 0.5;

  float time = -0.234375*time;
  float t = time;     S1 = sin(t); C1 = cos(t);
  t = time/log(2.);   S2 = sin(t); C2 = cos(t); // t*1.4427
  t = time/log2(10.); S3 = sin(t); C3 = cos(t); // t*0.30103

//  vec3 p = trace(vec3(0.,0.,4.), normalize(vec3(v,-4.)));  // perspective
  vec3 p = trace(vec3(v,1.), vec3(0.,0.,-1.));  // no perspective

  float hue = min(trap, 1.);  // orbit trap
  if (FAITHFUL) { hue = round(hue*32.) / 32.; }  // quantize to about 32 hues

  float bri = (map(p+vec3(0.,0.,Eps)) - last_dist) / Eps;  // ao, brightness: smoothed normal.z
  if (FAITHFUL) { bri = round(bri*8.) / 8.; }  // quantize to about 8 brightness levels

  if (p.z<-1. || bri<0.) { glFragColor = vec4(0.,0.,0.,1.); }
  else {
    float spe = 0.5*pow(bri,8.);  // shiny
    if (FAITHFUL) { spe = 0.; }

    glFragColor = vec4(spe+bri*vec3(1.,hue,0.), 1.);  // flame
//    glFragColor = vec4(spe+bri*vec3(0.125,hue,float(0xc8)/256.), 1.);  // sky
//    glFragColor = vec4(spe+bri*vec3(1.,.3+.6*hue,.25+.5*hue), 1.);  // brain
//    glFragColor = vec4(spe+bri*vec3(1.-hue,.25,1.), 1.);  // alien
//    glFragColor = vec4(spe+bri*vec3(1.,.75+hue*.25,.25+hue*.5), 1.);  // platinum
//    glFragColor = vec4(spe+bri*vec3(hue*hue,.25+hue*.75,.75-hue*.25), 1.);  // anodized titanium
  }
}
