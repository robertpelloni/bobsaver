// original https://www.shadertoy.com/view/MsjyRK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// DNA Worms
// combination of a couple things
// DNA model - me, used wikipedia and a few other sources to get the numbers right.
// (DNA-B)

// worms:
// Created by inigo quilez - iq/2014
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

float hash( vec2 p ) { return fract(sin(1.0+dot(p,vec2(127.1,311.7)))*43758.545); }
vec2  sincos( float x ) { return vec2( sin(x), cos(x) ); }
vec3  opU( vec3 d1, vec3 d2 ){ return (d1.x<d2.x) ? d1 : d2;}

vec2 sdSegment( in vec3 p, in vec3 a, in vec3 b )
{
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return vec2( length( pa - ba*h ), h );
}

float sdPlane( vec3 p )
{
    return p.y;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float udRoundBox( vec3 p, vec3 b, float r )
{
    return length(max(abs(p)-b,0.0))-r;
}

float sdTorus( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
#if 0
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
#else
    float d1 = q.z-h.y;
    float d2 = max((q.x*0.866025+q.y*0.5),q.y)-h.x;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
#if 0
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
#else
    float d1 = q.z-h.y;
    float d2 = max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}

float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCone( in vec3 p, in vec3 c )
{
    vec2 q = vec2( length(p.xz), p.y );
    float d1 = -q.y-c.z;
    float d2 = max( dot(q,c.xy), q.y);
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float sdConeSection( in vec3 p, in float h, in float r1, in float r2 )
{
    float d1 = -p.y - h;
    float q = p.y - h;
    float si = 0.5*(r1-r2)/h;
    float d2 = max( sqrt( dot(p.xz,p.xz)*(1.0-si*si)) + q*si - r2, q );
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float sdPryamid4(vec3 p, vec3 h ) // h = { cos a, sin a, height }
{
    // Tetrahedron = Octahedron - Cube
    float box = sdBox( p - vec3(0,-2.0*h.z,0), vec3(2.0*h.z) );
 
    float d = 0.0;
    d = max( d, abs( dot(p, vec3( -h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  h.x, h.y, 0 )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y, h.x )) ));
    d = max( d, abs( dot(p, vec3(  0, h.y,-h.x )) ));
    float octa = d - h.z;
    return max(-box,octa); // Subtraction
 }

float length2( vec2 p )
{
    return sqrt( p.x*p.x + p.y*p.y );
}

float length6( vec2 p )
{
    p = p*p*p; p = p*p;
    return pow( p.x + p.y, 1.0/6.0 );
}

float length8( vec2 p )
{
    p = p*p; p = p*p; p = p*p;
    return pow( p.x + p.y, 1.0/8.0 );
}

float sdTorus82( vec3 p, vec2 t )
{
    vec2 q = vec2(length2(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

float sdTorus88( vec3 p, vec2 t )
{
    vec2 q = vec2(length8(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

float sdCylinder6( vec3 p, vec2 h )
{
    return max( length6(p.xz)-h.x, abs(p.y)-h.y );
}

//------------------------------------------------------------------

float opS( float d1, float d2 )
{
    return max(-d2,d1);
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

vec3 opRep( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}

vec3 opTwist( vec3 p )
{
    float  c = cos(10.0*p.y+10.0);
    float  s = sin(10.0*p.y+10.0);
    mat2   m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}

// Smooth Min
// http://www.iquilezles.org/www/articles/smin/smin.htm

// Min Polynomial
// ========================================
float sMinP( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

// Min Exponential
// ========================================
float sMinE( float a, float b, float k) {
    float res = exp( -k*a ) + exp( -k*b );
    return -log( res )/k;
}

// Min Power
// ========================================
float sMin( float a, float b, float k ) {
    a = pow( a, k );
    b = pow( b, k );
    return pow( (a*b) / (a+b), 1.0/k );
}

mat4 Rot4X(float a ) {
    float c = cos( a );
    float s = sin( a );
    return mat4( 1, 0, 0, 0,
                0, c,-s, 0,
                0, s, c, 0,
                0, 0, 0, 1 );
}

// Return 4x4 rotation Y matrix
// angle in radians
// ========================================
mat4 Rot4Y(float a ) {
    float c = cos( a );
    float s = sin( a );
    return mat4( c, 0, s, 0,
                0, 1, 0, 0,
                -s, 0, c, 0,
                0, 0, 0, 1 );
}

// Return 4x4 rotation Z matrix
// angle in radians
// ========================================
mat4 Rot4Z(float a ) {
    float c = cos( a );
    float s = sin( a );
    return mat4(
        c,-s, 0, 0,
        s, c, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
    );
}

// if no support for GLSL 1.2+
//     #version 120
// ========================================
mat4 transposeM4(in mat4 m ) {
    vec4 r0 = m[0];
    vec4 r1 = m[1];
    vec4 r2 = m[2];
    vec4 r3 = m[3];

    mat4 t = mat4(
        vec4( r0.x, r1.x, r2.x, r3.x ),
        vec4( r0.y, r1.y, r2.y, r3.y ),
        vec4( r0.z, r1.z, r2.z, r3.z ),
        vec4( r0.w, r1.w, r2.w, r3.w )
    );
    return t;
}

// Note: m must already be inverted!
// TODO: invert(m) transpose(m)
// Op Rotation / Translation
// ========================================
vec3 opTx( vec3 p, mat4 m ) {   // BUG in iq's docs, should be q
    return (transposeM4(m)*vec4(p,1.0)).xyz;
}

// angstroms to world units
#define ANG_TO_WORLD 0.1
// angstroms
#define DNA_RADIUS 10.72 * ANG_TO_WORLD

#define RISE 3.32 * ANG_TO_WORLD

#define OFFSET 21.44 * ANG_TO_WORLD
// angstroms

//#define ROTATION_PER_BP -0.5986479 / 3.32 / ANG_TO_WORLD
#define ROTATION_PER_BP -0.180315633 / ANG_TO_WORLD

#define BP_APOTHEM 3.84170 * ANG_TO_WORLD

#define BP_WIDTH 20.01596 * ANG_TO_WORLD / 2.0

vec3 opDNATwist(vec3 p) // 20 angs wide
{
    float c = cos(ROTATION_PER_BP * p.y); // angs / 10
    float s = sin(ROTATION_PER_BP * p.y);
    mat2 m = mat2(c, -s, s, c); // rotation matrix
     return vec3(m * p.xz, p.y);
}

float mapDNA(vec3 pos) {
    // dna base pair
    float dnaBasePairs = sdBox(
        opRep(
            opDNATwist(pos - vec3(0, - RISE / 2.0, 0)) + vec3(BP_APOTHEM, 0, time * 1.0),
            vec3(0, 0, RISE)
        ),
        vec3(.07, BP_WIDTH, .1)
    );
    
    vec2 strands = opU(
        vec2(sdBox(opDNATwist(pos) - vec3(0, DNA_RADIUS, 0), vec3(.225, .125, 100)), 200.),
        vec2(sdBox(opDNATwist(pos + vec3(0, OFFSET, 0)) - vec3(0, DNA_RADIUS, 0.0), vec3(.225, .125, 100)), 100.0)
    );
    
    
    vec2 res = opU(
        strands,
        vec2(dnaBasePairs, 40.0)
    );
    
    return res[0];
}

vec3 map( vec3 p )
{
    vec2  id = floor( (p.xz+1.0)/5.0 );
    float ph = hash(id+113.1);
    float ve = hash(id);

    p.xz = mod( p.xz+1.0, 5.0 ) - 2.50;
    p.xz += 0.5*cos( 2.0*ve*time + (p.y+ph)*vec2(0.53,0.32) - vec2(1.57,0.0) );

    vec3 p1 = p; p1.xz += 0.15*sincos(p.y-ve*time*ve+0.0);
    vec3 p2 = p; p2.xz += 0.15*sincos(p.y-ve*time*ve+2.0);
    vec3 p3 = p; p3.xz += 0.15*sincos(p.y-ve*time*ve+4.0);
    
    vec2 h1 = sdSegment( p1, vec3(0.0,-50.0, 0.0), vec3(0.0, 50.0, 0.0) );
    vec2 h2 = sdSegment( p2, vec3(0.0,-50.0, 0.0), vec3(0.0, 50.0, 0.0) );
    vec2 h3 = sdSegment( p3, vec3(0.0,-50.0, 0.0), vec3(0.0, 50.0, 0.0) );

    return opU( opU( vec3(h1.x-0.15*(0.8+0.2*sin(200.0*h1.y)), ve + 0.000, h1.y), 
                     vec3(h2.x-0.15*(0.8+0.2*sin(200.0*h2.y)), ve + 0.015, h2.y) ), 
                     vec3(mapDNA(p), ve + 0.030, h3.y) );

}

vec3 intersect( in vec3 ro, in vec3 rd, in float px, const float maxdist )
{
    vec3 res = vec3(-1.0);
    float t = 0.0;
    for( int i=0; i<256; i++ )
    {
        vec3 h = map(ro + t*rd);
        res = vec3( t, h.yz );
        if( h.x<(px*t) || t>maxdist ) break;
        t += min( h.x, 0.5 )*0.7;
    }
    return res;
}

vec3 calcNormal( in vec3 pos )
{
    const vec2 e = vec2(1.0,-1.0)*0.003;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
                      e.yyx*map( pos + e.yyx ).x + 
                      e.yxy*map( pos + e.yxy ).x + 
                      e.xxx*map( pos + e.xxx ).x );
}

float calcOcc( in vec3 pos, in vec3 nor )
{
    const float h = 0.1;
    float ao = 0.0;
    for( int i=0; i<8; i++ )
    {
        vec3 dir = sin( float(i)*vec3(1.0,7.13,13.71)+vec3(0.0,2.0,4.0) );
        dir = dir + 2.0*nor*max(0.0,-dot(nor,dir));            
        float d = map( pos + h*dir ).x;
        ao += h-d;
    }
    return clamp( 1.0 - 0.7*ao, 0.0, 1.0 );
}

vec3 render( in vec3 ro, in vec3 rd, in float px )
{
    vec3 col = vec3(0.0);
    
    const float maxdist = 32.0;
    vec3 res = intersect( ro, rd, px, maxdist );
    if( res.x < maxdist )
    {
        vec3  pos = ro + res.x*rd;
        vec3  nor = calcNormal( pos );
        float occ = calcOcc( pos, nor );

        col = 0.5 + 0.5*cos( res.y*30.0 + vec3(0.0,4.4,4.0) );
        col *= 0.5 + 1.5*nor.y;
        col += clamp(1.0+dot(rd,nor),0.0,1.0);
        float u = 800.0*res.z - sin(res.y)*time;
        col *= 0.95 + 0.05*cos( u + 3.1416*cos(1.5*u + 3.1416*cos(3.0*u)) + vec3(0.0,1.0,2.0) );
        col *= vec3(1.5,1.0,0.7);
        col *= occ;

        float fl = mod( (0.5+cos(2.0+res.y*47.0))*time + res.y*7.0, 4.0 )/4.0;
        col *= 2.5 - 1.5*smoothstep(0.02,0.04,abs(res.z-fl));
        
        col *= exp( -0.1*res.x );
        col *= 1.0 - smoothstep( 20.0, 30.0, res.x );
    }
    
    return pow( col, vec3(0.5,1.0,1.0) );
}

void main(void)
{    
    vec2 p = (-resolution.xy+2.0*gl_FragCoord.xy)/resolution.y;
    vec2 q = gl_FragCoord.xy/resolution.xy;
    
    vec3  ro = vec3(0.6,1.4,1.2);
    vec3  ta = vec3(-2.0,1.0,0.0);
    float fl = 3.0;
    vec3  ww = normalize( ta - ro);
    vec3  uu = normalize( cross( vec3(0.0,1.0,0.0), ww ) );
    vec3  vv = normalize( cross(ww,uu) );
    vec3  rd = normalize( p.x*uu + p.y*vv + fl*ww );

    vec3 col = render( ro, rd, 1.0/(resolution.y*fl) );
    
    col *= pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
    
    glFragColor = vec4( col, 1.0 );
}

void mainVR( out vec4 glFragColor, in vec2 gl_FragCoord, in vec3 fragRayOri, in vec3 fragRayDir )
{
    vec3 ro = fragRayOri + vec3( 1.0, 0.0, 1.0 );
    vec3 rd = fragRayDir;
    vec3 col = render( ro, rd, 0.001 );
    
    glFragColor = vec4( col, 1.0 );
}
