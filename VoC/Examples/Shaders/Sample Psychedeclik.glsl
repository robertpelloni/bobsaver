#version 420

// original https://www.shadertoy.com/view/wdVyDV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x/resolution.y;
    vec3 color = vec3(0.0);
    float d = 0.0;

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(uv.xyx+vec3(1,2,4));
    
    uv = uv *10.-1.;

  // Make the distance field
    d = length( sin(uv)-.3 )+time*.3;
    
    col = col+d;

    // Output to screen
    glFragColor = vec4(vec3(fract(col*5.0)),1.0);
}
