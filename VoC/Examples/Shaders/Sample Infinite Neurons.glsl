#version 420

// original https://www.shadertoy.com/view/clj3Wz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float D_MAX = 30.0;  // max marching distance

#define PI 3.1416
#define AA 1  // number of anti-aliasing passes

// SDF Transforms

float intersectSDF(float distA, float distB) {
  return max(distA, distB);
}

float unionSDF(float distA, float distB) {
  return min(distA, distB);
}

float differenceSDF(float distA, float distB) {
  return max(distA, -distB);
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); 
}

// SDFs

float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdOctahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sceneSDFnoRep(vec3 samplePoint) {    
  //return sdBox(samplePoint, vec3(0.05, 0.05, 0.5));
  float smallEdge = 0.01;
  float s1 = sdBox(samplePoint, vec3(smallEdge, smallEdge, 0.25));
  float s2 = sdBox(samplePoint, vec3(0.25, smallEdge, smallEdge));
  float s3 = sdBox(samplePoint, vec3(smallEdge, 0.25, smallEdge));
  float s123 = unionSDF(s1, unionSDF(s2, s3));
  float s4 = sdOctahedron(samplePoint, 0.09);
  // float s4 = sdSphere(samplePoint, 0.2);

  return opSmoothUnion(s123, s4, 0.03);
}

// Repeat SDF infinitely
// c is ~size of repeated unit
float opRep( in vec3 p, in vec3 c){
  vec3 q = mod(p+0.5*c,c)-0.5*c;
  return sceneSDFnoRep( q );
}

// Scene SDF
float sceneSDF(vec3 samplePoint) {    
  return opRep(samplePoint, vec3(0.5));
}

// Calculates surface normal
vec3 calcNormal( in vec3 pos ) {
  vec2 e = vec2(1.0,-1.0)*0.5773;
  const float eps = 0.0005;  // small increment epsilon
  return normalize( e.xyy*sceneSDF( pos + e.xyy*eps ) + 
          e.yyx*sceneSDF( pos + e.yyx*eps ) + 
          e.yxy*sceneSDF( pos + e.yxy*eps ) + 
          e.xxx*sceneSDF( pos + e.xxx*eps ) );
}

// Apply fog
vec3 applyFog( in vec3  rgb,       // original color of the pixel
               in float dist,     // camera to point distance
               in float distFactor) {
  float fogAmount = 1.0 - exp( -dist * distFactor );
  vec3  fogColor  = vec3(0.0, 0.0, 0.0);
  return mix( rgb, fogColor, fogAmount );
}

void main(void) {
  // camera movement    
    // float angle = 0.25 * PI * time + 0.75 * PI;
    // vec3 eye = vec3( 1.2*cos(angle), 0.4, 1.2*sin(angle) );
  // vec3 center = vec3( 0.0, 0.0, 0.0 );
    vec3 eye = vec3( 1.0 - time, 0.25, -0.25 + time );
  vec3 center = vec3( 0.0  - time, 0.25, 0.75  + time );
  // camera matrix
  vec3 ww = normalize( center - eye );  // vect from center to eye
  vec3 uu = normalize( cross(ww, vec3(0.0,1.0,0.0)) );  // cross with up
  vec3 vv = normalize( cross(uu, ww) );

  vec3 tot = vec3(0.0);
  
  #if AA>1  // anti-aliasing passes
  for( int m=0; m<AA; m++ )
  for( int n=0; n<AA; n++ ) {
    // pixel coordinates
    vec2 offset = vec2(float(m),float(n)) / float(AA) - 0.5;  // offset for anti-aliasing passes
    vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+offset))/resolution.y;
    #else    
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    #endif

    // create view ray
    vec3 ray = normalize( p.x*uu + p.y*vv + 1.5*ww );

    // raymarch
    float dTot = 0.0;
    for( int i=0; i<256; i++ ) {
      vec3 pos = eye + dTot*ray;
      float d = sceneSDF(pos);
      if( d < 0.0001 || dTot > D_MAX ) break;
      dTot += d;
    }
    
    // shading/lighting    
    vec3 color = vec3(0.0);
    if( dTot < D_MAX ) {
      vec3 pos = eye + dTot * ray;  // position of point on surface
      vec3 normal = calcNormal(pos);  // surface normal
      float diffuse = clamp( dot(normal, vec3(0.5)), 0.0, 1.0 );
      float ambient = 0.5 + 0.5 * dot(normal, vec3(0.0,1.0,0.0));
      //color = vec3(0.7, 0.7, 0.7) * ambient + vec3(3.0/255.0, 44.0/255.0, 252.0/255.0) * diffuse;
      color = vec3(3.0/255.0, 44.0/255.0, 252.0/255.0) * ambient + vec3(0.7, 0.7, 0.7) * diffuse;

      color = applyFog(color, dTot, 0.3);
    }

    // gamma        
    color = sqrt( color );
    tot += color;
    #if AA>1
  }
  tot /= float(AA*AA);  // take mean if multiple anti-aliasing passes
  #endif

    glFragColor = vec4( tot, 1.0 );
}
