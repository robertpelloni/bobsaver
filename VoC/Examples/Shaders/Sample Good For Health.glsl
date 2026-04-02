#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WlXSWB

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 2013 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    

// A list of useful distance function to simple primitives. More info here:
//
// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

#define AA 2   // make this 2 or 3 for antialiasing
#define saturate(v) clamp(v, 0., 1.)
#define rand(v) fract(sin(dot(v ,vec2(12.9898,78.233))) * 43758.5453)
#define HASHSCALE1 .1031

float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

//------------------------------------------------------------------

float sdPlane( vec3 p )
{
    return p.y;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

//------------------------------------------------------------------

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

//------------------------------------------------------------------

#define ZERO (min(frames,0))

//------------------------------------------------------------------

mat4 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

float pMod1(inout float p, float size) {
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

float opRep( in float p, in float c)
{
    return mod(p,c)+0.5*c;
}

vec2 map( in vec3 pos )
{
    vec2 res = vec2( 1e10, 0.0 );

    pos.z -= 1.5;
    pos.y -= 1.0;
    
    pos.y += 12.0*(time*.125); 
    
    int index = int(ceil(pos.z / 1.2)) + (int(ceil(pos.y / 1.2)));
    
    pos.z = mod(pos.z, 1.2)+0.3*1.2;     
    pos.y = mod(pos.y, 1.2)+0.5*1.2;
    
    vec3 axis = vec3(hash12(vec2(42, index)),hash12(vec2(99, index)),hash12(vec2(22, index)));
    mat4 r = rotationMatrix(axis, 6.28 * fract(time * 0.1));
    vec3 t = (r*vec4(0.0,0.5,0.0,0.)).xyz;
    
    vec3 pos0 = pos-vec3( -0.0 ,1.,1.0);
    float halfsize = 0.35;
    float halfdistance = distance(pos0, t*halfsize); 
    float d = sdCapsule(   
        pos0,
        -t*halfsize,
        t*halfsize, 0.1  );
   
    float m = halfdistance / halfsize;
    if (index % 2 == 0)
    {
        m+= 2.;
    }
    res = opU( res, vec2(d , m) );
    
    return res;
}

// http://iquilezles.org/www/articles/boxfunctions/boxfunctions.htm
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    return vec2( max( max( t1.x, t1.y ), t1.z ),
                 min( min( t2.x, t2.y ), t2.z ) );
}

const float maxHei = 0.8;

vec2 castRay( in vec3 ro, in vec3 rd )
{
    vec2 res = vec2(-1.0,-1.0);

    float tmin = 1.0;
    float tmax = 20.0;
  
    // raymarch primitives   
    vec2 tb = iBox( ro-vec3(0.0,0.0,0.0), rd, vec3(100.) );
    if( tb.x<tb.y && tb.y>0.0 && tb.x<tmax)
    {
        tmin = max(tb.x,tmin);
        tmax = min(tb.y,tmax);

        float t = tmin;
        for( int i=0; i<70 && t<tmax; i++ )
        {
            vec2 h = map( ro+rd*t );
            if( abs(h.x)<(0.0001*t) )
            { 
                res = vec2(t,h.y); 
                 break;
            }
            t += h.x;
        }
    }
    
    return res;
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    // bounding volume
    float tp = (maxHei-ro.y)/rd.y; if( tp>0.0 ) tmax = min( tmax, tp );

    float res = 1.0;
    float t = mint;
    for( int i=ZERO; i<16; i++ )
    {
        float h = map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos )
{
#if 1
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
                      e.yyx*map( pos + e.yyx ).x + 
                      e.yxy*map( pos + e.yxy ).x + 
                      e.xxx*map( pos + e.xxx ).x );
#else
    // inspired by klems - a way to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e).x;
    }
    return normalize(n);
#endif    
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 ) * (0.5+0.5*nor.y);
}

vec3 render(in vec3 bg, in vec3 ro, in vec3 rd, in vec3 rdx, in vec3 rdy )
{ 
    vec3 col = bg;  
    vec2 res = castRay(ro,rd);
    float t = res.x;
    float m = res.y;
    
    if( m>-0.5 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = (m<1.5) ? vec3(0.0,1.0,0.0) : calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material
        vec3 c1 =  vec3(1.,1.,1.);
        if (m > 2.)
        {
           c1 =  vec3(1.,0.,0.);
           m -=2.;
        }
        col = mix(vec3(0.,0.,1.), c1, step(m, 0.5));

        // lighting
        vec3  lig = normalize( vec3(-0.5, 0.4, -0.6) );
        vec3  hal = normalize( lig-rd );
        float amb = sqrt(clamp( 0.5+0.5*nor.y, 0.0, 1.0 ));
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.2, 0.2, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        
        dif *= calcSoftshadow( pos, lig, 0.02, 2.5 );
        dom *= calcSoftshadow( pos, ref, 0.02, 2.5 );

        float spe = pow( clamp( dot( nor, hal ), 0.0, 1.0 ),16.0)*
                    dif *
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));
       
        vec3 lin = vec3(0.0);
        lin += 3.80*dif*vec3(1.30,1.00,0.70);
        lin += 0.55*amb*vec3(0.40,0.60,1.15);
        lin += 0.85*dom*vec3(0.40,0.60,1.30);
        lin += 0.55*bac*vec3(0.25,0.25,0.25);
        lin += 0.25*fre*vec3(1.00,1.00,1.00);
        col = col*lin;
        col += 7.00*spe*vec3(1.10,0.90,0.70);
    }

    return vec3( clamp(col,0.0,1.0) );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv =          ( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy -resolution.xy)/resolution.xy.y;
    vec3 bg = vec3(0.7,0.,0.);
    
    // camera    
    vec3 ro = vec3( 4., 1.2, 0.0);
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+o))/resolution.y;
#else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
#endif

        // ray direction
        vec3 rd = ca * normalize( vec3(p,2.0) );

         // ray differentials
        vec2 px = (-resolution.xy+2.0*(gl_FragCoord.xy+vec2(1.0,0.0)))/resolution.y;
        vec2 py = (-resolution.xy+2.0*(gl_FragCoord.xy+vec2(0.0,1.0)))/resolution.y;
        vec3 rdx = ca * normalize( vec3(px,2.0) );
        vec3 rdy = ca * normalize( vec3(py,2.0) );
        
        // render    
        vec3 col = render( bg.rgb, ro, rd, rdx, rdy );
        
        float fogStart = 0.2;
        float d1 = max(0., (resolution.y*0.05-gl_FragCoord.y));
        float d2 = max(0., (gl_FragCoord.y-resolution.y*0.95));
        float fogDistance = d1 + d2;
        float fogDensity = 0.02;
        float fogAmount =1.0- exp( -fogDistance*fogDensity );
        vec3  fogColor = bg.rgb;
        col = mix( col, fogColor, fogAmount );

        // gamma
        col = pow( col, vec3(0.4545) );
        
        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif   
    
    glFragColor = vec4( tot, 1.0 );
}
