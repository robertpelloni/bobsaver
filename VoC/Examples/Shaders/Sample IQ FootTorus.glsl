#version 420

// original https://www.shadertoy.com/view/4dKfDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2018 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#define AA 4   // make this 1 is your machine is too slow

//------------------------------------------------------------------

const vec2 torus = vec2(0.5,0.2);

float map( in vec3 p )
{
    return length( vec2(length(p.xz)-torus.x,p.y) )-torus.y;
}

vec2 castRay( in vec3 ro, in vec3 rd )
{
    // plane
    float tmax = (-torus.y-ro.y)/rd.y;
   
    // torus
    float t = 1.0;
    float m = 2.0;
    for( int i=0; i<100; i++ )
    {
        float precis = 0.0004*t;
        float res = map( ro+rd*t );
        if( res<precis || t>tmax ) break;
        t += res;
    }

    if( t>tmax ) { t=tmax; m=1.0; }
    return vec2( t, m );
}

float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<12; i++ )
    {
        float h = map( ro + rd*t );
        res = min( res,18.0*h/t );
        t += clamp( h, 0.05, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ) + 
                      e.yyx*map( pos + e.yyx ) + 
                      e.yxy*map( pos + e.yxy ) + 
                      e.xxx*map( pos + e.xxx ) );
}

float checkers_pattern( in vec2 p ) // http://iquilezles.org/www/articles/checkerfiltering/checkerfiltering.htm
{
    // filter kernel
    vec2 w = fwidth(p) + 0.001;
    // analytical integral (box filter)
    vec2 i = 2.0*(abs(fract((p-0.5*w)*0.5)-0.5)-abs(fract((p+0.5*w)*0.5)-0.5))/w;
    // xor pattern
    return 0.5 - 0.5*i.x*i.y;                  
}

vec3 hexagon_pattern( vec2 p ) 
{
    vec2 q = vec2( p.x*2.0*0.5773503, p.y + p.x*0.5773503 );
    
    vec2 pi = floor(q);
    vec2 pf = fract(q);

    float v = mod(pi.x + pi.y, 3.0);

    float ca = step(1.0,v);
    float cb = step(2.0,v);
    vec2  ma = step(pf.xy,pf.yx);
    
    return vec3( pi + ca - cb*ma, dot( ma, 1.0-pf.yx + ca*(pf.x+pf.y-1.0) + cb*(pf.yx-2.0*pf.xy) ) );
}

vec3 render( in vec3 ro, in vec3 rd )
{ 
    vec3 col = vec3(0.7, 0.9, 1.0) + rd.y*0.8;
    vec2 res = castRay(ro,rd);
    float t = res.x;
    float m = res.y;
    {
        vec3 pos = ro + t*rd;
        vec3 nor = vec3(0.0,1.0,0.0);
        
        if( m<1.5 ) // plane
        {
            float f = checkers_pattern( 2.0*pos.xz );
            col = 0.3 + f*vec3(0.1);
            col *= smoothstep(0.0,0.42, abs(length(pos.xz)-torus.x) );
        }
        else // torus
        {
            nor = calcNormal( pos );
            
            vec2 uv = vec2( atan(pos.z, -pos.x), atan(length(pos.xz)-torus.x,pos.y) )*
                      vec2(12.0*sqrt(3.0), 8.0)/3.14159;
            uv.y += time;
            vec3 h = hexagon_pattern( uv );
            
            // cell color
            col = vec3( mod(h.x+2.0*h.y,3.0)/2.0 );
            // cell borders
            col *= smoothstep(0.02,0.04,h.z);
        }

        // lighting        
        float occ = (0.5+0.5*nor.y);
        vec3  lig = normalize( vec3(0.4, 0.5, -0.6) );
        vec3  hal = normalize( lig-rd );
        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        
        dif *= calcSoftshadow( pos, lig, 0.02, 2.5 );

        float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),32.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));

        vec3 lin = vec3(0.0);
        lin += 1.630*dif*vec3(1.1,0.90,0.55);
        lin += 0.50*amb*vec3(0.30,0.60,1.50)*occ;
        lin += 0.30*bac*vec3(0.40,0.30,0.25)*occ;
        col = col*lin;
        col += 6.00*spe*vec3(1.15,0.90,0.70);
    }

    return col;
}

void main(void)
{
    vec2 mo = mouse*resolution.xy.xy/resolution.xy;

    
    vec3 tot = vec3(0.0);
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+o))/resolution.y;
        #else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord)/resolution.y;
        #endif

        // camera    
        vec3 ro = vec3( 1.3*cos(0.05*time + 6.0*mo.x), 1.1, 1.3*sin(0.05*time + 6.0*mo.x) );
        vec3 ta = vec3( 0.0, -0.2, 0.0 );
        // camera-to-world transformation
        vec3 cw = normalize(ta-ro);
        vec3 cu = normalize( cross(cw,vec3(0.0, 1.0,0.0)) );
        vec3 cv = normalize( cross(cu,cw) );
        // ray direction
        vec3 rd = normalize( p.x*cu + p.y*cv + 2.0*cw );

        // render    
        vec3 col = render( ro, rd );

        // gamma
        col = pow( col, vec3(0.4545) );

        tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

 
    // grading
    tot = pow(tot,vec3(0.8,0.9,1.0) );
    // vignetting
    vec2 q = gl_FragCoord.xy/resolution.xy;
    tot *= 0.3 + 0.7*pow(16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.25);
    
    glFragColor = vec4( tot, 1.0 );
}
