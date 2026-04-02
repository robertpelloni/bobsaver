#version 420

// original https://www.shadertoy.com/view/mtdczX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define I resolution

void main(void)
{
    vec4 U=vec4(0.0);
    vec2 V = gl_FragCoord.xy;
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 u = ( V * 2. - I.xy ) / I.y;

    // Time varying pixel color
    float p = .1, i=0;
    
    U = vec4(0);
    
    while( i++<40. )
        p = min(
            p,
            fract( length(u - vec2( cos( i + time ), sin( i + time ) ) ) - time * .5 )
        ),
        U.rgb += smoothstep( 1e-2, 1e-3, p );
        
    // Output to screen
    glFragColor = U;
    
}