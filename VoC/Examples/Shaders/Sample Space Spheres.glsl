#version 420

// original https://www.shadertoy.com/view/Xl33Ds

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: Viktor Chlumský
// Created with SHADRON
// www.shadron.info

// LIBRARY FILES

// #include <math_constants>
#define PI 3.1415926535897932384626433832795

// #include <affine_transform>
vec3 rotateY(vec3 p, float a) {
    return vec3(
        cos(a)*p.x+sin(a)*p.z,
        p.y,
        -sin(a)*p.x+cos(a)*p.z
    );
}

// #include <perlin>
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

float perlin_mod289(float x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 perlin_mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 perlin_mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 perlin_mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float perlin_permute(float x) {
     return perlin_mod289(((x*34.0)+1.0)*x);
}

vec3 perlin_permute(vec3 x) {
  return perlin_mod289(((x*34.0)+1.0)*x);
}

vec4 perlin_permute(vec4 x) {
     return perlin_mod289(((x*34.0)+1.0)*x);
}

float perlin_taylorInvSqrt(float r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec4 perlin_taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

vec4 perlin_grad4(float j, vec4 ip)
  {
  const vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
  vec4 p,s;

  p.xyz = floor( fract (vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
  p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
  s = vec4(lessThan(p, vec4(0.0)));
  p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www; 

  return p;
  }

float perlinNoise(vec3 v)
  { 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = perlin_mod289(i); 
  vec4 p = perlin_permute( perlin_permute( perlin_permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = perlin_taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
  }

float perlinNoise(vec4 v)
  {
  const vec4  C = vec4( 0.138196601125011,  // (5 - sqrt(5))/20  G4
                        0.276393202250021,  // 2 * G4
                        0.414589803375032,  // 3 * G4
                       -0.447213595499958); // -1 + 4 * G4

// First corner
  vec4 i  = floor(v + dot(v, vec4(0.309016994374947451)) ); // (sqrt(5) - 1)/4
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
  i = perlin_mod289(i); 
  float j0 = perlin_permute( perlin_permute( perlin_permute( perlin_permute(i.w) + i.z) + i.y) + i.x);
  vec4 j1 = perlin_permute( perlin_permute( perlin_permute( perlin_permute (
             i.w + vec4(i1.w, i2.w, i3.w, 1.0 ))
           + i.z + vec4(i1.z, i2.z, i3.z, 1.0 ))
           + i.y + vec4(i1.y, i2.y, i3.y, 1.0 ))
           + i.x + vec4(i1.x, i2.x, i3.x, 1.0 ));

// Gradients: 7x7x6 points over a cube, mapped onto a 4-cross polytope
// 7*7*6 = 294, which is close to the ring size 17*17 = 289.
  vec4 ip = vec4(1.0/294.0, 1.0/49.0, 1.0/7.0, 0.0) ;

  vec4 p0 = perlin_grad4(j0,   ip);
  vec4 p1 = perlin_grad4(j1.x, ip);
  vec4 p2 = perlin_grad4(j1.y, ip);
  vec4 p3 = perlin_grad4(j1.z, ip);
  vec4 p4 = perlin_grad4(j1.w, ip);

// Normalise gradients
  vec4 norm = perlin_taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;
  p4 *= perlin_taylorInvSqrt(dot(p4,p4));

// Mix contributions from the five corners
  vec3 m0 = max(0.6 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), 0.0);
  vec2 m1 = max(0.6 - vec2(dot(x3,x3), dot(x4,x4)            ), 0.0);
  m0 = m0 * m0;
  m1 = m1 * m1;
  return 49.0 * ( dot(m0*m0, vec3( dot( p0, x0 ), dot( p1, x1 ), dot( p2, x2 )))
               + dot(m1*m1, vec2( dot( p3, x3 ), dot( p4, x4 ) ) ) ) ;

  }

// #include <worley>
// Cellular noise ("Worley noise") in 2D in GLSL.
// Copyright (c) Stefan Gustavson 2011-04-19. All rights reserved.
// This code is released under the conditions of the MIT license.
// See LICENSE file for details.
// https://github.com/stegu/webgl-noise
// Modulo 289 without a division (only multiplications)
vec3 worley_mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 worley_mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

// Modulo 7 without a division
vec3 worley_mod7(vec3 x) {
  return x - floor(x * (1.0 / 7.0)) * 7.0;
}

// Permutation polynomial: (34x^2 + x) mod 289
vec3 worley_permute(vec3 x) {
  return worley_mod289((34.0 * x + 1.0) * x);
}

// Cellular noise, returning F1 and F2 in a vec2.
// 3x3x3 search region for good F2 everywhere, but a lot
// slower than the 2x2x2 version.
// The code below is a bit scary even to its author,
// but it has at least half decent performance on a
// modern GPU. In any case, it beats any software
// implementation of Worley noise hands down.
vec2 worleyNoise(vec3 P) {
    float K = 0.142857142857; // 1/7
    float Ko = 0.428571428571; // 1/2-K/2
    float K2 = 0.020408163265306; // 1/(7*7)
    float Kz = 0.166666666667; // 1/6
    float Kzo = 0.416666666667; // 1/2-1/6*2
    float jitter = 1.0; // smaller jitter gives more regular pattern

    vec3 Pi = worley_mod289(floor(P));
     vec3 Pf = fract(P) - 0.5;

    vec3 Pfx = Pf.x + vec3(1.0, 0.0, -1.0);
    vec3 Pfy = Pf.y + vec3(1.0, 0.0, -1.0);
    vec3 Pfz = Pf.z + vec3(1.0, 0.0, -1.0);

    vec3 p = worley_permute(Pi.x + vec3(-1.0, 0.0, 1.0));
    vec3 p1 = worley_permute(p + Pi.y - 1.0);
    vec3 p2 = worley_permute(p + Pi.y);
    vec3 p3 = worley_permute(p + Pi.y + 1.0);

    vec3 p11 = worley_permute(p1 + Pi.z - 1.0);
    vec3 p12 = worley_permute(p1 + Pi.z);
    vec3 p13 = worley_permute(p1 + Pi.z + 1.0);

    vec3 p21 = worley_permute(p2 + Pi.z - 1.0);
    vec3 p22 = worley_permute(p2 + Pi.z);
    vec3 p23 = worley_permute(p2 + Pi.z + 1.0);

    vec3 p31 = worley_permute(p3 + Pi.z - 1.0);
    vec3 p32 = worley_permute(p3 + Pi.z);
    vec3 p33 = worley_permute(p3 + Pi.z + 1.0);

    vec3 ox11 = fract(p11*K) - Ko;
    vec3 oy11 = worley_mod7(floor(p11*K))*K - Ko;
    vec3 oz11 = floor(p11*K2)*Kz - Kzo; // p11 < 289 guaranteed

    vec3 ox12 = fract(p12*K) - Ko;
    vec3 oy12 = worley_mod7(floor(p12*K))*K - Ko;
    vec3 oz12 = floor(p12*K2)*Kz - Kzo;

    vec3 ox13 = fract(p13*K) - Ko;
    vec3 oy13 = worley_mod7(floor(p13*K))*K - Ko;
    vec3 oz13 = floor(p13*K2)*Kz - Kzo;

    vec3 ox21 = fract(p21*K) - Ko;
    vec3 oy21 = worley_mod7(floor(p21*K))*K - Ko;
    vec3 oz21 = floor(p21*K2)*Kz - Kzo;

    vec3 ox22 = fract(p22*K) - Ko;
    vec3 oy22 = worley_mod7(floor(p22*K))*K - Ko;
    vec3 oz22 = floor(p22*K2)*Kz - Kzo;

    vec3 ox23 = fract(p23*K) - Ko;
    vec3 oy23 = worley_mod7(floor(p23*K))*K - Ko;
    vec3 oz23 = floor(p23*K2)*Kz - Kzo;

    vec3 ox31 = fract(p31*K) - Ko;
    vec3 oy31 = worley_mod7(floor(p31*K))*K - Ko;
    vec3 oz31 = floor(p31*K2)*Kz - Kzo;

    vec3 ox32 = fract(p32*K) - Ko;
    vec3 oy32 = worley_mod7(floor(p32*K))*K - Ko;
    vec3 oz32 = floor(p32*K2)*Kz - Kzo;

    vec3 ox33 = fract(p33*K) - Ko;
    vec3 oy33 = worley_mod7(floor(p33*K))*K - Ko;
    vec3 oz33 = floor(p33*K2)*Kz - Kzo;

    vec3 dx11 = Pfx + jitter*ox11;
    vec3 dy11 = Pfy.x + jitter*oy11;
    vec3 dz11 = Pfz.x + jitter*oz11;

    vec3 dx12 = Pfx + jitter*ox12;
    vec3 dy12 = Pfy.x + jitter*oy12;
    vec3 dz12 = Pfz.y + jitter*oz12;

    vec3 dx13 = Pfx + jitter*ox13;
    vec3 dy13 = Pfy.x + jitter*oy13;
    vec3 dz13 = Pfz.z + jitter*oz13;

    vec3 dx21 = Pfx + jitter*ox21;
    vec3 dy21 = Pfy.y + jitter*oy21;
    vec3 dz21 = Pfz.x + jitter*oz21;

    vec3 dx22 = Pfx + jitter*ox22;
    vec3 dy22 = Pfy.y + jitter*oy22;
    vec3 dz22 = Pfz.y + jitter*oz22;

    vec3 dx23 = Pfx + jitter*ox23;
    vec3 dy23 = Pfy.y + jitter*oy23;
    vec3 dz23 = Pfz.z + jitter*oz23;

    vec3 dx31 = Pfx + jitter*ox31;
    vec3 dy31 = Pfy.z + jitter*oy31;
    vec3 dz31 = Pfz.x + jitter*oz31;

    vec3 dx32 = Pfx + jitter*ox32;
    vec3 dy32 = Pfy.z + jitter*oy32;
    vec3 dz32 = Pfz.y + jitter*oz32;

    vec3 dx33 = Pfx + jitter*ox33;
    vec3 dy33 = Pfy.z + jitter*oy33;
    vec3 dz33 = Pfz.z + jitter*oz33;

    vec3 d11 = dx11 * dx11 + dy11 * dy11 + dz11 * dz11;
    vec3 d12 = dx12 * dx12 + dy12 * dy12 + dz12 * dz12;
    vec3 d13 = dx13 * dx13 + dy13 * dy13 + dz13 * dz13;
    vec3 d21 = dx21 * dx21 + dy21 * dy21 + dz21 * dz21;
    vec3 d22 = dx22 * dx22 + dy22 * dy22 + dz22 * dz22;
    vec3 d23 = dx23 * dx23 + dy23 * dy23 + dz23 * dz23;
    vec3 d31 = dx31 * dx31 + dy31 * dy31 + dz31 * dz31;
    vec3 d32 = dx32 * dx32 + dy32 * dy32 + dz32 * dz32;
    vec3 d33 = dx33 * dx33 + dy33 * dy33 + dz33 * dz33;

    // Sort out the two smallest distances (F1, F2)
    vec3 d1a = min(d11, d12);
    d12 = max(d11, d12);
    d11 = min(d1a, d13); // Smallest now not in d12 or d13
    d13 = max(d1a, d13);
    d12 = min(d12, d13); // 2nd smallest now not in d13
    vec3 d2a = min(d21, d22);
    d22 = max(d21, d22);
    d21 = min(d2a, d23); // Smallest now not in d22 or d23
    d23 = max(d2a, d23);
    d22 = min(d22, d23); // 2nd smallest now not in d23
    vec3 d3a = min(d31, d32);
    d32 = max(d31, d32);
    d31 = min(d3a, d33); // Smallest now not in d32 or d33
    d33 = max(d3a, d33);
    d32 = min(d32, d33); // 2nd smallest now not in d33
    vec3 da = min(d11, d21);
    d21 = max(d11, d21);
    d11 = min(da, d31); // Smallest now in d11
    d31 = max(da, d31); // 2nd smallest now not in d31
    d11.xy = (d11.x < d11.y) ? d11.xy : d11.yx;
    d11.xz = (d11.x < d11.z) ? d11.xz : d11.zx; // d11.x now smallest
    d12 = min(d12, d21); // 2nd smallest now not in d21
    d12 = min(d12, d22); // nor in d22
    d12 = min(d12, d31); // nor in d31
    d12 = min(d12, d32); // nor in d32
    d11.yz = min(d11.yz,d12.xy); // nor in d12.yz
    d11.y = min(d11.y,d12.z); // Only two more to go
    d11.y = min(d11.y,d11.z); // Done! (Phew!)
    return sqrt(d11.xy); // F1, F2
}

// Main script

const float startDistance = 3.325;
const float hRot = -3.0;
const float vRot = 0.0;
const float refractEta = 0.875;
const int RAYSTEPS = 128;
const int REFLECTIONS = 4;
const float EPSILON = 0.001;

#define SHTIME time
#define TIME (2.5*(2.0*SHTIME+0.9*sin(1.5+2.0*SHTIME)))

struct Sphere {
    vec3 center;
    float r;
    vec3 color1, color2;
};

float sphereSDF(vec3 p, Sphere s) {
    return distance(p, s.center)-s.r;
}

vec3 sphereNormal(vec3 p, Sphere s) {
    return normalize(p-s.center);
}

float planeSDF(vec3 p) {
    return p.y;
}

vec3 planeNormal(vec3 p) {
    return vec3(0.0, 1.0, 0.0);
}

float fbm(vec4 p) {
    float total = 0.0;
    float s = 1.0;
    total += 0.5*perlinNoise(s*p);
    total += 0.25*perlinNoise(2.0*s*p);
    total += 0.125*perlinNoise(4.0*s*p);
    total += 0.0625*perlinNoise(8.0*s*p);
    return total;
}

float wnt(vec3 p) {
    vec2 w = worleyNoise(p);
    return w.y/w.x-1.5;
}

float fworley(vec3 p) {
    float total = 0.0;
    float s = 4.0;
    total += 0.5*wnt(s*p);
    total += 0.25*wnt(2.0*s*p);
    total += 0.125*wnt(4.0*s*p);
    total += 0.0625*wnt(8.0*s*p);
    //total += worleyNoise(16.0*s*p).x;
    return total;
}

float marble(vec3 p) {
    //vec4 p4 = vec4(p, 0.015625*SHTIME);
    vec4 p4 = vec4(p.xz, (-1.0+p.y)*vec2(sin(0.5*SHTIME), cos(0.5*SHTIME)));
    p4 += fbm(p4);
    p4 += fbm(p4);
    return 0.5*(fbm(p4)+1.0);
    //return 0.5*(fbm(p)+1.0);
}

vec4 shader(vec2 pos) {
    float rhrot = hRot+0.1*TIME;
    vec3 start = rotateY(vec3(0.0, 0.7, -startDistance), rhrot);
    vec3 direction = rotateY(normalize(vec3((2.0*pos-1.0)*vec2(1.0, resolution.y/resolution.x), 1.0)), rhrot);
    vec3 lightDirection = normalize(vec3(2.0, -1.0, 3.0));
    vec3 color = vec3(0.0);

    Sphere sphere0, sphere1, sphere2, sphere3;
    sphere0.center = vec3(0.0, 1.0, 0.0); sphere0.r = 1.0; sphere0.color1 = vec3(1.0, 0.0, 0.125); sphere0.color2 = vec3(1.0, 1.0, 0.125);
    sphere1.center = vec3(-1.0, 0.75, -1.5); sphere1.r = 0.75; sphere1.color1 = vec3(0.125, 0.125, 0.125); sphere1.color2 = vec3(0.25, 0.125, 0.0);
    sphere2.center = vec3(+1.0, 0.5, -1.0); sphere2.r = 0.5; sphere2.color1 = vec3(0.0, 0.125, 0.25); sphere2.color2 = vec3(0.0625, 0.185, 0.25);
    sphere3.center = vec3(0.0, -64.0, 0.0); sphere3.r = 64.0; sphere3.color1 = vec3(1.0); sphere3.color2 = vec3(1.0);

    int ignore = 0;
    vec3 p = start;

    float atten = 1.0;
    for (int h = 0; h < REFLECTIONS; ++h) {
        vec3 normal;
        vec3 difColor1 = vec3(1.0);
        vec3 difColor2 = vec3(1.0);
        float ripple = 0.0;
        bool hit = false;
        bool seeThrough = false;
        float natten = atten;
        float emissive = 0.0;
        for (int i = 0; i < RAYSTEPS; ++i) {
            if (length(p) >= 256.0)
                break;

            float distance = 99999999.9;

            if (ignore != 1) {
                //distance = planeSDF(p);
                distance = sphereSDF(p, sphere3);
                if (distance < EPSILON) {
                    hit = true;
                    //normal = planeNormal(p);
                    normal = sphereNormal(p, sphere3);
                    ripple = 0.0625;
                    ignore = 1;
                    break;
                }
            }

            if (ignore != 2) {
                distance = min(distance, sphereSDF(p, sphere0));
                if (distance < EPSILON) {
                    hit = true;
                    normal = sphereNormal(p, sphere0);
                    difColor1 = sphere0.color1;
                    difColor2 = sphere0.color2;
                    natten *= 0.25;
                    emissive = 1.0;
                    ignore = 2;
                    break;
                }
            }

            if (ignore != 3) {
                distance = min(distance, sphereSDF(p, sphere1));
                if (distance < EPSILON) {
                    hit = true;
                    normal = sphereNormal(p, sphere1);
                    difColor1 = sphere1.color1;
                    difColor2 = sphere1.color2;
                    ignore = 3;
                    break;
                }
            }

            if (ignore != 4) {
                distance = min(distance, sphereSDF(p, sphere2));
                if (distance < EPSILON) {
                    hit = true;
                    seeThrough = true;
                    normal = sphereNormal(p, sphere2);
                    difColor1 = sphere2.color1;
                    difColor2 = sphere2.color2;
                    ignore = 4;
                    break;
                }
            }

            p += distance*direction;

        }

        if (hit) {
            // SHADOW
            vec3 sp = p;
            float shadow = 1.0;
            float highlight = 0.0;
            for (int i = 0; i < RAYSTEPS; ++i) {

                float sdistance = 99999999.9;

                if (ignore != 1) sdistance = sphereSDF(sp, sphere3); //planeSDF(sp);
                if (ignore != 2) sdistance = min(sdistance, sphereSDF(sp, sphere0));
                if (ignore != 3) sdistance = min(sdistance, sphereSDF(sp, sphere1));
                float prevSdist = sdistance;
                if (ignore != 4) sdistance = min(sdistance, sphereSDF(sp, sphere2));
                if (sdistance < 0.03125) {
                    float shadeDist = distance(p, sp);
                    shadow = 1.0-1.0/(1.0+shadeDist);
                    if (prevSdist != sdistance) {
                        // refract light instead of block
                        vec3 nd = refract(-lightDirection, sphereNormal(sp, sphere2), refractEta);
                        highlight = pow(max(0.0, dot(nd, -lightDirection)), 4096.0)*(1.0-shadow);
                        shadow = 1.0-0.5*(1.0-shadow);
                    }
                    break;
                }

                sp -= sdistance*lightDirection;

            }

            float marblePattern = marble(p);
            float diffuse = 0.03125+max(0.0, dot(lightDirection, -normal));
            if (seeThrough)
                direction = normalize(refract(direction, normal, refractEta)+ripple*perlinNoise(8.0*p));
            else
                direction = normalize(reflect(direction, normal)+ripple*perlinNoise(8.0*p));
            vec3 emit = 4.0*emissive*difColor1*max(0.0, marblePattern-0.5);
            //float specular = pow(max(0.0, dot(lightDirection, -direction)), 16.0);
            color += (emit+highlight+shadow*(mix(difColor1, difColor2, marblePattern)*diffuse)/(1.0+0.5*distance(start, p)))*atten;
            //return vec4(0.5*(normal+1.0), 1.0);
        } else {
            color += 0.5*vec3(0.1, 0.0, 0.1)*atten*fworley(normalize(p-start)-0.125*lightDirection*cos(SHTIME));
            float sun = 0.0;
            sun += 0.9375*pow(max(0.0, dot(direction, -lightDirection)), 16.0+sin(16.0*SHTIME));
            color += sun*vec3(1.5, 0.8, 0.4)*atten;
            break;
        }

        atten = natten;
    }

    return vec4(color, 1.0);
}

void main(void) {
    glFragColor = shader(gl_FragCoord.xy/resolution.xy);
}
