#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/fsBGRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
//
// Triangular numbers & complete graphs
// Matthew Arcus, mla, 2021
//
// Colour a complete graph with n nodes with n-1 colours, with i nodes being
// coloured by the ith colour.
//
// https://twitter.com/MatthewArcus/status/1378683514795790340
//
////////////////////////////////////////////////////////////////////////////////

float PI = 3.14159265;

// Distance squared of p from line segment qr.
float segment2(vec2 p, vec2 q, vec2 r) {
  p -= q; r -= q;
  float h = dot(p,r)/dot(r,r);
  h = clamp(h,0.0,1.0);
  p -= h*r;
  return dot(p,p);
}

// From Chris Wellons: https://nullprogram.com/blog/2018/07/31/
uint ihash(uint x) {
    x ^= x >> 16;
    x *= 0x7feb352dU;
    x ^= x >> 15;
    x *= 0x846ca68bU;
    x ^= x >> 16;
    return x;
}

vec3 hsv2rgb(float h, float s, float v) {
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  rgb = rgb*rgb*(3.0-2.0*rgb); // cubic smoothing       
  return v * mix( vec3(1.0), rgb, s);
}

// Rotate vector p by angle t.
vec2 rotate(vec2 p, float t) {
  return cos(t)*p + sin(t)*vec2(-p.y,p.x);
}

vec3 diagram(vec2 p) {
  float N = 5.0+floor(0.5*time)+max(0.0,2.0*fract(0.5*time)-1.0);
  p = rotate(p,0.01); // Rotate slightly to reduce artefacts
  float lwidth = fwidth(p.x);
  vec3 col = vec3(0); //1.0-vec3(1,1,0.8);
  if (dot(p,p) > 1.0+lwidth) return col;
  float d2min = 1e8, rmin;
  float offset = 0.5*(N-1.0);
  for (float i = 0.0, j = 1.0; j < N; ) {
    float ii = 2.0*PI/N*(i-offset);
    float ij = 2.0*PI/N*(j-offset);
    vec2 q = vec2(sin(ii),cos(ii));
    vec2 r = vec2(sin(ij),cos(ij));
    float d2 = segment2(p,q,r);
    if (d2 < d2min) {
      d2min = d2;
      rmin = (abs(i-j)-1.0)/(N-1.0);
    }
    vec2 n = r-q;
    if (dot(p-q,vec2(-n.y,n.x)) > 0.0) i++;
    else j++;
  }
  col = mix(hsv2rgb(rmin,1.0,1.0),col,smoothstep(0.0,lwidth,sqrt(d2min)));
  return col;
}

void main(void) {
  vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
  //if (mouse*resolution.xy.z > 0.0) {
  //  vec2 mouse = (2.0*mouse*resolution.xy.xy-resolution.xy)/resolution.y;
  //  p -= mouse; // Centre on mouse
  // p *= 0.55*resolution.y/resolution.x; // And zoom
  //}
  vec3 col = diagram(p);
  glFragColor = vec4(pow(col,vec3(0.4545)),1);
}
