#version 420

// original https://www.shadertoy.com/view/Nd2BDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Daniel Varga plugging his manifold into raymarching example by Inigo Quilez. Thanks Inigo!

// The MIT License
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

precision highp float;

float dot2(in vec3 v ) { return dot(v,v); }

float manifold(vec3 p, vec3 a, float target)
{
    vec3 d = p - a;
    vec2 px = vec2(cos(d.x), sin(d.x));
    vec2 py = vec2(cos(d.y), sin(d.y));
    vec2 pz = vec2(cos(d.z), sin(d.z));
    float eq = length(px + py + pz + vec2(1.0, 0.0)) - target;
    return eq;
}

float map( in vec3 pos )
{
    float t = time / 5.0;
    float mul = 10.0;
    vec3  pa = vec3(t, 2.0 * 3.14 / mul + cos(t*0.5*mul) / 5.0, 0.0);
    float target = (sin(time * 0.94535) + 1.5) / 3.0 ; // smaller is thinner.
    return manifold(mul * pos, mul * pa, target) * 0.01;
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.0005;
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
                      e.yyx*map( pos + e.yyx*eps ) + 
                      e.yxy*map( pos + e.yxy*eps ) + 
                      e.xxx*map( pos + e.xxx*eps ) );
}

// Daniel: let's rather just hardwire no AA.
#define AA 1

void main(void)
{
    // camera movement    
    // float an = 0.05*(time-10.0);
    float an = 0.0;
    vec3 ro = vec3( 1.0*cos(an), 0.4, 1.0*sin(an) );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera matrix
    vec3 ww = normalize( ta - ro );
    vec3 uu = normalize( cross(ww,vec3(0.0,1.0,0.0) ) );
    vec3 vv = normalize( cross(uu,ww));

    
    
    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+o))/resolution.y;
        #else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
        #endif

        // create view ray
        vec3 rd = normalize( p.x*uu + p.y*vv + 1.5*ww );

        // raymarch
        const float tmax = 10.0;
        float t = 0.0;
        for( int i=0; i<1000; i++ )
        {
            vec3 pos = ro + t*rd;
            float h = map(pos);
            if( h<0.001 || t>tmax ) break;
            t += h;
        }
        
    
        // shading/lighting    
        vec3 col = vec3(0.0);
        if( t<tmax )
        {
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);
            float dif = clamp( dot(nor,vec3(0.57703)), 0.0, 1.0 );
            float amb = 0.5 + 0.5*dot(nor,vec3(0.0,1.0,0.0));
            col = vec3(0.2,0.3,0.4)*amb + vec3(0.8,0.7,0.5)*dif;
            col *= 2.0*exp2(-t / 1.5);
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
