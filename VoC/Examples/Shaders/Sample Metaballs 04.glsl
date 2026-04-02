#version 420

// original https://www.shadertoy.com/view/Xl2GRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define time time

const float INTERSECTION_PRECISION = .01;
const float MAX_TRACE_DISTANCE     = 10.;
const int NUM_TRACE_STEPS          = 100;

const vec3 lightPos = vec3( 3. , 0.  , 0. );

// Taken from https://www.shadertoy.com/view/4ts3z2
// By NIMITZ  (twitter: @stormoid)
// good god that dudes a genius...

float tri_1_0( float x ){ 
  return abs( fract(x) - .5 );
}

vec3 tri3_1_1( vec3 p ){
 
  return vec3( 
      tri_1_0( p.z + tri_1_0( p.y * 1. ) ), 
      tri_1_0( p.z + tri_1_0( p.x * 1. ) ), 
      tri_1_0( p.y + tri_1_0( p.x * 1. ) )
  );

}
                                 

float triNoise3D_1_2( vec3 p, float spd , float time){
  
  float z  = 1.4;
    float rz =  0.;
  vec3  bp =   p;

    for( float i = 0.; i <= 3.; i++ ){
   
    vec3 dg = tri3_1_1( bp * 2. );
    p += ( dg + time * .1 * spd );

    bp *= 1.8;
        z  *= 1.5;
        p  *= 1.2; 
      
    float t = tri_1_0( p.z + tri_1_0( p.x + tri_1_0( p.y )));
    rz += t / z;
    bp += 0.14;

    }

    return rz;

}

float smin_2_3(float a, float b, float k) {
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  return mix(b, a, h) - k * h * (1.0 - h);
}

// exponential smooth min (k = 32);
/*float smin( float a, float b, float k )
{
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}*/

float sdSphere( vec3 p, float s ){
  
    return length( p ) - s*( (triNoise3D_1_2( p , .02 , time) + triNoise3D_1_2( p * .1 , .02 , time) * 4.) * .3 + .7);

}

void doCamera( out vec3 camPos , out vec3 camTar , in float time ){

  float an = .3 + 10. * sin( time * .1 );
  camPos = vec3( 3.5 * sin( an ) , 0. , 3.5 * cos( an ));
  camTar = vec3( 0. );

}

mat3 calcLookAtMatrix( vec3 camPos , vec3 camTar , float roll ){

  vec3 up = vec3( sin( roll ) ,cos( roll ) , 0. );
  vec3 ww = normalize( camTar - camPos );
  vec3 uu = normalize( cross( ww , up ) );
  vec3 vv = normalize( cross( uu , ww ) );

  return mat3( uu , vv , ww );

}

vec2 map( vec3 pos ){

  vec2 res = vec2( sdSphere( pos ,  .3) ,1. );

  float fRes = res.x;
  for( int i = 0; i < 6; i ++ ){
   
    vec3 p  = vec3( 
      .8 * sin( ( float( i )+ time* .1 ) * 2. ) ,
      .8 * sin( ( float( i )+ time* .1 ) * 5. ) ,
      .8 * sin( ( float( i )+ time* .1 ) * 9. ) 
    );   
    vec2 res2 = vec2( sdSphere( pos -p ,  .3) , 2. ); 

    fRes = smin_2_3( fRes , res2.x , .8);

  }  
  
  //float fRes = -1.;
  
  //float fRes = smin( res.x , res2.x , 8.);

  return vec2( fRes , 1.);

}

// res = result;
vec2 calcIntersection( in vec3 ro , in vec3 rd ){

  float h     = INTERSECTION_PRECISION * 2.;
  float t     = 0.;
  float res   = -1.;
  float id    = -1.;

  for( int i = 0; i < NUM_TRACE_STEPS; i++ ){
      
    if( h < INTERSECTION_PRECISION || t > MAX_TRACE_DISTANCE ) break;
    
    vec2 m = map( ro + rd * t );
  
    h  = m.x;
    t += h;
    id = m.y;

  }

  if( t < MAX_TRACE_DISTANCE ) res = t;
  if( t > MAX_TRACE_DISTANCE ) id = -1.;

  return vec2( res , id ); 

}

vec3 calcNormal( vec3 pos ){

  vec3 eps = vec3( 0.01 , 0. , 0. );
  
  vec3 nor = vec3(  
    map( pos + eps.xyy ).x - map( pos - eps.xyy ).x,
    map( pos + eps.yxy ).x - map( pos - eps.yxy ).x,
    map( pos + eps.yyx ).x - map( pos - eps.yyx ).x
  );

  return normalize( nor );
  

}

void main(void) {

  vec2 p = ( -resolution.xy + 2.0 * gl_FragCoord.xy ) / resolution.y;
    
  vec3 ro , ta;
  
  doCamera( ro , ta , time  );

  mat3 camMat = calcLookAtMatrix( ro , ta , 0. ); 
 
  // z = lens length 
  vec3 rd = normalize( camMat * vec3( p.xy , 2. ) ); 
 
  vec2 res = calcIntersection( ro , rd );
  vec3 col = vec3( 0. );

  if( res.x > 0. ){

    vec3 pos = ro + rd * res.x;

    vec3 lightDir = normalize( pos - lightPos );
    vec3 nor = calcNormal( pos );

    float lightMatch = max( 0. , dot( nor , lightDir ) );

    vec3 refl = reflect( lightDir , nor );
    float reflMatch = max( 0. , dot( refl , rd ) );

    float rimMatch =  1. - max( 0. , dot( nor , -rd ) );

    vec3 norCol = (nor * .5 + .5);

    vec3 lambCol = ((nor * .5 + .5)* lightMatch);
    vec3 ambiCol = ( vec3( 1. ) -norCol )*.1;
    vec3 specCol = vec3( 1. , .8 , 0. ) * pow( reflMatch , 20. );
    vec3 rimCol  = vec3( .4 , 1. , .8 ) * pow( rimMatch, 4. );
    
    col = lambCol + ambiCol + specCol + rimCol;

  }

  glFragColor = vec4( col , 1. );

}
