#version 420

// original https://www.shadertoy.com/view/wdGBzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Psychedelic Hypnoze by Seb.
// Just maths and colors (unoptimized)

const vec3 palette[23] = vec3[23]( vec3(0.66, 1.00, 0.95), vec3(0.70, 0.99, 0.85), vec3(0.74, 0.98, 0.75), vec3(0.79, 0.99, 0.68), vec3(0.80, 0.97, 0.62), vec3(0.88, 0.97, 0.64), vec3(0.96, 0.97, 0.66), vec3(0.98, 0.91, 0.66), vec3(0.96, 0.83, 0.62), vec3(0.98, 0.79, 0.62), vec3(1.00, 0.66, 0.70), vec3(0.97, 0.67, 0.69), vec3(0.96, 0.60, 0.78), vec3(0.92, 0.61, 0.81), vec3(0.91, 0.60, 0.91), vec3(0.87, 0.59, 0.98), vec3(0.81, 0.61, 0.97), vec3(0.74, 0.64, 0.97), vec3(0.68, 0.67, 0.98), vec3(0.61, 0.69, 0.97), vec3(0.63, 0.73, 0.97), vec3(0.61, 0.81, 0.98), vec3(0.62, 0.89, 1.0) );

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy;
    vec3 col = vec3( 0.63, 0.97, 1.0 );      
   
    for( int n = 22; n > -1; n--)
    {
        for( int m = 0; m < 2; m++)
        {
            float o = float(n) * 0.1;
            vec2 pos = vec2( cos( time * 1.8 - o ), cos( time * 1.4 - o ) );
            float rr = 1.0 + 0.2 * sin( time * 2.66 - o * 2.0 );  

            vec2 q= p + vec2( -0.5, -0.5 ) + vec2( -0.0045, 0.0045 ) * ( 1.0 - float(m) );
            q.x *= resolution.x / resolution.y;
            float t = 0.5 * ( time * 0.5 + cos( time * 1.84 - o * 2.34 ) - sin( time * 1.46 - o * 3.46) + 2.0 * cos( time * 0.58 - o * 2.64 ) );
            q *= ( 0.8 + 0.2 * cos( atan( q.y,q.x ) * ( o * 10.0 + 4.0 ) + t * 6.0 * ( o * 2.0 + 1.0 ) ) ) * rr * 9.37 / ( o * 26.0 + 2.0 );
            col.xyz = mix( palette[ n ] * ( m < 1 ? 0.8 : 1.0 ), col, smoothstep( 0.25, 0.25 + 0.0001 * ( m < 1 ? 10.0 : 1.0 ), length( ( q + pos * 0.1 ) ) ));                        
        }
    }
    glFragColor = vec4(col,1.0);
}
