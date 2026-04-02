#version 420

// original https://www.shadertoy.com/view/XdS3Rt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2014 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Analytical sphere visibility, which can be used of occlusion culling, based on this
//
// Aarticle I wrote in 2008: http://iquilezles.org/www/articles/sphereocc/sphereocc.htm
//
// Related info: http://iquilezles.org/www/articles/spherefunctions/spherefunctions.htm

//-----------------------------------------------------------------

// Return values:
// 1: spheres don't overlap
// 2: spheres overlap partially
// 3: spheres overlap completely (one completelly occludes the other)

int sphereVisibility( in vec3 ca, in float ra, in vec3 cb, float rb, in vec3 c )
{
    float aa = dot(ca-c,ca-c);
    float bb = dot(cb-c,cb-c);
    float ab = dot(ca-c,cb-c);
    
    float s = ab*ab + ra*ra*bb + rb*rb*aa - aa*bb; 
    float t = 2.0*ab*ra*rb;

         if( s + t < 0.0 ) return 1;
    else if( s - t < 0.0 ) return 2;
                           return 3;
}

//-----------------------------------------------------------------

float iSphere( in vec3 ro, in vec3 rd, in vec4 sph )
{
    vec3 oc = ro - sph.xyz;
    float b = dot( oc, rd );
    float c = dot( oc, oc ) - sph.w*sph.w;
    float h = b*b - c;
    if( h<0.0 ) return -1.0;
    return -b - sqrt( h );
}

float oSphere( in vec3 pos, in vec3 nor, in vec4 sph )
{
    vec3 di = sph.xyz - pos;
    float l = length(di);
    return 1.0 - max(0.0,dot(nor,di/l))*sph.w*sph.w/(l*l); 
}

//-----------------------------------------------------------------

vec3 hash3( float n ) { return fract(sin(vec3(n,n+1.0,n+2.0))*43758.5453123); }

//-----------------------------------------------------------------

#define AA 2

void main(void)
{
    float an = 0.6 - 0.5*time + 10.0*mouse.x*resolution.xy.x/resolution.x;
    vec3 ro = vec3( 3.5*cos(an), 0.0, 3.5*sin(an) );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

    vec4 sph1 = vec4(-1.2,0.7,0.0,1.0);
    vec4 sph2 = vec4( 1.2,0.0,0.0,1.0);
    int vis = sphereVisibility( sph1.xyz, sph1.w, sph2.xyz, sph2.w, ro );

            
    vec3 tot = vec3(0.0);
    for( int j=0; j<AA; j++ )
    for( int i=0; i<AA; i++ )
    {
        vec2 off = vec2( float(i), float(j) ) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+off)) / resolution.y;
        
        vec3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

        float tmin = 10000.0;
        vec3  nor = vec3(0.0);
        float occ = 1.0;
        vec3  pos = vec3(0.0);

        float h = iSphere( ro, rd, sph1 );
        if( h>0.0 && h<tmin ) 
        { 
            tmin = h; 
            pos = ro + h*rd;
            nor = normalize(pos-sph1.xyz); 
            occ = oSphere( pos, nor, sph2 );
            occ *= smoothstep(-0.6,-0.2,sin(20.0*(pos.x-sph1.x)));
        }
        h = iSphere( ro, rd, sph2 );
        if( h>0.0 && h<tmin ) 
        { 
            tmin = h; 
            pos = ro + h*rd;
            nor = normalize(pos-sph2.xyz); 
            occ = oSphere( pos, nor, sph1 );
            occ *= smoothstep(-0.6,-0.2,sin(20.0*(pos.z-sph1.z)));
        }

        vec3 col = vec3(0.02)*clamp(1.0-0.5*length(p),0.0,1.0);
        if( tmin<100.0 )
        {
            col = vec3(0.5);
            if( vis==1 ) col = vec3(1.0,1.0,1.0);
            if( vis==2 ) col = vec3(1.0,1.0,0.0);
            if( vis==3 ) col = vec3(1.0,0.0,0.0);
            col *= occ;
            col *= 0.7 + 0.3*nor.y;
            col *= exp(-0.5*max(0.0,tmin-2.0));
        }

        tot += pow( col, vec3(0.45) );
        tot += (1.0/255.0)*hash3(p.x+13.0*p.y);
    }
    tot /= float(AA*AA);

    glFragColor = vec4( tot, 1.0 );
}
