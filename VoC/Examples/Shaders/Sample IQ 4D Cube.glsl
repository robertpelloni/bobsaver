#version 420

// original https://www.shadertoy.com/view/4tVyWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0

// Another 4D cube. For the 4D->3D proection, you can switch between 
// orthographic and perspective projections, in line 9.
   

#define PROJECTION 1
// 0 = orthographics
// 1 = perspective

#define AA 2   // make this 1 is your machine is too slow

//#define BBOX

//------------------------------------------------------------------

float dot2(in vec3 v ) { return dot(v,v); }

float sdSegmentSq( vec3 p, vec3 a, vec3 b )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return dot2( pa - ba*h );
}

#ifdef BBOX
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );
    if( tN > tF || tF < 0.0) return vec2(-1.0);
    return vec2( tN, tF );
}
#endif

vec3 v00, v01, v02, v03, v04, v05, v06, v07, v08, v09, v10, v11, v12, v13, v14, v15;
#ifdef BBOX
vec3 bboxMin, bboxMax;
#endif

float map( in vec3 pos )
{
    // NOTE - it seems doing the 16 computations in serial is faster than doing them in parallel. This is
    //        probably because less registers in fly, which allows for more threads to run in parallel?
#if 1    
    float d =   sdSegmentSq( pos, v00, v01 );
    d = min( d, sdSegmentSq( pos, v02, v03 ));
    d = min( d, sdSegmentSq( pos, v00, v02 ));
    d = min( d, sdSegmentSq( pos, v01, v03 ));
    d = min( d, sdSegmentSq( pos, v04, v05 ));
    d = min( d, sdSegmentSq( pos, v06, v07 ));
    d = min( d, sdSegmentSq( pos, v04, v06 ));
    d = min( d, sdSegmentSq( pos, v05, v07 ));
    d = min( d, sdSegmentSq( pos, v00, v04 ));
    d = min( d, sdSegmentSq( pos, v01, v05 ));
    d = min( d, sdSegmentSq( pos, v02, v06 ));
    d = min( d, sdSegmentSq( pos, v03, v07 ));
    d = min( d, sdSegmentSq( pos, v08, v09 ));
    d = min( d, sdSegmentSq( pos, v10, v11 ));
    d = min( d, sdSegmentSq( pos, v08, v10 ));
    d = min( d, sdSegmentSq( pos, v09, v11 ));
    d = min( d, sdSegmentSq( pos, v12, v13 ));
    d = min( d, sdSegmentSq( pos, v14, v15 ));
    d = min( d, sdSegmentSq( pos, v12, v14 ));
    d = min( d, sdSegmentSq( pos, v13, v15 ));
    d = min( d, sdSegmentSq( pos, v08, v12 ));
    d = min( d, sdSegmentSq( pos, v09, v13 ));
    d = min( d, sdSegmentSq( pos, v10, v14 ));
    d = min( d, sdSegmentSq( pos, v11, v15 ));
    d = min( d, sdSegmentSq( pos, v00, v08 ));
    d = min( d, sdSegmentSq( pos, v01, v09 ));
    d = min( d, sdSegmentSq( pos, v02, v10 ));
    d = min( d, sdSegmentSq( pos, v03, v11 ));
    d = min( d, sdSegmentSq( pos, v04, v12 ));
    d = min( d, sdSegmentSq( pos, v05, v13 ));
    d = min( d, sdSegmentSq( pos, v06, v14 ));
    d = min( d, sdSegmentSq( pos, v07, v15 ));
#else
    float d = min( min(min( min( min( sdSegmentSq( pos, v00, v01 ), 
                                      sdSegmentSq( pos, v02, v03 )),
                                 min( sdSegmentSq( pos, v00, v02 ), 
                                      sdSegmentSq( pos, v01, v03 ))),
                            min( min( sdSegmentSq( pos, v04, v05 ), 
                                      sdSegmentSq( pos, v06, v07 )),
                                 min( sdSegmentSq( pos, v04, v06 ), 
                                      sdSegmentSq( pos, v05, v07 )))),
                       min( min( min( sdSegmentSq( pos, v00, v04 ), 
                                      sdSegmentSq( pos, v01, v05 )),
                                 min( sdSegmentSq( pos, v02, v06 ), 
                                      sdSegmentSq( pos, v03, v07 ))),
                            min( min( sdSegmentSq( pos, v08, v09 ), 
                                      sdSegmentSq( pos, v10, v11 )),
                                 min( sdSegmentSq( pos, v08, v10 ), 
                                      sdSegmentSq( pos, v09, v11 ))))),
                   min( min(min( min( sdSegmentSq( pos, v12, v13 ),
                                      sdSegmentSq( pos, v14, v15 )),
                                 min( sdSegmentSq( pos, v12, v14 ),
                                      sdSegmentSq( pos, v13, v15 ))),
                            min( min( sdSegmentSq( pos, v08, v12 ),
                                      sdSegmentSq( pos, v09, v13 )),
                                 min( sdSegmentSq( pos, v10, v14 ),
                                      sdSegmentSq( pos, v11, v15 )))), 
                        min(min( min( sdSegmentSq( pos, v02, v10 ),
                                      sdSegmentSq( pos, v03, v11 )),
                                 min( sdSegmentSq( pos, v00, v08 ), 
                                      sdSegmentSq( pos, v01, v09 ))),
                            min( min( sdSegmentSq( pos, v04, v12 ),
                                      sdSegmentSq( pos, v05, v13 )),
                                 min( sdSegmentSq( pos, v06, v14 ),
                                      sdSegmentSq( pos, v07, v15 ))))) );
#endif    
    return sqrt(d) - 0.07;
}

