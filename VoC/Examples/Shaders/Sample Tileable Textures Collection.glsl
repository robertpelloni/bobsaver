#version 420

// original https://www.shadertoy.com/view/3sKXWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 Alin Loghin
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#define SCALE   8.0 
#define TILES   3.0     

#define SHOW_TILING 1       
#define ANIMATE 1       

float hash(const in float x)
{ 
    return fract(sin(x) * 43758.5453123);
}

float hash(const in vec2 x) 
{ 
    return fract(sin(dot(x, vec2(12.9898, 4.1414))) * 43758.5453); 
}

vec2 hash2d(const in vec2 x)
{
    vec2 q = vec2(dot(x,vec2(127.1,311.7)), 
                  dot(x,vec2(269.5,183.3)));
    return fract(sin(q)*43758.5453);
}

vec3 hash3d(const in vec2 x)
{
    vec3 q = vec3( dot(x, vec2(127.1,311.7)), 
                   dot(x, vec2(269.5,183.3)), 
                   dot(x, vec2(419.2,371.9)));
    return fract(sin(q) * 43758.5453);
}

vec3 permute(const in vec3 x) 
{ 
    return mod(((x * 34.0) + 1.0) * x * 1.0, 289.0); 
}

vec4 permute(const in vec4 x) 
{ 
    return mod(((x * 34.0) + 1.0) * x * 1.0, 289.0); 
}

vec2 smootherStep(const in vec2 x) 
{ 
    vec2 x2 = x * x;
    return x2 * x * (x * (x * 6.0 - 15.0) + 10.0); 
}

