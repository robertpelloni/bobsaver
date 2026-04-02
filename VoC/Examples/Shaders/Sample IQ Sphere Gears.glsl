#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tt2XzG

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Basically the same as https://www.shadertoy.com/view/XlVcWz
// but optimized through symmetry so it only needs to evaluate
// four gears instead of 18. Also I made the gears with actual
// boxes rather than displacements, which creates an exact SDF
// allowing me to raymarch the scene at the speed of light, or
// in other words, without reducing the raymarching step size.
// Also I'm using a bounding volume to speed things up further
// so I can affor some nice ligthing and motion blur.

#define AA 1
//#define AA 2  // Set AA to 1 if your machine is too slow

float time2;

// http://iquilezles.org/www/articles/smin/smin.htm
float smax( float a, float b, float k )
{
    float h = max(k-abs(a-b),0.0);
    return max(a, b) + h*h*0.25/k;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere( in vec3 p, in float r )
{
    return length(p)-r;
}

// http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdVerticalCapsule( vec3 p, float h, float r )
{
    p.y -= clamp( p.y, 0.0, h );
    return length( p ) - r;
}

// http://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm
float sdCross( in vec2 p, in vec2 b, float r ) 
{
    p = abs(p); p = (p.y>p.x) ? p.yx : p.xy;
    
    vec2  q = p - b;
    float k = max(q.y,q.x);
    vec2  w = (k>0.0) ? q : vec2(b.y-p.x,-k);
    
    return sign(k)*length(max(w,0.0)) + r;
}

// http://iquilezles.org/www/articles/intersectors/intersectors.htm
vec2 iSphere( in vec3 ro, in vec3 rd, in float rad )
{
    float b = dot( ro, rd );
    float c = dot( ro, ro ) - rad*rad;
    float h = b*b - c;
    if( h<0.0 ) return vec2(-1.0);
    h = sqrt(h);
    return vec2(-b-h, -b+h );
}

//----------------------------------

float dents( in vec2 q, in float off, in float tr )
{
    const float an = 6.283185/12.0;
    float fa = (atan(q.y,q.x)+an*0.5)/an;
    float sym = an*floor(fa);
    vec2 r = mat2(cos(sym),-sin(sym), sin(sym), cos(sym))*q;
    
#if 1
    float d = length(max(abs(r-vec2(0.17,0))-tr*vec2(0.04,0.019),0.0));
#else
    const mat2 inc = mat2(0.866025, 0.5, -0.5, 0.866025 );
    if( fract(fa)>0.5 ) r = r*inc;
    vec2 p0 = abs(    r - vec2(0.17,0.0)) - vec2(0.04,0.019);
    vec2 p1 = abs(inc*r - vec2(0.17,0.0)) - vec2(0.04,0.019);
    float d =   min(max(p0.x,p0.y),0.0) + length(max(p0,0.0));
    d = min( d, min(max(p1.x,p1.y),0.0) + length(max(p1,0.0)) );
#endif

    return d - 0.005*tr;
}

vec4 gear(vec3 q, float s, float o, float a)
{
    // animate    
    float an = 6.283185*time2/3.0;
    an = an*s*o + a*6.283185/24.0;
    
    float an2 = 2.0*min(1.0-2.0*abs(fract(0.5+time2/10.0)-0.5),1.0/2.0);
    vec3 tr = min( 10.0*an2 - vec3(4.0,6.0,8.0),1.0);
    
    // rotate
    float co = cos(an), si = sin(an);
    q.xz = mat2(co,si,-si,co)*q.xz;
    q.y *= s;

    // ring
    float d = abs(length(q.xz) - 0.155*tr.y) - 0.018;

    // add dents
    d = min( d, dents(q.xz,o,tr.z) );

    // slice it
    float de = -0.0015*clamp(600.0*abs(dot(q.xz,q.xz)-0.155*0.155),0.0,1.0);
    d = smax( d, abs(length(q)-0.5)-0.03+de, 0.005*tr.z );

    // add cross
    float d3 = sdCross( q.xz, vec2(0.15,0.022)*tr.y, 0.02*tr.y );
    vec2 w = vec2( d3, abs(q.y-0.485)-0.005*tr.y );
    d3 = min(max(w.x,w.y),0.0) + length(max(w,0.0))-0.003*tr.y;
    d = min( d, d3 ); 
        
    // add pivot
    d = min( d, sdVerticalCapsule( q, 0.5*tr.x, 0.01 ));

    // base
    d = min( d, sdSphere(q-vec3(0.0,0.12,0.0),0.025) );
    
    return vec4(d,q.xzy);
}

vec4 map( in vec3 p)
{
    // center
    vec4 d = vec4( sdSphere(p,0.12), p );
    
    // gears. There are 18, but we only evaluate 6    
    vec3 qy = vec3(p.x*0.7071+p.z*0.7071, p.y, p.z*0.7071-p.x*0.7071);
    vec3 qx = vec3(p.x, p.y*0.7071+p.z*0.7071, p.z*0.7071-p.y*0.7071);
    vec3 qz = vec3(p.x*0.7071+p.y*0.7071, p.y*0.7071-p.x*0.7071, p.z);

    float sx=1.0;if( abs(qx.y)>abs(qx.z) ) {sx=-1.0; qx.yz=qx.zy;}
    float sy=1.0;if( abs(qy.z)>abs(qy.x) ) {sy=-1.0; qy.zx=qy.xz;}
    float sz=1.0;if( abs(qz.x)>abs(qz.y) ) {sz=-1.0; qz.xy=qz.yx;}
    
    vec4 t;
#if 0
    t = gear( p.xyz, sign(p.y),-1.0,0.0,time2 ); if( t.x<d.x ) d=t;
    t = gear( p.zxy, sign(p.x),-1.0,0.0,time2 ); if( t.x<d.x ) d=t;
    t = gear( p.yzx, sign(p.z),-1.0,0.0,time2 ); if( t.x<d.x ) d=t;
#else    
    float px=1.0; 
    if( abs(p.x)>abs(p.y) && abs(p.x)>abs(p.z) ) {px=-1.0;p=p.yxz;}
    if( abs(p.z)>abs(p.y) && abs(p.z)>abs(p.x) ) {px=-1.0;p=p.xzy;}
    t = gear( p.xyz, sign(p.y),-px,0.0 ); if( t.x<d.x ) d=t;
#endif    
    t = gear( qx.yzx,sign(qx.z),sx,1.0 ); if( t.x<d.x ) d=t;
    t = gear( qy.zxy,sign(qy.x),sy,1.0 ); if( t.x<d.x ) d=t;
    t = gear( qz.xyz,sign(qz.y),sz,1.0 ); if( t.x<d.x ) d=t;
    
    return d;
}

#define ZERO min(frames,0)

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos)
{
#if 0
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.00025;
    return normalize( e.xyy*map( pos + e.xyy*eps, time2 ).x + 
                      e.yyx*map( pos + e.yyx*eps, time2 ).x + 
                      e.yxy*map( pos + e.yxy*eps, time2 ).x + 
                      e.xxx*map( pos + e.xxx*eps, time2 ).x );
#else
    // klems's trick to prevent the compiler from inlining map() 4 times
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+0.0005*e).x;
    }
    return normalize(n);
