#version 420

// original https://www.shadertoy.com/view/WsSyRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// simple raymarch blinking eye test using IQ's classic eye texture :)
// optimized eye calc / texture lookup etc.

#define MARCHSTEPS 80
#define AA    2
#define PI    3.1415926
#define    TAU    6.28318

// ---------------
// IQ's classic eye texture 
const mat2 m = mat2( 0.80,  0.60, -0.60,  0.80 );

float hash( float n )
{
    return fract(sin(n)*43758.5453);
}

float noise( in vec2 x )
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0;
    return mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
               mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
}

float fbm( vec2 p )
{
    float f = 0.50000*noise( p ); p = m*p*2.02;
    f += 0.25000*noise( p ); p = m*p*2.03;
    f += 0.12500*noise( p ); p = m*p*2.01;
    f += 0.06250*noise( p ); p = m*p*2.04;
    f += 0.03125*noise( p );
    return f/0.984375;
}

float length2( vec2 p )
{
    vec2 q = p*p*p*p;
    return pow( q.x + q.y, 1.0/4.0 );
}

vec3 eyetex(vec2 p)
{
    float r = length( p );
    float a = atan( p.y, p.x );
    float dd = 0.2*sin(1.4*time);
    float ss = 1.0 + clamp(1.0-r,0.0,1.0)*dd;
    r *= ss;
    vec3 col = vec3( 0.0, 0.3, 0.4 );
    float f = fbm( 5.0*p );
    col = mix( col, vec3(0.2,0.5,0.4), f );
    col = mix( col, vec3(0.9,0.6,0.2), 1.0-smoothstep(0.2,0.6,r) );
    a += 0.05*fbm( 20.0*p );
    f = smoothstep( 0.3, 1.0, fbm( vec2(20.0*a,6.0*r) ) );
    col = mix( col, vec3(1.0,1.0,1.0), f );
    f = smoothstep( 0.4, 0.9, fbm( vec2(15.0*a,10.0*r) ) );
    col *= 1.0-0.5*f;
    col *= 1.0-0.25*smoothstep( 0.6,0.8,r );
    f = 1.0-smoothstep( 0.0, 0.6, length2( mat2(0.6,0.8,-0.8,0.6)*(p-vec2(0.3,0.5) )*vec2(1.0,2.0)) );
    //col += vec3(1.0,0.9,0.9)*f*0.985;
    col *= vec3(0.8+0.2*cos(r*a));
    f = 1.0-smoothstep( 0.2, 0.25, r );
    col = mix( col, vec3(0.0), f );
    f = smoothstep( 0.79, 0.82, r );
    col = mix( col, vec3(1.0), f );    
    return col;
}
// end of IQ's classic eye texture
// ---------------

// ----------
// background stripes
vec3 hsv2rgb( in vec3 c )
{
    vec3 rgb = clamp( abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0 );
    return c.z * mix( vec3(1.0), rgb, c.y);
}

vec3 SSTLines(vec2 duv, float nl, float grad,float thickness, float wibblesize, float wibblespeed, float glowintensity, float glowclamp, float extraglow)
{
       vec3 col2 =  hsv2rgb(vec3(time*0.025,0.5,0.5));
    duv.y -= (floor(duv.x)*grad) + (duv.x*grad);
    duv = fract(duv);
    float l1 = abs(fract((duv.x*grad-duv.y)*nl) -0.5);
    float dd = sin(time*wibblespeed+duv.x*6.28)*wibblesize;
    l1 = min(glowclamp, (thickness+dd)/l1);
    vec3 col = col2*l1*glowintensity+(dd*extraglow);
    return mix(col2,col,l1);
}

vec3 background(vec2 uv)
{
    uv *= 0.5+sin(time)*0.25;    // zoom
    uv.y += time*0.1;            // vscroll
    return SSTLines(uv, 5.0, sin(time*0.35)*0.2, 0.15,  0.015, 6.5, 3.25, 1.0, 9.0);
}
//end of background stripes
// ----------

float pMod1(inout float p, float size)
{
    float halfsize = size*0.5;
    float c = floor((p + halfsize)/size);
    p = mod(p + halfsize, size) - halfsize;
    return c;
}

float ssub( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

// simplified :)
float _cindex = 0.0;            // colour index
float map( in vec3 p )
{
    float c = 3.3+pMod1(p.y,2.5);
    p.x += sin(time+c*0.5)*4.0;
    c *= 7.7+pMod1(p.x,2.5);
    float d1 = length(p)-0.9;
    float d2 = length(vec2(p.z-1.6,p.y))-(1.0-pow((sin( mod(time+c*0.35, 200.))*0.5+0.5), 40.));
    d2 = ssub(d2, d1-0.1, 0.05);
    _cindex = 2.0+step(d1,d2);
    return  min(d2, d1);    
}

vec3 calcNormal( in vec3 pos )
{
    vec2 e = vec2(1.0,-1.0)*0.5773;
    const float eps = 0.0005;
    return normalize( e.xyy*map( pos + e.xyy*eps ) + 
                      e.yyx*map( pos + e.yyx*eps ) + 
                      e.yxy*map( pos + e.yxy*eps ) + 
                      e.xxx*map( pos + e.xxx*eps ) );
}
    
// ----------

void main(void)
{
       vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 bg = background(uv)*0.65;
     // camera movement    
    float an = sin(time*0.7)*0.35;
    float dist = 8.0+sin(time*0.8)*4.0;
    an+=PI*0.5;
    float y = 0.0;
    
    //if (mouse*resolution.xy.z>0.5)
    //{
    //    an=mouse*resolution.xy.x/resolution.x*4.0;
    //    y = (mouse*resolution.xy.y/resolution.y)*8.0;
    //    y-=4.0;
    //}
    
    vec3 ro = vec3( dist*cos(an), -y, dist*sin(an) );
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
        const float tmax = 40.0;
        float t = 0.0;
        for( int i=0; i<MARCHSTEPS; i++ )
        {
            vec3 pos = ro + t*rd;
            float h = map(pos);
            if( h<0.0001 || t>tmax ) break;
            t += h;
        }
    
        // shading/lighting    
        vec3 col = bg;    //vec3(0.1);
        if( t<tmax )
        {
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);
            float dif = clamp( dot(nor,vec3(0.57703)), 0.0, 1.0 );

            // nasty :)
            vec3 ambcol =  vec3(0.65, 0.4, 0.35);
            if(_cindex > 2.5)
                ambcol = eyetex(vec2((0.25-( atan(nor.z, nor.x) / TAU)) * 12.0, -( asin(nor.y) / PI)*6.0))*0.9;
            col = (ambcol*ambcol)*(dif+0.25);
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
