#version 420

// original https://www.shadertoy.com/view/Xt2fRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2016
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// The visuals for the third part of my video "Collatz and Self Similarity": 
//
// https://www.youtube.com/watch?v=GJDz4kQqTV4
//
// (minus the text overlays, which cannot do in the online version of Shadertoy

//------------------------------------------------------
// global
//------------------------------------------------------

#define AA 2   // supersampling level. Make higher for more quality.

const float pi = 3.1415926535897932384626433832795; // should be pronounced "pee" not "pie", dear english speakers!

//------------------------------------------------------
// complex numbers
//------------------------------------------------------

vec2 cadd( vec2 a, float s ) { return vec2( a.x+s, a.y ); }
vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 cdiv( vec2 a, vec2 b )  { float d = dot(b,b); return vec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }
vec2 cmulj( vec2 z ) { return vec2(-z.y,z.x); }
vec3 cexp( vec2 z ) { return vec3( exp(z.x), vec2( cos(z.y), sin(z.y) ) ); }
vec3 cexpj( vec2 z ) { return vec3( exp(-z.y), vec2( cos(z.x), sin(z.x) ) ); }

vec2 rotate(vec2 v, float a) {
    float s = sin(a);
    float c = cos(a);
    mat2 m = mat2(c, -s, s, c);
    return m * v;
}

//------------------------------------------------------
// Visualization
//------------------------------------------------------

vec3 render( in vec2 gl_FragCoordScreen, float time )
{
    float sc = 4.5;
    vec2 ce = vec2(.0,0.0);    

    float zoomDepth = 2.5;
    float eTime = zoomDepth*sin(time/zoomDepth) + zoomDepth;
    
    sc = 4.5 * pow( 0.1, eTime );
        
    vec2 center = vec2(0.5,0.5);
    
    float spinAngle = 0.0;

    vec2 gl_FragCoord = rotate(gl_FragCoordScreen, spinAngle);

    vec2 p = ce + sc*(-resolution.xy+2.0*gl_FragCoord) / resolution.x;
    float e = sc*2.0/resolution.x;
    
    
    vec2 z = rotate(p, time);
    //n = vec2(n.x,0.0);
    
    const float th = 10000000000.0;
    
    vec2 lz = z;
    float d = 0.0;
    float f = 0.0;
    float rmin = th;
    vec2 dz = vec2(1.0,0.0);
    vec2 ldz = dz;
    for( int i=0; i<64; i++ )
    {
        vec3 k = cexpj( pi*z );
        
        lz = z;
        ldz = dz;

        dz = cmul( (vec2(8.0,0.0) - k.x*cmul(k.yz,vec2(5.0-5.0*pi*z.y, pi*(5.0*z.x+2.0))))/4.0, dz );
        
        //rmin = min( rmin, length(cdiv( cadd(7.0*z,2.0) , cadd(5.0*z,2.0) ) - k.x*k.yz) );
        
        z = ( cadd(7.0*z,2.0) - k.x*cmul(k.yz,cadd(5.0*z,2.0)) )/3.9;

        float r = length(z);
        rmin = min( rmin, r );
        if( r>th ) { d=1.0; break; }
        f += 1.0;
    }
    
    vec3 col = vec3(0.0);
    if( d<2.0 )
    {
        col = vec3(1.0,0.6,0.2);
        
        f += clamp( log(th/length(lz))*1.8, 0.0, 1.0 ) - 1.0;
        col = 0.5 + 0.5*cos(0.15*f + 1.5 + vec3(0.2,0.9,1.0));
        col *= 0.027*f;
        
        col += 0.01*sin(40.0*atan(lz.x,lz.y));
        
        float dis = log(length(lz))*length(lz)/length(ldz);
        col += 0.025*sqrt(dis/sc) - 0.1;
        col *= 0.9;
    }
    else
    {
        col = vec3(0.0,0.0,0.0);
    }

   
    //col = clamp( col, 0.0, 1.0 );
      
    return col;

}

void main(void)
{
    vec3 col = vec3(0.0);
    
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 px = gl_FragCoord.xy + vec2(float(m),float(n))/float(AA);
        col += render( px, time );    
    }
    col /= float(AA*AA);
#else
        
    col = render( gl_FragCoord, time );
#endif            
    
    glFragColor = vec4( col, 1.0 );
}