float noise(const in vec2 pos, const in vec2 scale) 
{
    // classic value noise
    vec2 p = mod(pos * floor(scale), scale);
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(mod(i + vec2(1.0, 0.0), scale));
    float c = hash(mod(i + vec2(0.0, 1.0), scale));
    float d = hash(mod(i + vec2(1.0, 1.0), scale));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float gradientNoise(const in vec2 pos, const in vec2 scale) 
{
    // classic gradient noise
    vec2 p = mod(pos * floor(scale), scale);
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    vec2 a = hash2d(i);
    vec2 b = hash2d(mod(i + vec2(1.0, 0.0), scale));
    vec2 c = hash2d(mod(i + vec2(0.0, 1.0), scale));
    vec2 d = hash2d(mod(i + vec2(1.0, 1.0), scale));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    float ab = mix(dot(a, f - vec2(0.0, 0.0)), dot(b, f - vec2(1.0, 0.0)), u.x);
    float cd = mix(dot(c, f - vec2(0.0, 1.0)), dot(d, f - vec2(1.0, 1.0)), u.x);
    return 2.3 * mix(ab, cd, u.y);
}

float perlinNoise(const in vec2 pos, const in vec2 scale)
{
    // classic Perlin noise based on Stefan Gustavson
    vec2 p = pos * floor(scale);
    vec4 i = mod(floor(p.xyxy) + vec4(0.0, 0.0, 1.0, 1.0), scale.xyxy);
    vec4 f = fract(p.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
    i = mod(i, 289.0); // avoid truncation effects in permutation
    
    vec4 ix = i.xzxz;
    vec4 iy = i.yyww;
    vec4 fx = f.xzxz;
    vec4 fy = f.yyww;
    
    vec4 ixy = permute(permute(ix) + iy);
    vec4 gx = 2.0 * fract(ixy * 0.0243902439) - 1.0; // 1/41 = 0.024...
    vec4 gy = abs(gx) - 0.5;
    vec4 tx = floor(gx + 0.5);
    gx = gx - tx;
    
    vec2 g00 = vec2(gx.x,gy.x);
    vec2 g10 = vec2(gx.y,gy.y);
    vec2 g01 = vec2(gx.z,gy.z);
    vec2 g11 = vec2(gx.w,gy.w);
    
    vec4 norm = 1.79284291400159 - 0.85373472095314 * 
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
    g00 *= norm.x;
    g01 *= norm.y;
    g10 *= norm.z;
    g11 *= norm.w;
    float n00 = dot(g00, vec2(fx.x, fy.x));
    float n10 = dot(g10, vec2(fx.y, fy.y));
    float n01 = dot(g01, vec2(fx.z, fy.z));
    float n11 = dot(g11, vec2(fx.w, fy.w));
    
    vec2 fade_xy = smootherStep(f.xy);
    vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
    float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
    return 2.3 * n_xy;
}

vec2 cellularNoise(const in vec2 pos, const in vec2 scale, const in float jitter) 
{       
    // classic cellular/voronoi noise
    vec2 p = pos * floor(scale) + 0.5;
    vec2 i = floor(p);
    vec2 f = fract(p);

    vec2 distances = vec2(1.0);
    for (int y=-1; y<=1; y++)
    {
        for (int x=-1; x<=1; x++)
        {
            vec2 n = vec2(float(x), float(y));
            vec2 cPos = hash2d(mod(i + n, scale)) * jitter;
            vec2 rPos = n + cPos - f;

            float d = length(rPos);
            if(d < distances.x)
            {
                distances.y = distances.x;
                distances.x = d;
            }
            else if(d < distances.y)
            {
                distances.y = d;
            }
        }
    }
    return sqrt(distances);
}

float metaballs(const in vec2 pos, const in vec2 scale, const in float jitter) 
{       
    // classic cellular/voronoi noise
    vec2 p = pos * floor(scale) + 0.5;
    vec2 i = floor(p);
    vec2 f = fract(p);

    float minDistance = 1.0;
    for (int y=-1; y<=1; y++)
    {
        for (int x=-1; x<=1; x++)
        {
            vec2 n = vec2(float(x), float(y));
            vec2 cPos = hash2d(mod(i + n, scale)) * jitter;
            vec2 rPos = n + cPos - f;

            float d = length(rPos);
            minDistance = min(minDistance, minDistance * d);
        }
    }
    return minDistance;
}

float voronoi(const in vec2 pos, const in vec2 scale, const in float jitter, out vec2 tilePos, out vec2 relativePos)
{
    // voronoi based on Inigo Quilez
    vec2 p = pos * floor(scale);
    vec2 i = floor(p);
    vec2 f = fract(p);

    // first pass
    vec2 minPos;
    float minDistance = 1e+5;
    for (int y=-1; y<=1; y++)
    {
        for (int x=-1; x<=1; x++)
        {
            vec2 n = vec2(float(x), float(y));
            vec2 cPos = hash2d(mod(i + n, scale)) * jitter;
            vec2 rPos = n + cPos - f;

            float d = dot(rPos, rPos);
            if(d < minDistance)
            {
                minDistance = d;
                minPos = rPos;
                tilePos = cPos;
            }
        }
    }
    relativePos = minPos;

    // second pass, distance to borders
    minDistance = 1e+5;
    for (int y=-2; y<=2; y++)
    {
        for (int x=-2; x<=2; x++)
        { 
            vec2 n = vec2(float(x), float(y));
            vec2 cPos = hash2d(mod(i + n, scale)) * jitter;
            vec2 rPos = n + cPos - f;
            
            vec2 v = minPos - rPos;
            if(dot(v, v) > 1e-5)
                minDistance = min(minDistance, dot( 0.5 * (minPos + rPos), normalize(rPos - minPos)));
        }
    }

    return minDistance;
}

vec3 checkers45(const in vec2 pos, const in vec2 scale, const in vec2 smoothness)
{
    // based on filtering the checkerboard by Inigo Quilez 
    vec2 p = pos * floor(scale) * 2.0;
    vec2 tile = floor(p);
    
    const float angle = 3.14152 / 4.0;
    const float cosAngle = cos(angle);
    const float sinAngle = sin(angle);

    p *= 1.0 / sqrt(2.0);
    p = p * mat2(cosAngle, sinAngle, -sinAngle, cosAngle);
    tile = mod(floor(p), scale);
    
    vec2 w = smoothness;
    // box filter using triangular signal
    vec2 s1 = abs(fract((p - 0.5 * w) / 2.0) - 0.5);
    vec2 s2 = abs(fract((p + 0.5 * w) / 2.0) - 0.5);
    vec2 i = 2.0 * (s1 - s2) / w;
    float d = 0.5 - 0.5 * i.x * i.y; // xor pattern
    return vec3(d, tile);
}

float fbmNoise(const in vec2 pos, const in vec2 scale, const in float angle) 
{
    // based on classic value noise
    vec2 i = floor(pos);
    vec2 f = fract(pos);

    float cosAngle = cos(angle); 
    float sinAngle = sin(angle); 
    mat2 rot = mat2(cosAngle, sinAngle,-sinAngle, cosAngle);
    
    float a = hash(rot * i);
    float b = hash(rot * mod(i + vec2(1.0, 0.0), scale));
    float c = hash(rot * mod(i + vec2(0.0, 1.0), scale));
    float d = hash(rot * mod(i + vec2(1.0, 1.0), scale));

    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm(const in vec2 pos, const in vec2 scale, const int octaves, const float shift, const float axialShift) 
{
    // classic fbm implementation
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 0.0;
    float angle = axialShift;
    
    vec2 s = floor(scale);
    vec2 p = mod(pos * s, s);
    for (int i = 0; i < 15; i++) 
    {
        value += amplitude * fbmNoise(p, s, angle);
        
        p = p * 2.0 + shift;
        s *= 2.0;
        p = mod(p, s);
        amplitude *= 0.5;
        angle += axialShift;
    }
    return value;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.y;
    vec2 p = fract(uv * TILES);
    vec2 scale = vec2(SCALE);

#if ANIMATE == 1
    p += time * 0.03;
#endif

    vec3 col;
    float current = mod(time * 0.5, 8.0);
    if(current < 1.0)
    {
        vec2 cells = cellularNoise(p, scale, 1.0);
        col = vec3(cells.y - cells.x);
    }
    else if(current < 2.0)
    {
        col = vec3(noise(p, scale));
    }
    else if(current < 3.0)
    {
        vec2 tilePos;
        vec2 relativePos;
        float d = voronoi(p, scale, 1.0, tilePos, relativePos);
        col = vec3(smoothstep(0.02, 0.09, d));
        col *= hash3d(tilePos) * (1.0 - length(relativePos) * 0.5);
    }
    else if(current < 4.0)
    {
        col = vec3(perlinNoise(p, scale));
    }
    else if(current < 5.0)
    {
       vec3 c = checkers45(p, scale, vec2(0.51));
       col = vec3(c.x);
       col *= hash3d(c.yz + 1.0);
    }
    else if(current < 6.0)
    {
        col = vec3(metaballs(p, scale, 1.0));
        col = smoothstep(0.1, 0.2, col);
    }
    else if(current < 7.0)
    {
        col = vec3(fbm(p, scale, 16, 0.75, 0.5));
    }
    else if(current < 8.0)
    {
        col = vec3(gradientNoise(p, scale));
    }
    
#if SHOW_TILING == 1
    vec2 pixel = vec2(TILES) / resolution.xy;
    uv *= TILES;

    vec2 first = step(pixel, uv) * floor(mod(time * 0.75, 4.0)) * 0.25;        
    uv  = step(fract(uv), pixel);               
    col = mix(col, vec3(0.0, 1.0, 0.0), (uv.x + uv.y) * first.x * first.y);
#endif

    glFragColor = vec4(col, 1.0);
}
