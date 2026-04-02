#version 420

// original https://www.shadertoy.com/view/3sSSD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

////////////////////////////////////////////////////////////////////////////////
// Complex atanh generating a spiral of hexagonally touching 'circles'.
////////////////////////////////////////////////////////////////////////////////

float A = 3.0, B = 17.0; // Rotation angle is atan(B,A)
float K = 1.0;          // Extra subdivisions
float scale = 2.0;
float PI = 3.14159;

// Complex functions
vec2 cmul(vec2 z, vec2 w) {
  return mat2(z,-z.y,z.x)*w;
}

vec2 cinv(vec2 z) {
  float t = dot(z,z);
  return vec2(z.x,-z.y)/t;
}

vec2 cdiv(vec2 z, vec2 w) {
  return cmul(z,cinv(w));
}

vec2 clog(vec2 z) {
  float r = length(z);
  return vec2(log(r),atan(z.y,z.x));
}

// Inverse hyperbolic tangent 
vec2 catanh(vec2 z) {
  return 0.5*clog(cdiv(vec2(1,0)+z,vec2(1,0)-z));
}

// Iq's hsv function, but just for hue.
vec3 h2rgb(float h ) {
  vec3 rgb = clamp( abs(mod(h*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
  return rgb*rgb*(3.0-2.0*rgb); // cubic smoothing    
}

// Shane's distance function showing the hexagonal cells.
float dist(vec2 p){
  float d0 = length(p);
  p = abs(p);
  float d1 = max(p.y*.8660254 + p.x*.5, p.x) + .025;
  return mix(d0,d1,0.5-0.5*cos(time));
}

void main(void) {
  float X = sqrt(3.0);
  vec2 z = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
  z *= scale;

  /*
  if (mouse*resolution.xy.x > 0.0) {
    // Get angle from mouse position
    vec2 m = (2.0*mouse*resolution.xy.xy-resolution.xy)/resolution.y;
    m *= 20.0;
    A = floor(m.x), B = floor(m.y);
  }
  */

  vec2 rot = normalize(vec2(X*A,B));
  //z = clog(z);
  z = 2.0*catanh(z);
  z = cmul(rot,z);
  z *= K*sqrt(X*X*A*A+B*B)/PI; // Alignment
  z += time*vec2(1,0);
  // Divide into regions, 2 across, 2*sqrt(3) high
  z.y /= X;
  vec2 index = round(z);
  z -= index;
  z.y *= X;
  // z now relative to centre of region
  vec2 P = vec2(1,X); // upper right corner of region
  // Alternate regions are reversed left to right
  bool flip = mod(index.x + index.y, 2.0) == 0.0;
  if (flip) z.x = -z.x;
  bool lower = dot(z,P) < 0.0;
  // Adjust indexes
  if (flip == lower) index.x++;
  if (lower) index.y--;
  // Lower half of region has circle centred on lower left corner
  //float r = lower ? distance(-0.5*P,z) : distance(0.5*P,z);
  float r = lower ? dist(-0.5*P - z) : dist(0.5*P - z);
  float h = index.y/(2.0*K*(A==0.0 ? 1.0 : A)); // Color for row
  vec3 col = h2rgb(h);
  col = mix(col,vec3(0.1),r);
  float eps = 0.01;
  col = mix(col,vec3(0.25),smoothstep(1.0-eps,1.0+eps,r));
  // Uncomment next line to see fundamental regions
  //col *= 0.8+0.2*smoothstep(0.05-eps,0.05+eps,min(0.5-abs(z.x),0.5*X-abs(z.y)));
  glFragColor = vec4(col,1);
}
