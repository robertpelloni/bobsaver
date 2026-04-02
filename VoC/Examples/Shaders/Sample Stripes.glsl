#version 420

// original https://www.shadertoy.com/view/Xtt3WS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

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

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x) {
     return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v)
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
  i = mod289(i); 
  vec4 p = permute( permute( permute( 
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
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
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
 

vec3 sph2cart(float r, float theta, float phi)
{
   return  vec3(r * cos(theta) * sin(phi),
         r * sin(theta) * sin(phi),    
         r * cos(phi));
}

float sph(float rad, vec3 center, vec3 p)
{
    return length(p - center) - rad;   
}

float DE(vec3 p) 
{
  float theta = 30.0; 2.4;
  float phi = 100.0; // 2.4;// + time;

   float mind = sph(1.0, vec3(0.0), p);
    
   for(int i = 0; i < 40; i ++)
   {
       theta += 0.1;
       phi += time/20.;
       
     mind = min(mind,  sph(0.001 * pow(float(i/2 ), 2.0), sph2cart(1.0, theta, phi), p) );
   }
    return mind;
}
    
vec3 grad(vec3 p)
{
    vec2 e = vec2(0.01, 0.0);
    
     return normalize(vec3( DE(p + e.xyy) - DE(p - e.xyy), 
                          DE(p + e.yxy) - DE(p - e.yxy), 
                          DE(p + e.yyx) - DE(p - e.yyx)));
    
    
}

    
void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec2 uv_n = 2.5 * (uv - 0.5) * vec2(1.0, resolution.y / resolution.x) ; 
        
    vec3 cam = vec3(0.0, 0.0, -2);
    
    vec3 ray = normalize(vec3( uv_n, 1.0));
    float t = 0.0;
    float d = 0.0;
    vec3 p = cam;
    float iter = 0.0;
    bool hit = false;
    
    for ( int i = 0; i < 20; i ++) 
    {
        p = t * ray + cam;
    
        d = DE(p);
        
        if ( d < 0.01) {
            hit = true;
            break;

        }
        
        t += d;
        iter++;
        
    }
               vec3 normal = grad(p );

    float st;
    
    vec3 color = vec3(1.0);
    if (!hit){
        iter = 0.5;
        st = 1.0;
    }
    else
    {
           st =  fract((p.y + p.x + snoise(p)/3.0 - time/10.0 ) * 6. ) < 0.5? 0.0 : 1.0;
        float thickness = sin(p.x * 10.) / 10.0 + 0.2;
        
        
        //st = abs(sin(10. * (p.y + p.x )));
        
        //st = snoise(p * 4.0 + time);
         
        float shade = 1.0;// abs(dot(ray, normal));
        
        color = vec3(st) * shade;

    }
    

    glFragColor = vec4(color , 1.0);
    
    
    
}
