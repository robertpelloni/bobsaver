#version 420

// original https://www.shadertoy.com/view/XdfBzH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// --- base gradient noise + derivative from iq https://www.shadertoy.com/view/XdXBRH
// --- plus flownoise
// see also "laplacian" noise: https://www.shadertoy.com/view/XsXBzH

float T = 0.;
vec2 hash( in vec2 x ) 
{
    float t = T  * sign(mod(x.x+x.y,2.)-.5), // optional checker swirls
          c = cos(t), s=sin(t);
    const vec2 k = vec2( 0.3183099, 0.3678794 );
    x = x*k + k.yx;
    x =  -1. + 2.*fract( 16. * k*fract( x.x*x.y*(x.x+x.y)) );
    return x * mat2(c,-s,s,c); // flownoise
 // return vec2(cos(t+3.1416*x.x), s = sin(t+3.1416*x.x)); // iq variant
}

// return gradient noise (in x) and its derivatives (in yz)
vec3 noised( in vec2 p )
{
    vec2 i = floor( p ),
         f = fract( p );

#if 1 // quintic interpolation
    vec2 u = f*f*f*(f*(f*6.-15.)+10.),
        du = 30.*f*f*(f*(f-2.)+1.);
#else // cubic interpolation
    vec2 u = f*f*(3.-2.*f),
        du = 6.*f*(1.-f);
#endif    
    
    vec2 ga = hash( i + vec2(0,0) ),
         gb = hash( i + vec2(1,0) ),
         gc = hash( i + vec2(0,1) ),
         gd = hash( i + vec2(1,1) );
    
    float va = dot( ga, f - vec2(0,0) ),
          vb = dot( gb, f - vec2(1,0) ),
          vc = dot( gc, f - vec2(0,1) ),
          vd = dot( gd, f - vec2(1,1) );

    return vec3( va + u.x*(vb-va) + u.y*(vc-va) + u.x*u.y*(va-vb-vc+vd),   // value
                 ga + u.x*(gb-ga) + u.y*(gc-ga) + u.x*u.y*(ga-gb-gc+gd) +  // derivatives
                 du * (u.yx*(va-vb-vc+vd) + vec2(vb,vc) - va));
}

// -----------------------------------------------
 

void main(void)
{
    glFragColor -= glFragColor; 
    float s = 1.; vec4 C = vec4(1.,.9,.8,0);
    for (int i=0; i<4; i++) {
        T = time; // * s;                            // optional *s

        glFragColor +=  .3*length( noised( s*gl_FragCoord.xy/64.).yz ) *C; // /s;   // optional /s // strips
        s *= 2.; C *= C;
    
    }
}