#endif    
}

float calcAO( in vec3 pos, in vec3 nor)
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=ZERO; i<5; i++ )
    {
        float h = 0.01 + 0.12*float(i)/4.0;
        float d = map( pos+h*nor ).x;
        occ += (h-d)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow( in vec3 ro, in vec3 rd, in float k )
{
    float res = 1.0;
    
    // bounding sphere
    vec2 b = iSphere( ro, rd, 0.535 );
    if( b.y>0.0 )
    {
        // raymarch
        float tmax = b.y;
        float t    = max(b.x,0.001);
        for( int i=0; i<64; i++ )
        {
            float h = map( ro + rd*t ).x;
            res = min( res, k*h/t );
            t += clamp( h, 0.012, 0.2 );
            if( res<0.001 || t>tmax ) break;
        }
    }
    
    return clamp( res, 0.0, 1.0 );
}

vec4 intersect( in vec3 ro, in vec3 rd)
{
    vec4 res = vec4(-1.0);
    
    // bounding sphere
    vec2 tminmax = iSphere( ro, rd, 0.535 );
    if( tminmax.y>0.0 )
    {
        // raymarch
        float t = max(tminmax.x,0.001);
        for( int i=0; i<128 && t<tminmax.y; i++ )
        {
            vec4 h = map(ro+t*rd);
            if( h.x<0.001 ) { res=vec4(t,h.yzw); break; }
            t += h.x;
        }
    }
    
    return res;
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
    vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=ZERO; m<AA; m++ )
    for( int n=ZERO; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(gl_FragCoord.xy+o)-resolution.xy)/resolution.y;
        float d = 0.5*sin(gl_FragCoord.x*147.0)*sin(gl_FragCoord.y*131.0);
        time2 = time - 0.5*(1.0/24.0)*(float(m*AA+n)+d)/float(AA*AA-1);
        #else    
        vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
        time2 = time+5;
        #endif

        // camera    
        float an = 6.2831*time2/40.0;
        vec3 ta = vec3( 0.0, 0.0, 0.0 );
        vec3 ro = ta + vec3( 1.3*cos(an), 0.5, 1.2*sin(an) );
        
        ro += 0.005*sin(92.0*time2/40.0+vec3(0.0,1.0,3.0));
        ta += 0.009*sin(68.0*time2/40.0+vec3(2.0,4.0,6.0));
        
        // camera-to-world transformation
        mat3 ca = setCamera( ro, ta, 0.0 );
        
        // ray direction
        float fl = 2.0;
        vec3 rd = ca * normalize( vec3(p,fl) );

        // background
        vec3 col = vec3(1.0+rd.y)*0.03;
        
        // raymarch geometry
        vec4 tuvw = intersect( ro, rd);
        if( tuvw.x>0.0 )
        {
            // shading/lighting    
            vec3 pos = ro + tuvw.x*rd;
            vec3 nor = calcNormal(pos);
                        
            vec3 mate = vec3( 0.25 );
            vec3 te = vec3(0.5);
            
            mate = 0.22*te;
            float len = length(pos);
            
            mate *= 1.0 + vec3(2.0,0.5,0.0)*(1.0-smoothstep(0.121,0.122,len) ) ;
            
            float focc  = 0.1+0.9*clamp(0.5+0.5*dot(nor,pos/len),0.0,1.0);
                  focc *= 0.1+0.9*clamp(len*2.0,0.0,1.0);
            float ks = clamp(te.x*1.5,0.0,1.0);
            vec3  f0 = mate;
            float kd = (1.0-ks)*0.125;
            
            float occ = calcAO( pos, nor ) * focc;
            
            col = vec3(0.0);
            
            // top
            {
            vec3  lig = normalize(vec3(0.8,0.2,0.6));
            float dif = clamp( dot(nor,lig), 0.0, 1.0 );
            vec3  hal = normalize(lig-rd);
            float sha = 1.0; if( dif>0.001 ) sha = calcSoftshadow( pos+0.001*nor, lig, 20.0 );
            vec3  spe = pow(clamp(dot(nor,hal),0.0,1.0),16.0)*(f0+(1.0-f0)*pow(clamp(1.0+dot(hal,rd),0.0,1.0),5.0));
            col += kd*mate*2.0*vec3(1.00,0.70,0.50)*dif*sha;
            col += ks*     2.0*vec3(1.00,0.80,0.70)*dif*sha*spe*3.14;
            }

            // side
            {
            vec3  ref = reflect(rd,nor);
            float fre = clamp(1.0+dot(nor,rd),0.0,1.0);
            float sha = occ;//0.2*occ + 0.8*calcSoftshadow( pos+0.001*vec3(0,1,0), vec3(0.0,1.0,0.0), 3.0, time2 );
            col += kd*mate*25.0*vec3(0.19,0.22,0.24)*(0.6 + 0.4*nor.y)*sha;
            col += ks*     25.0*vec3(0.19,0.22,0.24)*sha*smoothstep( -1.0+1.5*focc, 1.0-0.4*focc, ref.y ) * (f0 + (1.0-f0)*pow(fre,5.0));
            }
            
            // bottom
            {
            float dif = clamp(0.4-0.6*nor.y,0.0,1.0);
            col += kd*mate*5.0*vec3(0.25,0.20,0.15)*dif*occ;
            }
        }
        
        // compress        
        // col = 1.2*col/(1.0+col);
        
        // vignetting
        col *= 1.0-0.1*dot(p,p);
        
        // gamma        
        tot += pow(col,vec3(0.45) );
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    // s-curve    
    tot = min(tot,1.0);
    tot = tot*tot*(3.0-2.0*tot);
    
    // cheap dithering
    tot += sin(gl_FragCoord.x*114.0)*sin(gl_FragCoord.y*211.1)/512.0;

    glFragColor = vec4( tot, 1.0 );
}
