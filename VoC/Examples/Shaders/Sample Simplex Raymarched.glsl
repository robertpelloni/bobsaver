#version 420

// original https://www.shadertoy.com/view/3tsSzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "raymarch-simplex1" by hodapp. https://shadertoy.com/view/3lfXzB
// 2019-07-17 17:01:18

//
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0; }

float mod289(float x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec4 permute(vec4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

float permute(float x) {
     return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float taylorInvSqrt(float r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec4 grad4(float j, vec4 ip)
  {
  const vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
  vec4 p,s;

  p.xyz = floor( fract (vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
  p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
  s = vec4(lessThan(p, vec4(0.0)));
  p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www; 

  return p;
  }
                        
// (sqrt(5) - 1)/4 = F4, used once below
#define F4 0.309016994374947451

float snoise(vec4 v)
  {
  const vec4  C = vec4( 0.138196601125011,  // (5 - sqrt(5))/20  G4
                        0.276393202250021,  // 2 * G4
                        0.414589803375032,  // 3 * G4
                       -0.447213595499958); // -1 + 4 * G4

// First corner
  vec4 i  = floor(v + dot(v, vec4(F4)) );
  vec4 x0 = v -   i + dot(i, C.xxxx);

// Other corners

// Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
  vec4 i0;
  vec3 isX = step( x0.yzw, x0.xxx );
  vec3 isYZ = step( x0.zww, x0.yyz );
//  i0.x = dot( isX, vec3( 1.0 ) );
  i0.x = isX.x + isX.y + isX.z;
  i0.yzw = 1.0 - isX;
//  i0.y += dot( isYZ.xy, vec2( 1.0 ) );
  i0.y += isYZ.x + isYZ.y;
  i0.zw += 1.0 - isYZ.xy;
  i0.z += isYZ.z;
  i0.w += 1.0 - isYZ.z;

  // i0 now contains the unique values 0,1,2,3 in each channel
  vec4 i3 = clamp( i0, 0.0, 1.0 );
  vec4 i2 = clamp( i0-1.0, 0.0, 1.0 );
  vec4 i1 = clamp( i0-2.0, 0.0, 1.0 );

  //  x0 = x0 - 0.0 + 0.0 * C.xxxx
  //  x1 = x0 - i1  + 1.0 * C.xxxx
  //  x2 = x0 - i2  + 2.0 * C.xxxx
  //  x3 = x0 - i3  + 3.0 * C.xxxx
  //  x4 = x0 - 1.0 + 4.0 * C.xxxx
  vec4 x1 = x0 - i1 + C.xxxx;
  vec4 x2 = x0 - i2 + C.yyyy;
  vec4 x3 = x0 - i3 + C.zzzz;
  vec4 x4 = x0 + C.wwww;

// Permutations
  i = mod289(i); 
  float j0 = permute( permute( permute( permute(i.w) + i.z) + i.y) + i.x);
  vec4 j1 = permute( permute( permute( permute (
             i.w + vec4(i1.w, i2.w, i3.w, 1.0 ))
           + i.z + vec4(i1.z, i2.z, i3.z, 1.0 ))
           + i.y + vec4(i1.y, i2.y, i3.y, 1.0 ))
           + i.x + vec4(i1.x, i2.x, i3.x, 1.0 ));

// Gradients: 7x7x6 points over a cube, mapped onto a 4-cross polytope
// 7*7*6 = 294, which is close to the ring size 17*17 = 289.
  vec4 ip = vec4(1.0/294.0, 1.0/49.0, 1.0/7.0, 0.0) ;

  vec4 p0 = grad4(j0,   ip);
  vec4 p1 = grad4(j1.x, ip);
  vec4 p2 = grad4(j1.y, ip);
  vec4 p3 = grad4(j1.z, ip);
  vec4 p4 = grad4(j1.w, ip);

// Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  p4 *= taylorInvSqrt(dot(p4,p4));

// Mix contributions from the five corners
  vec3 m0 = max(0.6 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0);
  vec2 m1 = max(0.6 - vec2(dot(x3,x3), dot(x4,x4)            ), 0.0);
  m0 = m0 * m0;
  m1 = m1 * m1;
  return 49.0 * ( dot(m0*m0, vec3( dot( p0, x0 ), dot( p1, x1 ), dot( p2, x2 )))
               + dot(m1*m1, vec2( dot( p3, x3 ), dot( p4, x4 ) ) ) ) ;

  }

// Starting point:
// https://www.shadertoy.com/view/XsB3Rm

// ray marching
const int max_iterations = 512;
const float stop_threshold = 0.001;
const float grad_step = 0.02;
const float clip_far = 1000.0;

// math
const float PI = 3.14159265359;
const float DEG_TO_RAD = PI / 180.0;

// iq's distance function
float sdSphere( vec3 pos, float r ) {
    return length( pos ) - r;
}

vec3 opTwist(in vec3 p) {
    const float k = 1.0;
    float c = cos(k*p.y);
    float s = sin(k*p.y);
    mat2 m = mat2(c,-s,s,c);
    vec3 q = vec3(m*p.xz,p.y);
    return q;
}

float sdCylinder(vec3 p, vec3 c) {
    return length(p.xz-c.xy)-c.z;
}

float sdBox( vec3 p, vec3 b ) {
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
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

vec3 xform(in vec3 pt, in float w0) {
    return vec3(snoise(vec4(pt, w0)),
                snoise(vec4(pt, w0 + 1000.0)),
                snoise(vec4(pt, w0 + 2000.0)));
}

// get distance in the world
float dist_field( vec3 p ) {
    
    const float l = 2.0;
    
    if (dot(p, p) > l*l) {
    //if (abs(p.x) > l || abs(p.y) > l || abs(p.z) > l) {
        return 1000.0;
    }
    
    //p += 0.1*xform(p*2.0, 0.0);
    
    //p.z += time;
    float th = -0.1; // (cos(time / 3.0) + 1.0) / 2.0;
    
    vec4 pt = vec4(p, time/9.0);
    
    return (snoise(pt*0.25)*2. + snoise(pt*2.)/2. + snoise(pt*4.)/4. +th+pow(length(p)*0.7,6.)) / 1.0;
}

// get gradient in the world
vec3 gradient( vec3 pos ) {
    const vec3 dx = vec3( grad_step, 0.0, 0.0 );
    const vec3 dy = vec3( 0.0, grad_step, 0.0 );
    const vec3 dz = vec3( 0.0, 0.0, grad_step );
    return normalize (
        vec3(
            dist_field( pos + dx ) - dist_field( pos - dx ),
            dist_field( pos + dy ) - dist_field( pos - dy ),
            dist_field( pos + dz ) - dist_field( pos - dz )            
        )
    );
}

vec3 fresnel( vec3 F0, vec3 h, vec3 l ) {
    return F0 + ( 1.0 - F0 ) * pow( clamp( 1.0 - dot( h, l ), 0.0, 1.0 ), 5.0 );
}

// phong shading
vec3 shading( vec3 v, vec3 n, vec3 dir, vec3 eye ) {
    // ...add lights here...
    
    float shininess = 8.0;
    
    vec3 final = vec3( 0.0 );
    
    vec3 ref = reflect( dir, n );
    
    vec3 Ks = vec3( 0.5 );
    vec3 Kd = vec3( 1.0 );
    
    // light 0
    {
        vec3 light_pos   = vec3( 20.0, 20.0, 20.0 );
        vec3 light_color = vec3( 1.0, 0.7, 0.7 );
    
        vec3 vl = normalize( light_pos - v );
    
        vec3 diffuse  = Kd * vec3( max( 0.0, dot( vl, n ) ) );
        vec3 specular = vec3( max( 0.0, dot( vl, ref ) ) );
        
        vec3 F = fresnel( Ks, normalize( vl - dir ), vl );
        specular = pow( specular, vec3( shininess ) );
        
        final += light_color * mix( diffuse, specular, F ); 
    }
    
    // light 1
    {
        vec3 light_pos   = vec3( -20.0, -20.0, -30.0 );
        vec3 light_color = vec3( 0.5, 0.7, 1.0 );
    
        vec3 vl = normalize( light_pos - v );
    
        vec3 diffuse  = Kd * vec3( max( 0.0, dot( vl, n ) ) );
        vec3 specular = vec3( max( 0.0, dot( vl, ref ) ) );
        
        vec3 F = fresnel( Ks, normalize( vl - dir ), vl );
        specular = pow( specular, vec3( shininess ) );
        
        final += light_color * mix( diffuse, specular, F );
    }

    //final += texture( iChannel0, ref ).rgb * fresnel( Ks, n, -dir );
    
    return final;
}

bool ray_vs_aabb(vec3 o, vec3 dir, vec3 bmin, vec3 bmax, inout vec2 e ) {
    vec3 a = ( bmin - o ) / dir;
    vec3 b = ( bmax - o ) / dir;
    
    vec3 s = min( a, b );
    vec3 t = max( a, b );
    
    e.x = max( max( s.x, s.y ), max( s.z, e.x ) );
    e.y = max( min( t.x, t.y ), max( t.z, e.y ) );
    
    return e.x < e.y;
}

// ray marching
bool ray_marching( vec3 o, vec3 dir, inout float depth, inout vec3 n ) {
    float t = 0.0;
    float d = 10000.0;
    float dt = 0.0;
    for ( int i = 0; i < 128; i++ ) {
        vec3 v = o + dir * t;
        d = dist_field( v );
        if ( d < 0.001 ) {
            break;
        }
        dt = min( abs(d), 0.1 );
        t += dt;
        if ( t > depth ) {
            break;
        }
    }
    
    if ( d >= 0.001 ) {
        return false;
    }
    
    t -= dt;
    for ( int i = 0; i < 4; i++ ) {
        dt *= 0.5;
        
        vec3 v = o + dir * ( t + dt );
        if ( dist_field( v ) >= 0.001 ) {
            t += dt;
        }
    }
    
    depth = t;
    n = normalize( gradient( o + dir * t ) );
    return true;
    
    return true;
}

// get ray direction
vec3 ray_dir( float fov, vec2 size, vec2 pos ) {
    vec2 xy = pos - size * 0.5;

    float cot_half_fov = tan( ( 90.0 - fov * 0.5 ) * DEG_TO_RAD );    
    float z = size.y * 0.5 * cot_half_fov;
    
    return normalize( vec3( xy, -z ) );
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
    // default ray dir
    vec3 dir = ray_dir( 45.0, resolution.xy, gl_FragCoord.xy );
    
    // default ray origin
    vec3 eye = vec3( 0.0, 0.0, 3.5 );

    // rotate camera
    mat3 rot = rotationXY( ( mouse*resolution.xy.xy - resolution.xy * 0.5 ).yx * vec2( 0.01, -0.01 ) );
    dir = rot * dir;
    eye = rot * eye;
    
    // ray marching
    float depth = clip_far;
    vec3 n = vec3( 0.0 );
    if ( !ray_marching( eye, dir, depth, n ) ) {
        //glFragColor = texture( iChannel0, dir );
        return;
    }
    
    // shading
    vec3 pos = eye + dir * depth;
    
    vec3 color = shading( pos, n, dir, eye );
    glFragColor = vec4( pow( color, vec3(1.0/1.2) ), 1.0 );
}
