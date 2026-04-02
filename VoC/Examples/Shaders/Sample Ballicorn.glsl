#version 420

// original https://www.shadertoy.com/view/WsSXWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MINIMIZED version of https://www.shadertoy.com/view/Xl2XWt

const float MAX_TRACE_DISTANCE = 10.0;           // max trace distance
const float INTERSECTION_PRECISION = 0.0001;        // precision of the intersection
const int NUM_OF_TRACE_STEPS = 300;
const float EPS_NORMAL = 0.001;
const float SCALE_DIST = 0.2;

const float PI = 3.14159265359;

// Hash without Sine
// Creative Commons Attribution-ShareAlike 4.0 International Public License
// Created by David Hoskins.
// https://www.shadertoy.com/view/4djSRW

#define HASHSCALE1 .1031
#define HASHSCALE3 vec3(.1031, .1030, .0973)

float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.xx+p3.yz)*p3.zy);

}

// Spectrum colour palette
// IQ https://www.shadertoy.com/view/ll2GD3
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 spectrum(float n) {
    return pal( n, vec3(0.5,0.5,0.5),vec3(0.5,0.5,0.5),vec3(1.0,1.0,1.0),vec3(0.0,0.33,0.67) );
}

//----
// Camera Stuffs
//----
mat3 calcLookAtMatrix( in vec3 ro, in vec3 ta, in float roll )
{
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(sin(roll),cos(roll),0.0) ) );
    vec3 vv = normalize( cross(uu,ww));
    return mat3( uu, vv, ww );
}

// checks to see which intersection is closer
// and makes the y of the vec2 be the proper id
vec2 opU( vec2 d1, vec2 d2 ){
    
    return (d1.x<d2.x) ? d1 : d2;
    
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdUnion( float d0, float d1 ) {
    return min( d0, d1 );
}

float sdInter( float d0, float d1 ) {
    return max( d0, d1 );
}

float sdSub( float d0, float d1 ) {
    return max( d0, -d1 );
}

float sdUnion_s( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sfDisp( vec3 p ) {
    return sin(p.x)*sin(p.y)*sin(p.z) ;
}

vec3 sdTwist( vec3 p, float a ) {
    float c = cos(a*p.y);
    float s = sin(a*p.y);
    mat2  m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}

vec3 sdRep( vec3 p, vec3 c ) {
    return mod(p,c)-0.5*c;
}

float opOnion( in float sdf, in float thickness )
{
    return abs(sdf)-thickness;
}

vec3 carToPol(vec3 p) {
    float r = length(p);
    float the = acos(p.z/r);
    float phi = atan(p.y,p.x);
    return vec3(r,the,phi);
}

//--------------------------------
// Modelling 
//--------------------------------
vec2 map( vec3 pos ){  
    vec3 pol = carToPol(pos);

    
    float d1 = opOnion(sdSphere( pos, 1.1 ), 0.0001);
    float wave = -0.1+0.5*sin(8.*(pol.y+0.2*time))*sin(8.*(pol.z));
    float d2 = d1 + wave;

    float d = sdSub(d1,d2);

    vec2 res = vec2(d, 1.0);
    
     //vec2 res = vec2( sdSphere( pos - vec3( .0 , .0 , .0 ) , 1.1 ) , 1. ); 
    //res = opU( res , vec2( sdBox( pos- vec3( -.8 , -.4 , 0.2 ), vec3( .4 , .3 , .2 )) , 2. ));
    
    return res;
    
}

vec2 calcIntersection( in vec3 ro, in vec3 rd ){

    
    float h =  INTERSECTION_PRECISION*2.0;
    float t = 0.0;
    float res = -1.0;
    float id = -1.;
    
    for( int i=0; i< NUM_OF_TRACE_STEPS ; i++ ){
        
        if( h < INTERSECTION_PRECISION || t > MAX_TRACE_DISTANCE ) break;
           vec2 m = map( ro+rd*t );
        h = m.x;
        t += h*SCALE_DIST;
        id = m.y;
        
    }

    if( t < MAX_TRACE_DISTANCE ) res = t;
    if( t > MAX_TRACE_DISTANCE ) id =-1.0;
    
    return vec2( res , id );
    
}

// Calculates the normal by taking a very small distance,
// remapping the function, and getting normal for that
vec3 calcNormal( in vec3 pos ){
    
    vec3 eps = vec3( EPS_NORMAL, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
}

vec3 render( vec2 res , vec3 ro , vec3 rd ){
   

  vec3 color = vec3( 0.5 );
    
  vec3 lightPos = vec3( 1. , 4. , 3. );
    
    
  if( res.y > -.5 ){
      
    vec3 pos = ro + rd * res.x;
    vec3 norm = calcNormal( pos );
      
    vec3 lightDir = normalize( lightPos - pos );
    
    float match = max( 0. , dot( lightDir , norm ));
      
       color = vec3( 1. , 1., 1.) * match * 0.3 ;
    
    vec3 pol = carToPol(pos);
    vec3 selfColor = spectrum(1.0*pol.z/PI/2.0+0.5*pol.y/PI);

    color += selfColor * 01.0;
  }
   
  return color;
    
    
}

// camera rotation : pitch, yaw
mat3 rotationXY( vec2 angle ) {
    vec2 c = cos( angle );
    vec2 s = sin( angle );
    
    return mat3(
        c.y      ,  0.0, -s.y,
        s.y * s.x,  c.x,  c.y * s.x,
        s.y * c.x, -s.x,  c.y * c.x
    );
}

void main(void)
{
    
    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;

    vec3 ro = vec3( 3.0*cos(0.5*time), 0.0, 3.0*sin(0.5*time));
    vec3 ta = vec3( 0. , 0. , 0. );
    

    
    // camera matrix
    mat3 camMat = calcLookAtMatrix( ro, ta, 0.5*sin(time) );  // 0.0 is the camera roll
    
    // create view ray
    vec3 rd = normalize( camMat * vec3(p.xy,2.0) ); // 2.0 is the lens length
    
            // rotate camera
    mat3 rot = rotationXY( ( mouse*resolution.xy.xy - resolution.xy * 0.5 ).yx * vec2( 0.01, -0.01 ) );
    rd = rot * rd;
    ro = rot * ro;

    
    vec2 res = calcIntersection( ro , rd  );

    
    vec3 color = render( res , ro , rd );
    
    glFragColor = vec4(color,1.0);

    
    
}
