#version 420

// original https://www.shadertoy.com/view/WtB3Wt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2019 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// I raymarched a 3D slice of a 4D box. The 3D slice (plane) that cuts the
// 4D box is animated over time, and the cube itself is rotating in 4D space.
// Note this is NOT 4D raymarching, it is 3D raymarching (of a 3D slice of a
// 4D world).

#define AA 2  // reduce this to 1 if you have a slow machine

float sdBox( in vec4 p, in vec4 b )
{
    vec4 d = abs(p) - b;
    return min( max(max(d.x,d.y),max(d.z,d.w)),0.0) + length(max(d,0.0));
}

mat4x4 q2m( in vec4 q )
{
    return mat4x4( q.x, -q.y, -q.z, -q.w,
                   q.y,  q.x, -q.w,  q.z,
                   q.z,  q.w,  q.x, -q.y,
                   q.w, -q.z,  q.y, q.x );
}

float map( in vec3 pos )
{
    // take a 3D slice
    vec4 p = vec4(pos,0.5*sin(time*0.513));
    
    // rotate 3D point into 4D
    vec4 q1 = normalize( cos( 0.2*time*vec4(1.0,1.7,1.1,1.5) + vec4(0.0,1.0,5.0,4.0) ) );
    vec4 q2 = normalize( cos( 0.2*time*vec4(1.9,1.7,1.4,1.3) + vec4(3.0,2.0,6.0,5.0) ) );
    p = q2m(q2)*p*q2m(q1);
    
    // 4D box
    return sdBox( p, vec4(0.8,0.5,0.7,0.2) );
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.00025;
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
                      e.yyx*map( pos + e.yyx*eps ) + 
                      e.yxy*map( pos + e.yxy*eps ) + 
                      e.xxx*map( pos + e.xxx*eps ) );
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<128; i++ )
    {
        float h = map( ro + rd*t );
        res = min( res, 16.0*h/t );
        t += clamp( h, 0.01, 0.25 );
        if( res<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec2 intersect( in vec3 ro, in vec3 rd )
{
    vec2 res = vec2(1e20,-1.0);
    
    // plane
    {
    float t = (-1.0-ro.y)/rd.y;
    if( t>0.0 ) res = vec2(t,1.0);
    }

    {
    // box
    float tmax = min(6.0,res.x);
    float t = 0.4;
    for( int i=0; i<128; i++ )
    {
        vec3 pos = ro + t*rd;
        float h = map(pos);
        if( h<0.001 || t>tmax ) break;
        t += h;
    }
    if( t<tmax && t<res.x ) res = vec2(t,2.0);
    }
    
    return res;
}

void main(void)
{
    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(gl_FragCoord.xy+o)-resolution.xy)/resolution.y;
        #else    
        vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
        #endif

        // create view ray
        vec3 ro = vec3(0.0,0.0,3.0);
        vec3 rd = normalize( vec3(p,-1.8) );

        // raymarch
        vec2 tm = intersect( ro, rd );
        vec3 col = vec3(0.65,0.68,0.7) - 0.7*rd.y;
        if( tm.y>0.0 )
        {
            // shading/lighting    
            vec3 pos = ro + tm.x*rd;
            vec3 nor = (tm.y<1.5)?vec3(0.0,1.0,0.0):calcNormal(pos);
            vec3 lig = normalize(vec3(0.8,0.4,0.6));
            float dif = clamp( dot(nor,lig), 0.0, 1.0 );
            vec3  hal = normalize(lig-rd);
            float sha = calcSoftshadow( pos+0.001*nor, lig, 0.001, 4.0 );
            float amb = 0.6 + 0.4*nor.y;
            float spe = clamp(dot(nor,hal),0.0,1.0);
            col  = 1.0*vec3(1.00,0.80,0.60)*dif*sha;
            col += 1.0*vec3(0.12,0.18,0.24)*amb;
            col += 0.2*pow(spe,8.0)*dif*sha;
        }

        // gamma        
        col = sqrt( col );
        tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    glFragColor = vec4( tot, 1.0 );
}
