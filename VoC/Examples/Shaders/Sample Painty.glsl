#version 420

// original https://www.shadertoy.com/view/4dSBDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
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

float fractal_noise(vec3 v, int octaves)
{
    float x = 0.0;
    float a = 0.5;
    float f = 0.0;
    for (int i=0; i<octaves; i++)
    {
        x += a * snoise(v);
        v *= 2.0;
        a *= 0.5;
    }
    return x;
}

float fractal_noise(vec3 v)
{
    return fractal_noise(v, 6);
}

vec3 temp2rgb(float temp)
{
    temp /= 100.0;

    // draper point
    // if (temp <= 8)
        // return vec3(0);

    // if (temp < 10)
        // return mix(vec3(0), vec3(1.0, 0.2663545845364998, 0.0), smoothstep(0, 1, (temp-8)/2.0));

    float red, green, blue;
    
    if (temp <= 66.0) {
        red = 255.0;
    } else {
        red = temp - 60.0;
        red = 329.698727446 * pow(red, -0.1332047592);
        red = clamp(red, 0.0, 255.0);
    }

    if (temp <= 66.0) {
        green = 99.4708025861 * log(temp) - 161.1195681661;
    } else {
        green = temp - 60.0;
        green = 288.1221695283 * pow(green, -0.0755148492);
    }
    green = clamp(green, 0.0, 255.0);

    if (temp >= 66.0) {
        blue = 255.0;
    } else if (temp <= 19.0) {
        blue = 0.0;
    } else {
        blue = temp - 10.0;
        blue = 138.5177312231 * log(blue) - 305.0447927307;
        blue = clamp(blue, 0.0, 255.0);
    }

    return vec3(red, green, blue) / 255.0;
}

float cardinal(float y0, float y1, float y2, float y3, float t, float c)
{
    float t2 = t * t;
    float t3 = t2 * t;
    float h1 = 2.0 * t3 - 3.0 * t2 + 1.0;
    float h2 = -2.0 * t3 + 3.0 * t2;
    float h3 = t3 - 2.0 * t2 + t;
    float h4 = t3 - t2;
    float m1 = c * (y2 - y0);
    float m2 = c * (y3 - y1);
    float r  = m1 * h3 + y1 * h1 + y2 * h2 + m2 * h4;
    return r;
}

vec2 cardinal(vec2 y0, vec2 y1, vec2 y2, vec2 y3, float t, float c)
{
    return vec2(cardinal(y0.x, y1.x, y2.x, y3.x, t, c),
                cardinal(y0.y, y1.y, y2.y, y3.y, t, c));
}

vec3 cardinal(vec3 y0, vec3 y1, vec3 y2, vec3 y3, float t, float c)
{
    return vec3(cardinal(y0.x, y1.x, y2.x, y3.x, t, c),
                cardinal(y0.y, y1.y, y2.y, y3.y, t, c),
                cardinal(y0.z, y1.z, y2.z, y3.z, t, c));
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float scale(float v, float r)
{
    return (v - r) / (1.0 - r);
}

vec3 img(vec2 uv)
{
    vec3 c = vec3(0.0);
    
    if (uv.y > 0.75)
    {
        if (uv.x < 0.25)
            c = cardinal(vec3(0.0), vec3(0.0), temp2rgb(1000.0), temp2rgb(2000.0), 4.0 * uv.x, 0.0);
        else
            c = temp2rgb(1000.0 + scale(uv.x, 0.25) * 5500.0);
    }
    else if (uv.y > 0.5)
    {
        c = vec3(uv.x);
    }
    else if (uv.y > 0.25)
    {
        c = hsv2rgb(vec3(280.0/360.0 - 280.0/360.0 * uv.x, 1.0, 0.5 * uv.x + 0.5));
    }
    else
    {
        c = vec3(0.0, 0.98, 1.0) * uv.x;
    }
    return c;
}

vec3 painty(vec2 uv, float t)
{
    vec3 a = vec3(0.0);
    const int c = 10;
    for (int i=0; i<c; i++) {
        vec2 v = uv + 0.1 * fractal_noise(vec3(uv * 10.0, t - float(i) * 0.016));
        a += img(v) / float(c);
    }
    return a;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    vec3 c = painty(uv, time);
    
    glFragColor = vec4(c, 1.0);
}
