#version 420

// original https://www.shadertoy.com/view/ltjcDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.14159

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float time = 8.0 * M_PI + 4.0 * sin( time * 9.0  + 7.0 * uv.x + 3.0 * uv.y );
    uv = abs( uv + vec2( -0.5, -0.5 ) );
    float r = cos( time * 1.0 * uv.x * 1.0 * M_PI );
    float t = cos( time * 1.0 * uv.y * 1.0 * M_PI );
    float p = clamp( r, 0.2, 0.7 );
    float q = clamp( t, 0.2, 0.7 );
    float r_color = max( p, q );
    float g_color =  step( 0.5, p );
    float b_color =  step( 0.5, q );
    
    glFragColor = vec4( r_color, g_color, b_color, 1.0 );
}
