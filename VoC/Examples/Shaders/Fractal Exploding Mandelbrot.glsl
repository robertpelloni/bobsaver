#version 420

// original https://www.shadertoy.com/view/XtscDl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Very nice coloring, zoom and anti-aliasing by:

// inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// See here for more information on smooth iteration count:
//
// http://iquilezles.org/www/articles/mset_smooth/mset_smooth.htm

// Exploding Pulsing Mandelbrot Set by Chris M. Thomasson
// Orbit trap color by Chris M. Thomasson
// http://www.fractalforums.com/index.php?action=gallery;sa=view;id=20582

vec2 ct_cmul(in vec2 p0, in vec2 p1)
{
    return vec2(p0.x * p1.x - p0.y * p1.y, p0.x * p1.y + p0.y * p1.x);
}

// increase this if you have a very fast GPU
#define AA 2

void main(void)
{
    vec3 col = vec3(0.0);
    
#if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        vec2 p = (-resolution.xy + 2.0*(gl_FragCoord.xy+vec2(float(m),float(n))/float(AA)))/resolution.y;
        float w = float(AA*m+n);
        float time = time + 0.5*(1.0/24.0)*w/float(AA*AA);
#else    
        vec2 p = (-resolution.xy + 2.0*gl_FragCoord.xy)/resolution.y;
        float time = time;
#endif
    
        float zoo = 1.0 + 0.38*cos(.07*time);
        float coa = cos( 0.15*(1.0-zoo)*time );
        float sia = sin( 0.15*(1.0-zoo)*time );
        zoo = pow( zoo,8.0);
        vec2 xy = vec2( p.x*coa-p.y*sia, p.x*sia+p.y*coa);
        vec2 c = vec2(-.745,.186) + xy*zoo;

        float B = 200.0;// + abs(cos(time * .25)) * 30.0;
        float l = 0.0;
        float ct_o = 999999999.0;
        vec2 z  = vec2(0.0);
        int ct_retry = 0;
        int ct_switch = 0;
        for( int i=0; i<256; i++ )
        {
            // z = z*z + c        
            z = vec2( z.x*z.x - z.y*z.y * (1.0 + abs(cos(time * 2.0)) * .1), (2.0 + abs(sin(time * 3.0)) * .1)*z.x*z.y ) + c;
            ct_o = min(ct_o, sqrt(z.x * z.x + z.y * z.y));
        
            if(z.x * z.x + z.y * z.y > B)
            {
                // Chris M. Thomassons Exploder!
                if (ct_retry < 7)
                {
                    if (ct_switch == 0)
                    {
                        z = ct_cmul(z, vec2(.02 + abs(cos(time * .5)) * .02, .07));
                        ct_switch = 1;
                    }
                    
                    else
                    {
                        z = ct_cmul(z, vec2(-.04, -(.04 + abs(sin(time)) * .041)));
                        ct_switch = 0;
                    }
                    
                    ++ct_retry;
                    continue;
                }
                break;
            }

            l += 1.0;
        }

        // ------------------------------------------------------
        // smooth interation count
        //float sl = l - log(log(length(z))/log(B))/log(2.0);
        
        // equivalent optimized smooth interation count
        float sl = l - log2(log2(dot(z,z))) + 4.0; 
        // ------------------------------------------------------
    
        float al = smoothstep( -5.0, 0.0, cos(3.14*time) );
        l = mix( l, sl, al );

        // CT: added some color wrt ct_o variable.
        col += 0.5 + 0.5*cos( 3.0 + l*0.15 + vec3(.5 + cos(3.14*time) * .5, ct_o * l * .05, 0));
#if AA>1
    }
    col /= float(AA*AA);
#endif

    glFragColor = vec4( col, 1.0 );
}
