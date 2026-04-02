#version 420

//original https://www.shadertoy.com/view/Xd2GRh

varying vec2 pos;

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//------------------ ------------------------------------------
// complex number operations
vec2 cadd( vec2 a, float s ) { return vec2( a.x+s, a.y ); }
vec2 cmul( vec2 a, vec2 b )  { return vec2( a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x ); }
vec2 cdiv( vec2 a, vec2 b )  { float d = dot(b,b); return vec2( dot(a,b), a.y*b.x - a.x*b.y ) / d; }
vec2 csqr( vec2 a ) { return vec2(a.x*a.x-a.y*a.y, 2.0*a.x*a.y ); }
vec2 csqrt( vec2 z ) { float m = length(z); return sqrt( 0.5*vec2(m+z.x, m-z.x) ) * vec2( 1.0, sign(z.y) ); }
vec2 conj( vec2 z ) { return vec2(z.x,-z.y); }
vec2 cpow( vec2 z, float n ) { float r = length( z ); float a = atan( z.y, z.x ); return pow( r, n )*vec2( cos(a*n), sin(a*n) ); }
vec2 cexp( vec2 z) {  return exp( z.x )*vec2( cos(z.y), sin(z.y) ); }
vec2 clog( vec2 z) {  return vec2( 0.5*log(z.x*z.x+z.y*z.y), atan(z.y,z.x)); }
vec2 csin( vec2 z) { float r = exp(z.y); return 0.5*vec2((r+1.0/r)*sin(z.x),(r-1.0/r)*cos(z.x));}
vec2 ccos( vec2 z) { float r = exp(z.y); return 0.5*vec2((r+1.0/r)*cos(z.x),-(r-1.0/r)*sin(z.x));}
//------------------------------------------------------------

vec2 z0;

vec2 f( vec2 x ){return csin(cpow(x+z0,-2.0))-0.9*(1.0+2.0*sin(0.05*time))*x + z0  ;}

void main(void)
{
    float range =4.0;    
    vec2 q = (gl_FragCoord.xy-mouse.xy) / resolution.xy;
    vec2 p = -0.5*range + range * q;
    p.y *= resolution.y/resolution.x;
    
    
   
    // iterate        
    
    vec2 z = p;
    z0=p;
    float g = 1e10;
    float k=100.0;
    vec2 z1;
    float dz;
    
        
    for(int i=0; i<100; i++ )
    {
        vec2 prevz=z;
       

        // function        
        z = f( z );
        
        g = min( g, dot(z-1.0,z-1.0) );
        
        // bailout
        dz = dot(z-prevz,z-prevz);        
        if( dz<0.00001 ){
            k = dz/0.00001;
            z = k*z+(1.0-k)*prevz;
            k= k+float(i);
            break;
        }
        if( dz>10000.0 ){
            k = 10000.0/dz;
            z = k*z+(1.0-k)*prevz;
            k= k+float(i);
            break;
            } 
        
    }
    
    float it = 1.0-k/100.0;
    
    
    vec3 col = 0.4+ 0.6*sin(vec3(-0.5,-0.2,0.8)+2.3+log(g*abs(z.y*z.x))); 

    glFragColor = vec4( col, 1.0 );
}
