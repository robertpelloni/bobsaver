#version 420

// original https://www.shadertoy.com/view/XlSSRh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Branch Code stolen from : https://www.shadertoy.com/view/ltlSRl

const float MAX_TRACE_DISTANCE = 10.0;             // max trace distance
const float INTERSECTION_PRECISION = 0.001;        // precision of the intersection
const int NUM_OF_TRACE_STEPS = 100;
const float PI = 3.14159;

mat4 rotateX(float angle){
    
    angle = -angle/180.0*3.1415926536;
    float c = cos(angle);
    float s = sin(angle);
    return mat4(1.0, 0.0, 0.0, 0.0, 0.0, c, -s, 0.0, 0.0, s, c, 0.0, 0.0, 0.0, 0.0, 1.0);
    
}

mat4 rotateY(float angle){
    
    angle = -angle/180.0*3.1415926536;
    float c = cos(angle);
    float s = sin(angle);
    return mat4(c, 0.0, s, 0.0, 0.0, 1.0, 0.0, 0.0, -s, 0.0, c, 0.0, 0.0, 0.0, 0.0, 1.0);
    
}

mat4 rotateZ(float angle){
    
    angle = -angle/180.0*3.1415926536;
    float c = cos(angle);
    float s = sin(angle);
    return mat4(c, -s, 0.0, 0.0, s, c, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
    
}
mat4 translate(vec3 t){
    
    return mat4(1.0, 0.0, 0.0, -t.x, 0.0, 1.0, 0.0, -t.y, 0.0, 0.0, 1.0, -t.z, 0.0, 0.0, 0.0, 1.0);
    
}

float sdCappedCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec2 smoothU( vec2 d1, vec2 d2, float k)
{
    float a = d1.x;
    float b = d2.x;
    float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
    return vec2( mix(b, a, h) - k*h*(1.0-h), mix(d2.y, d1.y, pow(h, 2.0)));
}

//--------------------------------
// Modelling 
//--------------------------------
vec2 map( vec3 pos ){  
    
    
    float branchSize = .3;
    float reductionFactor = .6 +  .2 * sin( time * 1.73 );
    float trunkSize = .2 +  .1 * sin( time * 3.27 );
    float bs = branchSize;
    float rot = 40. + 10. * sin( time * 4. );
    
    pos += vec3( 0. , branchSize , 0. );

   
    vec4 p = vec4( pos , 1. );
    mat4 m;
    
       //vec2 res = vec2( (abs(sin( pos.x * pos.y * pos.z  * 10.)) * 1.9 ) + length( pos ) - 1., 0.0 );
  
    vec2 res = vec2( sdCappedCylinder( p.xyz , vec2( trunkSize * bs , bs )),1.);
    
    for( int i = 0; i < 4; i ++ ){
        bs *= reductionFactor;

        m = translate(vec3(0.0, bs*2. , 0.0)) * rotateY(rot) * rotateX(rot);    
        p.x = abs(p.x) - bs / 2.;
        p.z = abs(p.z) - bs / 2.;   
        p = p * m; 

        res = smoothU( res , vec2( sdCappedCylinder( p.xyz , vec2( trunkSize * bs , bs )),1.) , .1);
    }

       return res;
    
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

void doCamera( out vec3 camPos, out vec3 camTar, in float time, in vec2 mouse )
{
    float an = 0.3 + 3.0*mouse.x;
       float an2 = 0.3 + 3.0*mouse.y;

    camPos = vec3(3.5*sin(an),3. * cos( an2),3.5*cos(an));
    camTar = vec3(0. ,0.0,0.0);
}

// Calculates the normal by taking a very small distance,
// remapping the function, and getting normal for that
vec3 calcNormal( in vec3 pos ){
    
    vec3 eps = vec3( 0.01, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
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
        t += h;
        id = m.y;
        
    }

    if( t < MAX_TRACE_DISTANCE ) res = t;
    if( t > MAX_TRACE_DISTANCE ) id =-1.0;
    
    return vec2( res , id );
     
}

void main(void) {
   

    vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
    vec2 m = mouse*resolution.xy.xy/resolution.xy;

    // camera movement
    vec3 ro, ta;
    doCamera( ro, ta, time, m );

    // camera matrix
    mat3 camMat = calcLookAtMatrix( ro, ta, 0.0 );  // 0.0 is the camera roll
    
    // create view ray
    vec3 rd = normalize( camMat * vec3(p.xy,2.0) ); // 2.0 is the lens length

    vec2 res = calcIntersection( ro , rd  );
    
    vec3 col = vec3( 0. , 0. , 0. ); 
    
        // If we have hit something lets get real!
    if( res.y > -.5 ){
   
        vec3 pos = ro + rd * res.x;
        vec3 nor = calcNormal( pos );
           col = nor * .5 + .5;

    }
    
    // apply gamma correction
    col = pow( col, vec3(0.4545) );

    glFragColor = vec4( col , 1. );
    
}
