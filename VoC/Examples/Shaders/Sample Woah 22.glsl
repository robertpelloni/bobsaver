#version 420

// original https://www.shadertoy.com/view/ltffDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Damn your eyes
// @P_Malin

// Epilepsy warning or something

// Not sure how I arrived at this but I guess I saw something similar somewhere 
// probably a Vasarely painting as Fabrice suggests.

void main(void)
{
    vec2 p = gl_FragCoord.xy;
    vec2 uv = (p.xy / resolution.xy) * 2. - 1.;
    uv.x *= resolution.x / resolution.y;
    float r = max( 0.,  1. - length(uv) );
    float t = time * 2.0;
    t = r * r * sin(r+t) * 3.0;    
    uv *= mat2( cos(t), -sin(t), sin(t), cos(t) );
    glFragColor = vec4( sin( uv.x * 150. ) * 0.5 + 0.5 );
}
