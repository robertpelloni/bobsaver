#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wdjczz

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// The MIT License
// Copyright © 20202 Navjot Garg
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// This is a model of Taj Mahal, created using SDF Primitives. The symmetric nature of the building is key in getting good performance.
// The building is evaluated in 1 quadrant and thus reduces the number of required evaluations by 4x. This runs at 45 fps on my GTX 980.
// Thanks to iq for providing references and optimization tips.

#if HW_PERFORMANCE==0
#define AA 1
#else
#define AA 2   // make this 2 or 3 for antialiasing
#endif

//------------------------------------------------------------------

float sdPlane( vec3 p )
{
    return p.y;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float dot2( in vec2 v ) { return dot(v,v); }

float sdCone( in vec3 p, in float h, in float r1, in float r2 )
{
    vec2 q = vec2( length(p.xz), p.y );
    
    vec2 k1 = vec2(r2,h);
    vec2 k2 = vec2(r2-r1,2.0*h);
    vec2 ca = vec2(q.x-min(q.x,(q.y < 0.0)?r1:r2), abs(q.y)-h);
    vec2 cb = q - k1 + k2*clamp( dot(k1-q,k2)/dot2(k2), 0.0, 1.0 );
    float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
    return s*sqrt( min(dot2(ca),dot2(cb)) );
}

float sdCylinder( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

// http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdCone(vec3 p, vec3 a, vec3 b, float ra, float rb)
{
    float rba  = rb-ra;
    float baba = dot(b-a,b-a);
    float papa = dot(p-a,p-a);
    float paba = dot(p-a,b-a)/baba;

    float x = sqrt( papa - paba*paba*baba );

    float cax = max(0.0,x-((paba<0.5)?ra:rb));
    float cay = abs(paba-0.5)-0.5;

    float k = rba*rba + baba;
    float f = clamp( (rba*(x-ra)+paba*baba)/k, 0.0, 1.0 );

    float cbx = x-ra - f*rba;
    float cby = paba - f;
    
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    
    return s*sqrt( min(cax*cax + cay*cay*baba,
                       cbx*cbx + cby*cby*baba) );
}

float sdBox( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdOctagonBox( vec3 p, vec2 r, vec2 s, float height )
{
    vec3 absP = abs(p);
    vec2 p1 = vec2(r.x, s.y);
    vec2 p2 = vec2(s.x, r.y);
    float h = min(1.0, max(0.0, dot(absP.xz-p1, p2-p1)/dot2(p2-p1)));
    vec2 q = p1+h*(p2-p1);
    vec3 d = vec3(absP - vec3(q.x,height,q.y));
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }
vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

float sdHemisphere(vec3 p, float s )
{
    float res = sdSphere(p, s);
    return opSubtraction(sdBox(vec3(p.x, p.y+s/2.0, p.z),vec3(s,s/2.0,s)),res);
}

vec2 gate(vec3 pCylinder,vec3 pSphere, vec2 rh)
{
    float gateCylinder = sdCylinder(pCylinder, rh);
    float gateDome = sdSphere(pSphere, rh.x);
    return opU(vec2(gateCylinder, 2.0), vec2(gateDome,2.0));
}

float sdMainGate(vec3 p, vec2 rh, vec2 rOcta, vec2 sOcta, float heightOcta)
{
    float octa = sdOctagonBox(p,rOcta, sOcta, heightOcta);
    
    // Evaluate only one quadrant instead of 4
    vec2 rhSmall = rh/2.2;
    vec3 absPos = vec3(abs(p.x),p.y,abs(p.z));    
    // X
    vec2 gates = gate(absPos-vec3(1.4,-0.1,0.0),absPos-vec3(1.4,0.5,0.0),rh);
    // Y
    gates = opU(gates,gate(absPos-vec3(0.0,-0.1,1.2), absPos-vec3(0.0,0.5,1.2),rh+vec2(0.05,0.0)));
    // X top
    gates = opU(gates,gate(absPos-vec3(1.4, 0.38,0.55),absPos-vec3(1.4,0.65,0.55),rhSmall));
    // X bottom
    gates = opU(gates,gate(absPos-vec3(1.4,-0.36,0.55),absPos-vec3(1.4,-0.08,0.55),rhSmall));
    // Y top
    gates = opU(gates,gate(absPos-vec3(0.7, 0.38,1.15),absPos-vec3(0.7,0.65,1.15),rhSmall));
    // Y bottom
    gates = opU(gates,gate(absPos-vec3(0.7, -0.36,1.15),absPos-vec3(0.7,-0.08,1.15),rhSmall));
    // side top
    gates = opU(gates,gate(absPos-vec3(1.25, 0.38,1.05),absPos-vec3(1.25,0.65,1.05),rhSmall));
    // side bottom
    gates = opU(gates,gate(absPos-vec3(1.25, -0.36,1.05),absPos-vec3(1.25,-0.08,1.05),rhSmall));
    
    return opSubtraction(gates.x,octa);
}
//------------------------------------------------------------------

#define ZERO (min(frames,0))

//------------------------------------------------------------------

vec2 map( in vec3 pos )
{   
    float col = 7.5;
    vec2 res = vec2( sdBox(pos, vec3(3.0, 0.25,2.5) ), col );
    
    // top facade
    vec3 sos = vec3(abs(pos.x),pos.y,abs(pos.z));
    res = opU(res,vec2( sdBox( sos-vec3(0.0,1.9,1.15), vec3(0.5, 0.15,0.05) ), col ));
    res = opU(res, vec2( sdSphere(sos - vec3(0.47,2.25,1.2), 0.03), col));
    res = opU(res, vec2( sdCylinder(sos - vec3(0.47,1.25,1.2), vec2(0.03, 1.0)), col));
    res = opU(res, vec2(sdCylinder(sos - vec3(0.47,2.3,1.2), vec2(0.005+max(0.0,sin(100.0*pos.y + 10.0))/40.0,0.1)), col));
    
    res = opU(res,vec2( sdBox( sos-vec3(1.35,1.9,0.0), vec3(0.05, 0.15,0.38) ),col ));
    res = opU(res, vec2( sdSphere(sos - vec3(1.4,2.25,0.35), 0.03), col));
    res = opU(res, vec2( sdCylinder(sos - vec3(1.4,1.25,0.35), vec2(0.03, 1.0)), col));
    res = opU(res, vec2(sdCylinder(sos - vec3(1.4,2.3,0.35), vec2(0.005+max(0.0,sin(100.0*pos.y + 10.0))/40.0,0.1)), col));
    
    // side spires
    res = opU(res, vec2( sdSphere(sos - vec3(1.0,2.0,1.2), 0.03), col));
    res = opU(res, vec2( sdCylinder(sos - vec3(1.0,1.1,1.2), vec2(0.03, 0.9)), col));
    res = opU(res, vec2(sdCylinder(sos - vec3(1.0,2.05,1.2), vec2(0.005+max(0.0,sin(100.0*pos.y + 10.0))/40.0,0.1)), col));
    
    res = opU(res, vec2( sdSphere(sos - vec3(1.4,2.0,0.8), 0.03), col));
    res = opU(res, vec2( sdCylinder(sos - vec3(1.4,1.1,0.8), vec2(0.03, 0.9)), col));
    res = opU(res, vec2(sdCylinder(sos - vec3(1.4,2.05,0.8), vec2(0.005+max(0.0,sin(100.0*pos.y + 10.0))/40.0,0.1)), col));
    
    // main building with gates
    res = opU(res, vec2(sdMainGate(pos - vec3(0.0,0.9,0.0),vec2(0.3,0.6),vec2(1.4,1.2), vec2(1.0,0.8), 0.9),col));
    
    // four columns
    res = opU(res, vec2(sdCone(sos - vec3(2.7,0.9,2.2),0.9, 0.2, 0.12), col));
    res = opU(res, vec2(sdSphere(sos - vec3(2.7,2.15,2.2),0.13), col));
    res = opU(res, vec2(sdCylinder(sos - vec3(2.7,2.35,2.2), vec2(0.01+max(0.0,sin(100.0*pos.y + 5.0))/40.0,0.1)), col));
    
    // disks on columns
    res = opU(res, vec2(sdCylinder(sos - vec3(2.7,2.1,2.2), vec2(0.15,0.03)), col));
    res = opU(res, vec2(sdCylinder(sos - vec3(2.7,1.8,2.2), vec2(0.15,0.05)), col));
    res = opU(res, vec2(sdCylinder(sos - vec3(2.7,1.25,2.2), vec2(0.17,0.05)), col));
    res = opU(res, vec2(sdCylinder(sos - vec3(2.7,0.7,2.2), vec2(0.2,0.05)), col));
  
    //spires for 4 columns and 4 domes
    float theta = 3.14/4.0;
    for(int i = 0; i< 8; i++)
    {  
        res = opU(res, vec2(sdCylinder(sos - (vec3(2.7,1.95,2.2) + vec3(0.1*cos(theta),0.0, 0.1* sin(theta))), vec2(0.015,0.15)), col));
        res = opU(res, vec2(sdCylinder(sos - (vec3(0.8,1.9,0.8) + vec3(0.25*cos(theta),0.0, 0.25* sin(theta))), vec2(0.03,0.2)),col));
        theta += (3.14/4.0);
    }
    
    // plates under small domes
    res = opU(res, vec2(sdCylinder(sos - vec3(0.8,2.1,0.8), vec2(0.35,0.01)), col));
    
    // domes and spire on domes
    res = opU(res,  vec2(sdHemisphere(sos- vec3(0.8,2.1,0.8),0.3), col));
    res = opU(res, vec2(sdCylinder(sos - vec3(0.8,2.5,0.8), vec2(0.01+max(0.0,sin(100.0*pos.y + 10.0))/40.0,0.1)), col));
    
    // center dome
    res = opU(res, vec2(sdCylinder(pos- vec3(0.0,2.0,0.0), vec2(0.7,0.3)), col));
    res = opU(res, vec2(sdSphere(pos - vec3(0.0,2.5,0.0),0.7), col));
    res = opU(res, vec2(sdCylinder(pos - vec3(0.0,3.4,0.0), vec2(0.025+max(0.0,sin(60.0*pos.y + 10.0))/20.0,0.2)), col));
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
    float tmax = 50.0;

    // raytrace floor plane
    float tp1 = (0.0-ro.y)/rd.y;
    if( tp1>0.0 )
    {
        tmax = min( tmax, tp1 );
        res = vec2( tp1, 1.0 );
    }
    
    // raymarch primitives   
    vec2 tb = iBox( ro, rd, vec3(5.0,4.0,5.0) );
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
        float s = clamp(8.0*h/t,0.0,1.0);
        res = min( res, s*s*(3.0-2.0*s) );
        t += clamp( h, 0.02, 0.10 );
        if( res<0.005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos )
{
#if 0
    vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
    return normalize( e.xyy*map( pos + e.xyy ).x + 
                      e.yyx*map( pos + e.yyx ).x + 
                      e.yxy*map( pos + e.yxy ).x + 
                      e.xxx*map( pos + e.xxx ).x );
#else
    // inspired by tdhooper and klems - a way to prevent the compiler from inlining map() 4 times
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

// http://iquilezles.org/www/articles/checkerfiltering/checkerfiltering.htm
float checkersGradBox( in vec2 p, in vec2 dpdx, in vec2 dpdy )
{
    // filter kernel
    vec2 w = abs(dpdx)+abs(dpdy) + 0.001;
    // analytical integral (box filter)
    vec2 i = 2.0*(abs(fract((p-0.5*w)*0.5)-0.5)-abs(fract((p+0.5*w)*0.5)-0.5))/w;
    // xor pattern
    return 0.5 - 0.5*i.x*i.y;                  
}

vec3 render( in vec3 ro, in vec3 rd, in vec3 rdx, in vec3 rdy )
{ 
    vec3 col = vec3(0.7, 0.7, 0.9) - max(rd.y,0.0)*0.3;
    vec2 res = castRay(ro,rd);
    float t = res.x;
    float m = res.y;
    if( m>-0.5 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = (m<1.5) ? vec3(0.0,1.0,0.0) : calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material        
        col = 0.2 + 0.18*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
        //col = vec3(0.2);
        col = 0.2 + 0.18*sin( m*2.0 + vec3(0.0,0.5,1.0) );
        if( m<1.5 )
        {
            // project pixel footprint into the plane
            vec3 dpdx = ro.y*(rd/rd.y-rdx/rdx.y);
            vec3 dpdy = ro.y*(rd/rd.y-rdy/rdy.y);

            float f = checkersGradBox( 5.0*pos.xz, 5.0*dpdx.xz, 5.0*dpdy.xz );
            col = 0.15 + f*vec3(0.05);
        }

        // lighting
        float occ = calcAO( pos, nor );
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
        lin += 0.55*amb*vec3(0.40,0.60,1.15)*occ;
        lin += 0.85*dom*vec3(0.40,0.60,1.30)*occ;
        lin += 0.55*bac*vec3(0.25,0.25,0.25)*occ;
        lin += 0.25*fre*vec3(1.00,1.00,1.00)*occ;
        col = col*lin;
        col += 7.00*spe*vec3(1.10,0.90,0.70);

        col = mix( col, vec3(0.7,0.7,0.9), 1.0-exp( -0.0001*t*t*t ) );
    }

    return vec3( clamp(col,0.0,1.0) );
}

mat3 setCamera( in vec3 cOrigin, in vec3 lookat, float cr )
{
    vec3 cforward = normalize(lookat-cOrigin);
    vec3 yUp = vec3(0.0, 1.0 ,0.0);
    vec3 cRight = normalize( cross(cforward,yUp) );
    vec3 cUp =          ( cross(cRight,cforward) );
    return mat3( cRight,cUp,cforward );
}

void main(void)
{
    vec2 mo = mouse*resolution.xy.xy/resolution.xy;
    float time = 15.0 + time*1.5;

    // camera    
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    vec3 ro = ta + vec3( 8.5*cos(6.0*mo.x), 1.0 + 5.0*mo.y, 10.5*sin(6.0*mo.x) );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(gl_FragCoord.xy+o)-resolution.xy)/resolution.y;
#else    
        vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
#endif

        // ray direction
        vec3 rd = ca * normalize( vec3(p,2.5) );

         // ray differentials
        vec2 px = (2.0*(gl_FragCoord.xy+vec2(1.0,0.0))-resolution.xy)/resolution.y;
        vec2 py = (2.0*(gl_FragCoord.xy+vec2(0.0,1.0))-resolution.xy)/resolution.y;
        vec3 rdx = ca * normalize( vec3(px,2.5) );
        vec3 rdy = ca * normalize( vec3(py,2.5) );
        
        // render    
        vec3 col = render( ro, rd, rdx, rdy );

        // gamma
        col = pow( col, vec3(0.4545) );

        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif

    
    glFragColor = vec4( tot, 1.0 );
}
