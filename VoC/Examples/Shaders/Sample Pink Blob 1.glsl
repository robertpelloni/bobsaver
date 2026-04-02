#version 420

// original https://www.shadertoy.com/view/fldyz7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Heavily adapted from Inigo Quilez (https://iquilezles.org/)

const float D_MAX = 5.0;  // max marching distance

#define PI 3.1416

// SDFs

float sdSphere( vec3 p, float s ) {
  return length(p)-s;
}

// Scene SDF
float sceneSDF(vec3 p) {    
  // return sdSphere(samplePoint, 0.5);
  float d1 = sdSphere(p, 0.5);

  float df = 8.0;  // frequency
  float da = 0.1;  // amplitude
  float d2 = da * sin(df * (p.x + 0.25*PI*time))*sin(df * p.y)*sin(df * p.z);

  return d1 + d2;
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

#define AA 2  // number of anti-aliasing passes

void main(void)
{
  // camera movement    
    // float angle = 0.25 * PI * u_time + 0.75 * PI;
    // vec3 eye = vec3( 1.2*cos(angle), 0.4, 1.2*sin(angle) );
  // vec3 center = vec3( 0.0, 0.0, 0.0 );
    vec3 eye = vec3( 1., 0.4, -1.);
  vec3 center = vec3( 0., 0., 0.);
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
      float diffuse = clamp( dot(normal, vec3(0.6)), 0.0, 1.0 );
      float ambient = 0.5 + 0.5 * dot(normal, vec3(0.0,1.0,0.0));
      color = vec3(0.5882, 0.302, 0.302) * ambient + vec3(0.098, 0.1843, 0.5882) * diffuse;
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
