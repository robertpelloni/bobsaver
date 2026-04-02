#version 420

// original https://www.shadertoy.com/view/XtBcDD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M_PI 3.14159

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    float phase = 8.0 * M_PI + 4.0 * sin( time * 9.0  + 7.0 * uv.x + 3.0 * uv.y );
    uv = abs( uv + vec2( -0.5, -0.5 ) );
    float p = cos( phase * 1.0 * uv.x * 1.0 * M_PI );
    float q = cos( phase * 1.0 * uv.y * 1.0 * M_PI );
    float color_phase = 1.8 * sin( phase * 0.1 ) * sin( phase * 0.1 );//mod( phase, 2.2 );
    float r_color = max( p, q ) * color_phase * 0.7;
    float g_color =  max( p, q ) * color_phase * 0.7;//step( 0.5, p );
    float b_color =  color_phase;
    
    
    glFragColor = vec4( r_color, g_color, b_color, 1.0 );
}
