#version 420

// original https://www.shadertoy.com/view/fslyW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by inigo quilez - iq/2022

// A zoom into a Golden Spiral, which, like all logarithmic spirals,
// is self-similar.

void main(void)
{
    // pixel coordinates
    vec2  op  = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    float opx = 2.0/resolution.y;
    
    // mathematical constants
    const float kt = 6.283185307;         // tau
    const float kh = (1.0+sqrt(5.0))/2.0; // phi
    const float k1 = (5.0-sqrt(5.0))/2.0;
    const float k2 = 4.0*log2(kh);
    const vec2  di = vec2(kh,2.0-kh);
    const vec2  ce = vec2(3,-1)/sqrt(5.0);

    // for time and color dithering
    float ran = fract(sin(gl_FragCoord.xy.x*7.0+17.0*gl_FragCoord.xy.y)*1.317);

    // motion blur loop
    vec3 tot = vec3(0.0);
    #if HW_PERFORMANCE==0
    const int kNumSamples = 6;
    #else
    const int kNumSamples = 12;
    #endif
    for( int mb=0; mb<kNumSamples; mb++ )
    {
        // aperture is half of a frame
        float time = time + (0.5/60.0)*(float(mb)+ran)/float(kNumSamples);

        // loop
        float ft = fract(time/1.0);
        float it = floor(time/1.0);

        // constant (exponential) zoom
        float sca = 0.5*exp2(-ft*k2);
        vec2  p  = sca*op;
        float px = sca*opx;

        vec3 col = vec3(0.0);

        // draw golden rectangles
        {
            float d = 1e20;
            float w = 1.0;
            vec2  q = p + ce;
            for( int i=0; i<20; i++ )
            {
                // square (in L2)
                float t = max(abs(q.x),abs(q.y))-w;

                // fill
                if( t<0.0 )
                {
                    // color  (https://iquilezles.org/www/articles/palettes/palettes.htm)
                    float id = float(i) + it*4.0;
                    col = vec3(0.7,0.5,0.4) + vec3(0.1,0.2,0.2)*cos(kt*id/12.0+vec3(2.0,2.5,3.0) );
                    // texture
                    col += 0.04*cos(kt*p.x*8.0/w)*cos(kt*p.y*8.0/w);
                }    

                // border (https://iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm)
                d = min( d, abs(t)-0.001*w );

                // displace, rotate and scale for next iteration
                q -= w*di;
                q  = vec2(-q.y,q.x);
                w *= kh-1.0; // should be w /= kh, but luckily 1/phi = phi-1
            }
            col *= smoothstep( 0.0, 1.5*px, d-0.001*sca );
        }

        // draw spiral (https://www.shadertoy.com/view/fslyWN)
        {
            p  /= k1;
            px /= k1;
            float ra = length(p);
            float an = atan(-p.x,p.y)/kt;
            float id = round( log2(ra)/k2 - an );
            if( id>-1.5 || (id>-2.5 && an>0.5-ft) )
            {
                float d = abs( ra - exp2(k2*(an+id)) );
                col = mix( col, vec3(1.0), smoothstep( 2.0*px, 0.0, d-0.005*sca ) );
            }
        }
        // accumulate
        tot += col;
    }
    // resolve
    tot /= float(kNumSamples);

    // vignetting
    tot *= 1.2-0.25*length(op);
    
    // remove color banding through dithering
    tot += (1.0/255.0)*ran;

    // output
    glFragColor = vec4(tot,1.0);
}