float castRay( in vec3 ro, in vec3 rd, in float tmin, in float tmax )
{
    float t = tmin;
    for( int i=0; i<80; i++ )
    {
        float h = map( ro+rd*t );
        if( h<0.002 || t>tmax ) break;
        t += h;
    }

    if( t>tmax ) t=-1.0;
    return t;
}

float calcSoftshadow( in vec3 ro, in vec3 rd )
{
    float res = 1.0;
    float t = 0.02;
    for( int i=0; i<64; i++ )
    {
        float h = map( ro + rd*t );
        res = min( res, 32.0*h/t );
        t += clamp( h, 0.05, 0.2 );
        if( res<0.005 || t>4.0 ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773*0.001;
    return normalize( e.xyy*map( pos + e.xyy ) + 
                      e.yyx*map( pos + e.yyx ) + 
                      e.yxy*map( pos + e.yxy ) + 
                      e.xxx*map( pos + e.xxx ) );
}

float calcAO( in vec3 pos, in vec3 nor, in float seed )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.3*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos );
        occ += -(dd-hr)*sca;
        sca *= 0.97;
    }
    return clamp( 1.0 - 1.0*occ, 0.0, 1.0 );    
}

vec3 render( in vec3 ro, in vec3 rd, in float seed )
{ 
    vec3 col = vec3(0.04) + 0.03*rd.y;

#ifdef BBOX
    vec2 tmima = iBox( ro-0.5*(bboxMax+bboxMin), rd, 0.5*(bboxMax-bboxMin)+0.07 );
    if( tmima.y<0.0 ) return col;
    float t = castRay(ro,rd, max(1.5,tmima.x), min(10.0,tmima.y));
#else        
    float t = castRay(ro,rd, 1.5, 10.0);
#endif    
    
    if( t>0.0 )
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material        
        col = vec3(0.4);

        // lighting        
        float occ = calcAO( pos, nor, seed )*(0.7+0.3*nor.y);
        vec3  lig = normalize( vec3(-0.4, 0.7, -0.6) );
        vec3  hal = normalize( lig-rd );
        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        
        if( dif>0.001) dif *= calcSoftshadow( pos, lig );

        float spe = pow( clamp( dot(nor,hal), 0.0, 1.0 ),16.0)*dif*
                    (0.04 + 0.96*pow( clamp(1.0+dot(hal,rd),0.0,1.0), 5.0 ));

        vec3 lin = vec3(0.0);
        lin += 1.30*dif*vec3(1.20,0.80,0.65);
        lin += 0.70*amb*vec3(0.70,0.80,1.00)*occ;
        lin += 1.00*fre*vec3(1.20,1.10,1.00)*occ;
        col = col*lin;
        col += 15.00*spe*vec3(1.00,0.90,0.70);
    }

    return col;
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

