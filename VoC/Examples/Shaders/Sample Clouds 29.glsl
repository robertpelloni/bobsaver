#version 420

// original https://www.shadertoy.com/view/3d23Ww

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(vec3 uv) {
  return fract( sin( dot( uv ,vec3(123.,65.,44.) ) ) * 4811.424 );
}

float pnoise(vec3 uv,float f) {

  vec3 t = uv * f;
  vec3 v1 = floor(t);
  vec3 v2 = fract(t);

  float a0 = hash(v1 + vec3(0.,0.,0.));
  float b0 = hash(v1 + vec3(1.,0.,0.));
  float c0 = hash(v1 + vec3(0.,1.,0.));
  float d0 = hash(v1 + vec3(1.,1.,0.));

  float a1 = hash(v1 + vec3(0.,0.,1.));
  float b1 = hash(v1 + vec3(1.,0.,1.));
  float c1 = hash(v1 + vec3(0.,1.,1.));
  float d1 = hash(v1 + vec3(1.,1.,1.));

  float o1 = mix(a0,b0,v2.x);
  float o2 = mix(c0,d0,v2.x);
  float o3 = mix(o1,o2,v2.y);

  float o4 = mix(a1,b1,v2.x);
  float o5 = mix(c1,d1,v2.x);
  float o6 = mix(o4,o5,v2.y);

  float o7 = mix(o3,o6,v2.z);
  
  return o7;
}

float fbm(vec3 uv) {
  float o = 0.;
  float n = 1.;
  float f = 2.5;
  
  for ( int i = 0 ; i < 4 ; ++ i ) {
    o += pnoise( uv , f ) * n ;
    f *= 2.; 
    n *= 0.5;
  }

  return o ;
}

float map( in vec3 p )
{
  float f = fbm( p * 0.7 + sin(time * 0.1) ) ;
  float s1 = cos( f * 4.5);
    return min( max(0.0, s1 ), 1.0 );
}

float sdf(vec3 p) {
  
  float l0 = dot ( p , vec3(0.,1.,0.));
  float l1 = length( p ) - 3.0;
  float l2 = max( -l0 , l1 );

  if ( l2 < 0.01 ) {
    float CLOUD_DENSITY = 5.5;
    return map( p ) * CLOUD_DENSITY ;
  }

  return 0.;
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

vec4 render( vec2 uv , vec3 eye , vec3 worldDir ) {

  vec3 sky = vec3(0.1 - uv.y ,0.0,0.7 + uv.y ) ;

  vec3 cloudColor = vec3( 1.0 , 1.0 , 1.0 );
  vec3 lightVec = normalize ( vec3( 0.5 , 1. , 0.5 ) );

  int steps = 40;
  int shadowSteps = 30;

  float invSteps = 1. / float(steps);
  float invShadowSteps = 1. / float(shadowSteps);
  float stepDistance = 2. * invSteps;
  float shadowStepSize = 2. * invShadowSteps;

  vec3 lightColor = vec3(0.,0.,0.);
  float lightPower = 1.;

  float dist = length ( eye ) - 1.2;
  vec3 start = worldDir * dist ;
  vec3 CurPos = eye + start ;
  int flg = 0;
  for(int I=0;I<steps;++I) {

    float cursample = sdf( CurPos ) * 3.;
    if ( cursample > 0.01 ) {

      vec3 lpos = CurPos;

      float shadowDist = 0.;
      for ( int S = 0 ; S< shadowSteps ; ++S ) {
        lpos += lightVec * shadowStepSize ;
        float lsample = sdf( lpos );
        shadowDist += lsample;
      }

      float curdensity = clamp( cursample * invSteps , 0. , 1. );
      lightColor += exp( - shadowDist * invShadowSteps ) * curdensity * cloudColor * lightPower;
      lightPower *= (1. - curdensity) ;
      
      if ( lightPower < 0.001 ) {
        break;
      }
    }

    CurPos += worldDir * stepDistance;
  }

  vec3 o = sky + lightColor ;
  return vec4( o , 1. );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy * (1.0/resolution.x) - vec2(0.5, 0.5);

    float t = time * .5;
    vec3 eye = vec3( cos(t) * 5. , 3.2 , sin(t) * 5. );

    vec3 center = vec3(0.,0.,0.);
    vec3 up = vec3(0.,1.,0.);
    mat4 vtw = createVTW(eye,center,up);

    vec3 viewDir = rayDirection(90.,resolution.xy);
    vec3 worldDir = (vtw * vec4(viewDir,0.)).xyz;

    glFragColor = render( uv , eye , worldDir );
}
