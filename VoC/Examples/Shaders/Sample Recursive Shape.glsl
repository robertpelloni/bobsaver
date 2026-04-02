#version 420

// original https://www.shadertoy.com/view/Ns2GRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Pyramid - distance" by iq. https://shadertoy.com/view/Ws3SDl
// 2021-03-31 00:43:59

// The MIT License
// Copyright © 2019 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// EXACT distance to a pyramid. This shader computes the exact euclidean
// distances (not a bound based on half spaces). This allows to do
// operations on the shape such as rounding (see https://iquilezles.org/articles/distfunctions)
// while other implementations don't. Unfortunately the maths require us to do
// one square root sometimes to get the exact distance.

// List of other 3D SDFs: https://www.shadertoy.com/playlist/43cXRl
//
// and https://iquilezles.org/articles/distfunctions
// inspired by 
// https://www.shadertoy.com/view/XljGDz

vec3 diagN = normalize(vec3(-1.0));

// signed distance to a pyramid of base 1x1 and height h
float sdPyramid( in vec3 p, in float h )
{

    p = -p;
    float m2 = h*h + 0.25;
    

   
    
    // symmetry
    p.xz = abs(p.xz); // do p=abs(p) instead for double pyramid
    p.xz = (p.z>p.x) ? p.zx : p.xz;
    p.xz -= 0.5;
    
    // project into face plane (2D)
    vec3 q = vec3( p.z, h*p.y-0.5*p.x, h*p.x+0.5*p.y);
        
    float s = max(-q.x,0.0);
    float t = clamp( (q.y-0.5*q.x)/(m2+0.25), 0.0, 1.0 );
    
    float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
    float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    
    float d2 = max(-q.y,q.x*m2+q.y*0.5) < 0.0 ? 0.0 : min(a,b);
    
    // recover 3D and scale, and add sign
    float d = sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));  
 
   
    return d;
    
}

float sdSphere(in vec3 p, float r) { 

    float d = length(p) -r;
    return d;
}

float sdNuts(in vec3 p, float r) {
    return max(sdSphere(p - vec3(0.0,0.2,0.0), 0.4), sdSphere(p - vec3(0.0,0.2,0.0), 0.4));
}

float map( in vec3 pos )
{   
    vec3 p = pos;
    float rad = 0.0;
    float h = 1.0;
    //float d = sdPyramid(pos,hei) - rad;
    vec3 p_s = vec3(0.0,-0.0,0.00);
    float r = h * 0.5;
   
    int RECURSION_LEVELS = 6;
    float radius = 4.0;
    float subR = 0.68;
    float addR = 0.27;
    
    float final = 10000.0;
    for (int i = 0; i < RECURSION_LEVELS; i++) {
        float d = sdSphere(p, radius);
        
        vec3 corner = abs(p) + diagN * radius;
        float lenCorners = length(corner);
        float subSpheres = sdSphere(corner, radius * subR);
        //float addSpheres = sdSphere(corner, radius * addR);
        
        p = corner;
     
        d = max(d,-subSpheres);
        //d = min(d, addSpheres);
        final = min(d, final); 
        radius *= addR;
    }
    
    
    
   
    return final;
}

// https://iquilezles.org/articles/normalsSDF
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.001;
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
                      e.yyx*map( pos + e.yyx*eps ) + 
                      e.yxy*map( pos + e.yxy*eps ) + 
                      e.xxx*map( pos + e.xxx*eps ) );
}
    
#define AA 8
float localTime = 0.0;
float marchCount;

float PI=3.14159265;

void main(void)
{
   vec3 camPos = vec3(0.0), camFacing;
   vec3 camLookat=vec3(0,0.0,0);
    localTime = time - 0.0;
    // ---------------- First, set up the camera rays for ray marching ----------------
    vec2 uv = gl_FragCoord.xy/resolution.xy * 2.0 - 1.0;
    float zoom = 1.7;
    uv /= zoom;

    // Camera up vector.
    vec3 camUp=vec3(0,1,0);

    // Camera lookat.
    camLookat=vec3(0,0.0,0);

    // debugging camera
    float mx=mouse.x*resolution.xy.x/resolution.x*PI*2.0-0.7 + localTime*3.1415 * 0.0625*0.666;
    float my=-mouse.y*resolution.xy.y/resolution.y*10.0 - sin(localTime * 0.31)*0.5;//*PI/2.01;
    camPos += vec3(cos(my)*cos(mx),sin(my),cos(my)*sin(mx))*(12.2);

    // Camera setup.
    vec3 camVec=normalize(camLookat - camPos);
    vec3 sideNorm=normalize(cross(camUp, camVec));
    vec3 upNorm=cross(camVec, sideNorm);
    vec3 worldFacing=(camPos + camVec);
    vec3 worldPix = worldFacing + uv.x * sideNorm * (resolution.x/resolution.y) + uv.y * upNorm;
    vec3 rayVec = normalize(worldPix - camPos);
    
    
    vec3 tot = vec3(0.0);

    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {

        // raymarch
        const float tmax = 30.0;
        float t = 0.0;
        for( int i=0; i<1024; i++ )
        {
            vec3 pos = camPos + t*rayVec;
            float h = map(pos);
            if( h<0.0001 || t>tmax ) break;
            t += h;
        }
        
    
        // shading/lighting    
        vec3 col = vec3(0.0);
        if( t<tmax )
        {
            vec3 pos = camPos + t*rayVec;
            vec3 nor = calcNormal(pos);
            float dif = clamp( dot(nor,vec3(0.7,0.6,0.4)), 0.0, 1.0 );
            float amb = 0.5 + 0.5*dot(nor,vec3(0.0,0.8,0.6));
            col = vec3(0.2,0.3,0.4)*amb + vec3(0.8,0.7,0.5)*dif;
        }

        // gamma        
        col = sqrt( col );
        tot += col;
    }
    tot /= float(AA*AA);
    #endif

    glFragColor = vec4( tot, 1.0 );
}