mat2 rot(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c,-s,s,c);
}

vec3 transform( in vec4 p )
{
    p.xw *= rot(time*0.41);
    p.yw *= rot(time*0.23);
    p.xy *= rot(time*0.73);
    p.wz *= rot(time*0.37);
    
    // orthogonal projection
    #if PROJECTION==0
    return p.xyz;
    #else
    // perspective projection
    return 2.5*p.xyz/(3.0+p.w);
    #endif
}

void main(void)
{
    float time = time;

    // rotate 4D cube
    v00 = transform( vec4(-1,-1,-1,-1));
    v01 = transform( vec4(-1,-1,-1, 1));
    v02 = transform( vec4(-1,-1, 1,-1));
    v03 = transform( vec4(-1,-1, 1, 1));
    v04 = transform( vec4(-1, 1,-1,-1));
    v05 = transform( vec4(-1, 1,-1, 1));
    v06 = transform( vec4(-1, 1, 1,-1));
    v07 = transform( vec4(-1, 1, 1, 1));
    v08 = transform( vec4( 1,-1,-1,-1));
    v09 = transform( vec4( 1,-1,-1, 1));
    v10 = transform( vec4( 1,-1, 1,-1));
    v11 = transform( vec4( 1,-1, 1, 1));
    v12 = transform( vec4( 1, 1,-1,-1));
    v13 = transform( vec4( 1, 1,-1, 1));
    v14 = transform( vec4( 1, 1, 1,-1));
    v15 = transform( vec4( 1, 1, 1, 1));
    
#ifdef BBOX
    bboxMin = min( min( min( min(v00,v01), min(v02,v03) ), min( min(v04,v05), min(v06,v07) ) ),
                   min( min( min(v08,v09), min(v10,v11) ), min( min(v12,v13), min(v14,v15) ) ) );
    bboxMax = max( max( max( max(v00,v01), max(v02,v03) ), max( max(v04,v05), max(v06,v07) ) ),
                   max( max( max(v08,v09), max(v10,v11) ), max( max(v12,v13), max(v14,v15) ) ) );
#endif
    
    // camera (static)
    vec3 ro = vec3( 4.5, 1.5, 0.0 );
    vec3 ta = vec3( 0.0, 0.0, 0.0 );
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );

    vec3 tot = vec3(0.0);
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(gl_FragCoord.xy+o)-resolution.xy)/resolution.y;
        float seed =  gl_FragCoord.x + gl_FragCoord.y*131.1 + time + 17.1*float(m) + 37.4*float(n);
#else    
        vec2 p = (2.0*gl_FragCoord-resolution.xy)/resolution.y;
        float seed =  gl_FragCoord.x + gl_FragCoord.y*131.1 + time;
#endif

        // ray direction
        vec3 rd = ca * normalize( vec3(p.xy,2.0) );

        // render    
        vec3 col = render( ro, rd, seed );

        // gamma
        col = pow( col, vec3(0.4545) );

        tot += col;
#if AA>1
    }
    tot /= float(AA*AA);
#endif

    // cheap dither to remove banding from background
    tot += 0.5*sin(gl_FragCoord.x)*sin(gl_FragCoord.y)/256.0;
    
    glFragColor = vec4( tot, 1.0 );
}
