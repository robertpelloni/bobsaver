#version 420

// original https://www.shadertoy.com/view/WsBGDW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise(vec3 uv) {
  return fract( sin( dot( uv ,vec3(123.,65.,44.) ) ) * 4811.424 );
}

float pnoise(vec3 uv,float f) {

  vec3 t = uv * f;
  vec3 v1 = floor(t);
  vec3 v2 = fract(t);

  float a0 = noise(v1 + vec3(0.,0.,0.));
  float b0 = noise(v1 + vec3(1.,0.,0.));
  float c0 = noise(v1 + vec3(0.,1.,0.));
  float d0 = noise(v1 + vec3(1.,1.,0.));

  float a1 = noise(v1 + vec3(0.,0.,1.));
  float b1 = noise(v1 + vec3(1.,0.,1.));
  float c1 = noise(v1 + vec3(0.,1.,1.));
  float d1 = noise(v1 + vec3(1.,1.,1.));

  float o1 = mix(a0,b0,v2.x);
  float o2 = mix(c0,d0,v2.x);
  float o3 = mix(o1,o2,v2.y);

  float o4 = mix(a1,b1,v2.x);
  float o5 = mix(c1,d1,v2.x);
  float o6 = mix(o4,o5,v2.y);

  float o7 = mix(o3,o6,v2.z);
  
  return o7;
}

float fbm(vec3 uv , float f ) {
  float o = 0.;
  float n = 1.;
  
  for ( int i = 0 ; i < 5 ; ++ i ) {
    o += pnoise( uv , f ) * n;
    f *= 2.; 
    n *= 0.5;
  }

  return o;
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

vec2 sdf(vec3 p) {

  vec3 p2 = p + vec3( time * .15 , time * -.08 , time * -.12 );

  //cloud sphere
  float cloudPlane = dot( p + vec3(0,-0.4,0) , vec3(0.,1.,0.) );
  float l0 = length( p + vec3(1.7,-0.15,1.0) ) - 0.7;
  float l1 = length( p + vec3(-0.8,-0.15,-1.0) ) - 0.7;
  float l2 = min(l0,l1);
  float cl = max(l2,-cloudPlane);

  //cloud detail
  float l4 = fbm( p2 , 5.0 ) - 0.8;
  float l5 = mix ( cl , l4 , .2 );

  //plane
  float l6 = dot( p , vec3(0.,1.,0.));

  if ( l5 < l6 ) {
    return vec2(l5,1);
  } else {
    return vec2(l6,2);
  }

}

vec3 createnormal(vec3 p) {

  float e = 0.0001;

  return normalize( vec3(
    sdf( vec3(p.x+e,p.y,p.z) ).x - sdf( vec3(p.x-e,p.y,p.z) ).x ,
    sdf( vec3(p.x,p.y+e,p.z) ).x - sdf( vec3(p.x,p.y-e,p.z) ).x ,
    sdf( vec3(p.x,p.y,p.z+e) ).x - sdf( vec3(p.x,p.y,p.z-e) ).x
  ));

}

vec3 lightingMaterial00 ( vec3 lightvec , vec3 p ) {

  vec3 normal = createnormal(p);
  vec3 s = p + normal * 0.01;

  float result = 0.9;
  float depth = 0.1;
  float minlight = 0.1;

  for( int I=0; I< 20 ; ++I ) {
    
    vec3 p2 = s + lightvec * depth;
    float len = sdf(p2).x;
    result = min( result , (len * 2.6 / depth) + minlight ) ;
    depth += len ;

    if( len < 0.00001 ) {
      result = minlight;
      break;
    }

  }

  return mix( vec3(0.2,0.1,0.9) , vec3( result ), 0.9 );

}

vec3 lightingMaterial01 ( vec3 lightvec , vec3 p ) {

  vec3 normal = createnormal(p);
  vec3 s = p + normal * 0.01;

  float result = 1.;
  float depth = 0.;
  float minlight = .1;

  for( int I=0; I< 15 ; ++I ) {
    
    vec3 p2 = s + lightvec * depth;
    float len = sdf(p2).x;
    result = min( result , len * 4.6 / depth + minlight );
    depth += len ;

    if( len < 0.001 ) {
      result = minlight;
      break;
    }

  }

  return mix ( vec3( 0.2 , 0.1 , 0.0 ) , vec3 ( result ) , .5 );

}

vec4 render(vec3 eye , vec3 worldDir , float start , float end ) {

  vec3 lightvec = normalize( vec3( 1.0 ,1.2, -0.8) );

  vec3 sky = vec3(0.25,0.4,0.65);
  vec3 cloud = vec3(0.,0.,0.);
  vec3 background = sky;
  float ratio = 1.0;

  float depth = start;
  for(int I=0;I<200;++I) {

    vec3 p = eye + worldDir * depth;
    if ( 17. < depth ) {
      break;
    }

    vec2 ss = sdf(p);
    float len = ss.x;
    int material = 0;

    if( len < 0.01 ) {
      
      material = int(ss.y);

      if ( material == 1 ) {
        ratio = min( ratio , 0.9 );
        vec3 l = lightingMaterial00( lightvec , p );
        cloud = mix(cloud , l , ratio);
        ratio *= .7;
        if ( ratio < 0.0001 ) {
          break;
        }
        depth += max(len, 0.001 * noise( worldDir * time ) + 0.002 );
      }

      if ( material == 2 ) {
        vec3 ground = lightingMaterial01( lightvec , p );
        background = ground;
        break;
      }

    } else {
      depth += max(len, 0.01 );
    }

  }

  vec3 o = background + cloud * .9 ; // (1.0 - ratio);
  return vec4( o , 1. );
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy * (1.0/resolution.x) - vec2(0.5, 0.5);

    float t = time * .1;
    vec3 eye = vec3( 5. ,2.5, 4. );
    vec3 center = vec3(0.,0.,0.);
    vec3 up = vec3(0.,1.,0.);
    mat4 vtw = createVTW(eye,center,up);

    vec3 viewDir = rayDirection(45.,resolution.xy);
    vec3 worldDir = (vtw * vec4(viewDir,0.)).xyz;

   glFragColor = render( eye , worldDir , 0. , 1000. );
}
