#version 420

// original https://www.shadertoy.com/view/WscXD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Raka
// by @Alien01_
// My first entry. 2nd place at inercia2019 one scene compo.

#define PI 3.141592

// From IQ's website
// https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float torus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}
// Also IQ's
float smin( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

mat2 rot(float a){
  return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float sphere(vec3 p, float r){
  return length(p) - r;
}

float square(vec2 uv, float r){
  float a = step(uv.x, r/2.) - step(uv.x, -r/2.);
  float b = step(uv.y, r/2.) - step(uv.y, -r/2.);
  float c = a*b;
  return c;
}

float gridShape(vec2 uv, float r){
  return square(uv, r * 2.0);
}

float map(vec3 p, float time){
  vec3 pt = p;
  pt.yz *= rot((time * 0.5));
  pt.xy *= rot(cos(time * 0.5 * PI));
  pt.xy *= rot(0.5);
  pt.yz *= rot(1.0);
  pt.yz *= rot(PI/2.0);
  float t = torus(pt, vec2(2.0, 0.5 * cos(time)));
  vec3 ps1 = pt;
  ps1.xz *= rot( time);
  ps1.y -= 1.5 * cos(time * 2.0);
  ps1.x -= 0.5;
  float s1 = sphere(ps1, 0.5);
  vec3 ps2 = pt;
  ps2.xz *= rot( time);
  ps2.y -= 1.5 * sin(time * 2.0);
  ps2.x += 0.5;
  float s2 = sphere(ps2, 0.5);
  float s = smin(s2, s1, 2.0);
  return smin(t,s, 0.3);
}

vec3 trace(vec2 uv, float time){
  vec3 ro = vec3(0.0, 0.0, -5.0);
  vec3 rd = normalize(vec3(uv, 1.0));
  vec3 p = ro+rd;
  float t = 0.;
  int i = 0;
  int iter = 64;
  float d = 0.0;
  for(i=0; i<iter; i++){
      d = map(p, time);
      t += d;
      p += rd*d;
      if(t > 100. ){
        return vec3(0);
      }
      else if( d < 0.1){
      return vec3(1.0-p.z);
    }
  }
}

void main(void)
{
  
  float gTime = time;
  gTime *= 0.4;
  
  vec2 uv = gl_FragCoord.xy/resolution.xy;
  
  uv.x -= 0.4;
  uv.y -= 0.4;
  uv *= 1.2;
  uv /= vec2(resolution.y / resolution.x, 1);
  
  vec2 uv1 = uv;

  float d = trace(uv, time).x;
  d = smoothstep(d, 0.0, abs(cos(time)));
 
  uv.yx *= rot(0.2 * gTime);
  vec3 color = vec3(0.0);
  
  vec2 st = fract(uv * 15.) - 0.5;
  vec2 stid = floor(uv) + 0.5;  
  
  
  st *= rot(d);
  color += 0.9*gridShape(st, d*0.16);
  color += 0.5*gridShape(st, 0.4);
  
  
  color *= mix(square(uv, 0.9), 0.8, d);  
  uv /= 2.0;
  
  vec2 id = ceil(uv) - 0.5;
  id *= rot( 0.5 * gTime * PI);
  color += 0.5*gridShape(id, 0.4 );
  
  if ( id.y + id.x - 0.3  <  uv.y ){  
    color = 1.0-color.zxy;
  }

  color.r *= 2.0;
  color += vec3(0.2, 0.0, 0.4);
  color *= 1.-dot(uv1,uv1) ;
  glFragColor = vec4(color,1.0);
  
}

