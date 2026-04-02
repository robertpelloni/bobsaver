#version 420

// original https://www.shadertoy.com/view/wsjGzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise( vec2 v ) {
  return fract( sin ( dot( v , vec2( 78.123 , 36.1226 ) ) ) * 64.314 );
}

float pnoise( vec2 uv ) {

  vec2 a = fract( uv );
  a = a * a * ( 3. - 2. * a );

  //dirc
  vec2 uv2 = floor( uv );
  float w0 = noise ( uv2 ) ;
  float w1 = noise ( uv2 + vec2( 1. , 0. ) ) ;
  float w2 = noise ( uv2 + vec2( 0. , 1. ) ) ;
  float w3 = noise ( uv2 + vec2( 1. , 1. ) ) ;

  float g0 = dot( vec2(w0) , ( a - vec2(0.,0.) ) ) ;
  float g1 = dot( vec2(w1) , ( a - vec2(1.,0.) ) ) ;
  float g2 = dot( vec2(w2) , ( a - vec2(0.,1.) ) ) ;
  float g3 = dot( vec2(w3) , ( a - vec2(1.,1.) ) ) ;

  float h0 = mix( g0 , g1 , a.x );
  float h1 = mix( g2 , g3 , a.x );
  float h2 = mix( h0 , h1 , a.y );

  float h = h2 + .1;

  return h;
}

float fbm( vec2 uv ) {
  float a = pnoise( uv );
  a += pnoise( uv * 2. ) * 0.5 ;
//  a += pnoise( uv * 4. ) * 0.25 ;
//  a += pnoise( uv * 8. ) * 0.125 ;
//  a += pnoise( uv * 16. ) * 0.0625 ;
  a += pnoise( uv * 32. ) * 0.03125 ;
  return a;
}

mat4 createVTW(vec3 eye,vec3 center,vec3 up) {
  vec3 f = normalize( center - eye );
  vec3 s = normalize( cross(f,up) );
  vec3 u = cross(s,f);
  return mat4(
    vec4(s,0.),
    vec4(u,0.),
    vec4(-f,0.),
    vec4(0.,0.,0.,1)
  );
}

vec3 rayDirection(float fieldofView,vec2 size) {
  vec2 xy = gl_FragCoord.xy - size / 2.0;
  float z = size.y / tan(radians(fieldofView) / 2.0 );
  return normalize(vec3(xy,-z));
}

float sdf( vec3 p ) {
    float h = fbm( p.xz ) * .5 + .2;
    vec3 p2 = vec3( p.x , h , p.z );

    float l = p.y - p2.y;
    return l;
}

vec3 createnormal(vec3 p) {
  float e = 0.001;
  return normalize( vec3(
    sdf( vec3(p.x+e,p.y,p.z) ) - sdf( vec3(p.x-e,p.y,p.z) ) ,
    sdf( vec3(p.x,p.y+e,p.z) ) - sdf( vec3(p.x,p.y-e,p.z) ) ,
    sdf( vec3(p.x,p.y,p.z+e) ) - sdf( vec3(p.x,p.y,p.z-e) )
  ));

}

vec4 render( vec2 uv , vec3 eye , vec3 dir ) {

  float len = 0.;
  vec3 lightVec = vec3(1.,1.,1.);
  vec3 lightColor = vec3( 0.7 , 0.5, 0.3 );

  for ( int i = 0 ; i < 80 ; ++ i ) {
    vec3 p = eye + dir * len;

    float l = sdf( p );
    len += length( l ) ;

    if ( l < 0.01 ) {
      vec3 n = createnormal( p );
      float light = dot ( n , lightVec );
      float sp = fbm( p.xz * .6 + time * .5 ) * 4.;
      return vec4( vec3( light ) * sp * lightColor + vec3( 0.3,0.2,0.15) , 1. );
    }

  }

  return vec4( 0. , 0. , 0. , 1. );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy * (1.0/resolution.x) - vec2(0.5, 0.5);

    float t = time * .1;
    vec3 eye = vec3( cos(t) * 5. , 2. , sin(t) * 5. );
   // vec3 eye = vec3( 5. , 5. , 5. );
    vec3 center = vec3(0.,0.5,0.);
    vec3 up = vec3(0.,1.,0.);
    mat4 vtw = createVTW(eye,center,up);

    vec3 viewDir = rayDirection(45.,resolution.xy);
    vec3 worldDir = (vtw * vec4(viewDir,0.)).xyz;

   glFragColor = render( uv , eye , worldDir );
}
