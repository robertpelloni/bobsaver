#version 420

// original https://www.shadertoy.com/view/WsGXDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// flownoise variant of https://shadertoy.com/view/WdGXWG
// curve variant of 2D https://shadertoy.com/view/wdKXzd

// gradient noise derived from https://www.shadertoy.com/view/XdXGW8

float _z;
vec2 hash( vec2 x ) 
{
 // float s = 0.;                      // standard Perlin noise
    float s = mod(x.x+x.y,2.)*2.-1.;   // flow noise checkered rotation direction
 // float s = 5.;                      // flow noise universal rotation direction
 // s *= time;                        // same rotation speed at all scales
    s *= time/ _z;                    // rotation speed increase with small scale
    const vec2 k = vec2( .3183099, .3678794 );
    x = x*k + k.yx;
    return ( -1. + 2.*fract( 16. * k*fract( x.x*x.y*(x.x+x.y)) ) ) 
        *  mat2(cos( s + vec4(0,33,11,0))); // rotating gradients. rot: https://www.shadertoy.com/view/XlsyWX
}

float noise( vec2 p )
{
    vec2 i = floor( p ),
         f = fract( p ),
         u = f*f*(3.-2.*f);

#define P(x,y) dot( hash( i + vec2(x,y) ), f - vec2(x,y) )
    return mix( mix( P(0,0), P(1,0), u.x),
                mix( P(0,1), P(1,1), u.x), u.y);
}

float perlin( vec2 p )  //fractal noise
{    
    mat2 m = mat2(2.); // mat2( 1.6,  1.2, -1.2,  1.6 );
    float v  = 0.,s = 1.;
    for( int i=0; i < 7; i++, s /= 2. ) { _z = s; // for flownoise
        v += s*noise( p ); p *= m;
    }
    return v;
}

// -----------------------------------------------

#define S(v) smoothstep( pix, 0., v )

void main(void)
{
    vec4 O = glFragColor;
    vec2 u = gl_FragCoord.xy;

    vec2 R = resolution.xy,
         U = ( u -.5*R ) / R.y * 2.,
         M = mouse*resolution.xy.xy; if (M!=vec2(0)) M = ( M -.5*R ) / R.y * 2.;
    O -= O;
    float pix = 3./R.y,
          y = perlin(vec2(U.x,0)) + U.x*M.y;
    
    O += S(abs(y - U.y));

    O.g += S(length(U)-.03);
    O.r += S(length(U-vec2(1,M.y))-.03);
    O.b += S(length(U+vec2(1,M.y))-.03);
      //O.b += S(abs(U.y - U.x*M.y));

    glFragColor = O;

}
