#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3llGzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 J. M.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// demo of using an experimental implementation of 3D Worley noise to texture a surface

// modified MATLAB bone colormap

vec3 bone( float t )
{
     return 0.875 * t + 0.125 * clamp(vec3(4.0, 3.0, 3.0) * t - vec3(3.0, 1.0, 0.0), 0.0, 1.0);
}

// rescaling function

float rescale(float x, vec2 range)
{
      float a = range.x, b = range.y;
      return (x - a)/(b - a);
}

// simple LCG

#define LCG(k) k = (65 * k) % 1021
#define lr(k) float(k)/1021.

// permutation polynomial

int permp (int i1, int i2)
{
      int t = (i1 + i2) & 255;
        
      return ((112 * t + 153) * t + 151) & 255;
}

// return the two closest distances for 3D Worley noise
// type controls the type of metric used

vec2 worley(int type, vec3 p)
{
    vec2 dl = vec2(20.0);
    ivec3 iv = ivec3(floor(p));
    vec3 fv = fract(p);
    
    int j = 0; // initialization for Knuth's "algorithm L"
    ivec3 di = ivec3(1), ki = -di;
    ivec4 fi = ivec4(0, 1, 2, 3);
    
    // instead of writing a triply nested loop (!!)
    // generate the indices for the neighbors in Gray order (Knuth's "algorithm L")
    // see section 7.2.1.1 of TAOCP, Volume 4A or https://doi.org/10.1145/360336.360343
    
    for (int k = 0; k < 27; k++) // loop through all neighbors
    { 
         // seeding
        int s = permp(permp(permp(0, iv.z + ki.z), iv.y + ki.y), iv.x + ki.x); LCG(s);
            
         for (int m = 0; m < 2; m++) // two points per cell
             {
                // generate feature points within the cell
                LCG(s); float sz = lr(s);
                LCG(s); float sy = lr(s);
                LCG(s); float sx = lr(s);
                
                vec3 tp = vec3(ki) + vec3(sx, sy, sz) - fv;
                float c = 0.0;
                if (type == 1) c = dot(tp, tp); // Euclidean metric
                if (type == 2) c = abs(tp.x) + abs(tp.y) + abs(tp.z); // Manhattan metric
                if (type == 3) c = max(abs(tp.x), max(abs(tp.y), abs(tp.z))); // Chebyshev metric
                
                float m1 = min(c, dl.x); // ranked distances
                dl = vec2(min(m1, dl.y), max(m1, min(max(c, dl.x), dl.y)));
             }
        
        // updating steps for Knuth's "algorithm L"
        j = fi[0]; fi[0] = 0; ki[2 - j] += di[j];
        if ((ki[2 - j] & 1) == 1) {
            di[j] = -di[j];
            fi[j] = fi[j + 1]; fi[j + 1] = j + 1;
        }
    }
    
    if (type == 1) dl = sqrt(dl); // don't forget to root at the end for Euclidean distance
        
    return dl;
}

// raytracing demo code adapted from Inigo Quilez, https://www.shadertoy.com/view/4sfGzS

const mat3 m = mat3( 0.00,  0.80,  0.60,
                    -0.80,  0.36, -0.48,
                    -0.60, -0.48,  0.64 );

void main(void)
{
    vec2 p = (-resolution.xy + 2.0 * gl_FragCoord.xy) / resolution.y;

     // camera movement    
    float an = 0.5 * time;
    vec3 ro = vec3( 2.5 * cos(an), 1.0, 2.5 * sin(an) );
    vec3 ta = vec3( 0.0, 1.0, 0.0 );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww, vec3(0.0, 1.0, 0.0) ) );
    vec3 vv = normalize( cross(uu, ww));
    // create view ray
    vec3 rd = normalize( p.x * uu + p.y * vv + 1.5 * ww );

    // sphere center    
    vec3 sc = vec3(0.0, 1.0, 0.0);

    // raytrace
    float tmin = 1.0e4;
    vec3  nor = vec3(0.0);
    float occ = 1.0;
    vec3  pos = vec3(0.0);
    
    // raytrace-plane
    float h = (0.0 - ro.y)/rd.y;
    if( h > 0.0 ) 
    { 
        tmin = h; 
        nor = vec3(0.0, 1.0, 0.0); 
        pos = ro + h * rd;
        vec3 di = sc - pos;
        float l = length(di);
        occ = 1.0 - dot(nor, di/l) * 1.0 * 1.0/(l * l); 
    }

    // raytrace-sphere
    vec3  ce = ro - sc;
    float b = dot( rd, ce );
    float c = dot( ce, ce ) - 1.0;
    h = b * b - c;
    if( h > 0.0 )
    {
        h = -b - sqrt(h);
        if( h < tmin ) 
        { 
            tmin = h; 
            nor = normalize(ro + h * rd - sc); 
            occ = 0.5 + 0.5 * nor.y;
        }
    }

    // shading/lighting    
    vec3 col = vec3(0.9);
    if( tmin < 100.0 )
    {
        pos = ro + tmin * rd;
        float f = 0.0;
        int type = int(0.05 * time) % 3 + 1;
        
        if( p.x < 0.0 )
        {
            vec2 w = worley(type, 4.0 * pos);
            f = length(w.xy)/(w.y + w.x) - w.x;
        }
        else
        {
            vec3 q = 2.0 * pos; // three octaves
            vec2 w = worley(type, q);
            f  = 2.0 * (w.y - w.x); q = m * q * 2.01;
            w = worley(type, q);
            f += 0.5 * (w.y - w.x); q = m * q * 2.02;
            w = worley(type, q);
            f += 0.25 * (w.y - w.x);
            f *= 0.75;
        }        
        
        f = smoothstep( -0.7, 0.7, f );
        f *= occ;
        col = bone(rescale(f, vec2(0.0, 2.8)));
        col = mix( col, vec3(0.9), 1.0 - exp( -0.004 * tmin * tmin ) );
    }
    
    col = sqrt( col );
    
    col *= smoothstep( 0.006, 0.008, abs(p.x) );
    
    glFragColor = vec4( col, 1.0 );
}
