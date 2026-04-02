#version 420

// original https://www.shadertoy.com/view/NdsXRs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// width compensing scarity variant of https://shadertoy.com/view/fdXXRX
// variant of https://shadertoy.com/view/fdXXR2
// gradient + 1pix-width lines + flownoise variant of https://shadertoy.com/view/NdXXRj
// interpolated variant of https://shadertoy.com/view/sdsXzB

#define keyToggle(a) ( texelFetch(iChannel3,ivec2(a,2),0).x > 0.)
#define hash(p )     ( 2.* fract(sin((p)*mat2(127.1,311.7, 269.5,183.3)) *43758.5453123) - 1. ) \
                    *  mat2(cos(time+vec4(0,11,33,0)))
  #define draw(v,d,w)  clamp(1. - abs( fract(v-.5) - .5 ) / (d) + w, 0.,1.) // correct version
//#define draw(v,d,w)  clamp(1. - abs( fract(v   ) - .5 ) / (d) + w, 0.,1.) // nicer here :-)
#define hue(v)       ( .6 + .6 * cos( 6.3*(v)  + vec4(0,23,21,0)  ) )

//#define func( P )  ( mod(time,4.) > 2. ? perlin( .5*(P) ) : noise( P ) )
//#define func( P )  ( keyToggle(32) ? perlin( .5*(P) ) : noise( P ) )
#define func( P )  ( perlin( .5*(P) ) )
#define grad(x,y)      dot( hash( i+vec2(x,y) ), f-vec2(x,y) )

float noise( vec2 p )
{
    vec2 i = floor(p), f = fract(p), // u = f*f*(3.-2.*f);              // = smoothstep
                                        u = f*f*f*( 10. +f*(6.*f-15.)); // better with derivatives
    return mix( mix( grad(0,0), grad(1,0), u.x),
                mix( grad(0,1), grad(1,1), u.x), u.y);
}

float perlin( vec2 U ) { // inspired from https://www.shadertoy.com/view/XdXGW8
    float v = 0., s = .5;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    for( int i=0; i<3; i++, s/=2., U*=m )
        v  += s * noise( U ); 
    return v;
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec4 O = glFragColor;

    vec2 R = resolution.xy, eps = vec2(1e-3,0),
         U = u / R.y,
         P = 8.*U - vec2(0.,.5*time);    
    O = vec4(0);
    float l, dl, f = func(P),
 // df = fwidth(f);
    df = length( ( vec2( func(P + eps.xy), func(P + eps.yx) ) -f ) / eps.x )*fwidth(P.x);
#if 0
    l = exp2(floor(log2(2.*fwidth(P.x)/df)));              // subvid amount (relative)
    dl =     fract(log2(2.*fwidth(P.x)/df));      
#else
    l = exp2(floor(log2(1./22./df)));                      // subvid amount (absolute)
    dl =     fract(log2(1./22./df));
#endif

    U -= .5*R/R.y;
    float w = .5*( 1.1+sin( 4.*(dot(U,U)-.5*time)) );
    f *= w;
 // f *= exp(- 4.* dot(U,U));
 // f *= max(.1, 1.-4.*dot(U,U));
#if 0                                                             // draw isolines using sin
    O = vec4(.5+.5*  mix( sin(50.*l*f) , sin(100.*l*f), dl ) ) * hue(6.*l); 
#else                                                             // draw isolines 
    df *= w;
    l *= 8.; 
    O += mix( draw(    f*l,    l*df , .5/w ),
              draw( 2.*f*l, 2.*l*df , .5/w ),
              dl ); // * hue(6.*l);
#endif
    
    O = sqrt(O);                                                  // to sRGB

    glFragColor = O;
}
