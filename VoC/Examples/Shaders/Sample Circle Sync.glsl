#version 420

// original https://www.shadertoy.com/view/WlK3Dw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float pi = 3.14159265359;

    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;

    float t = time*.4;
    uv*= 40.;
    
    // Time varying pixel color

    float dist = length(uv);
    
    int circid = int(floor(dist)) + 1;
    float circf = fract(dist);
    
    float off = 0.01;//sin(t*.001);
    //
    float ct_r = (t-off)*(float(circid))*.1;
    float col_r = ((fract(atan(uv.x, uv.y)/(2.*pi) + ct_r)) > .5) ? 1. : 0.;
    float ct_g = t*float(circid)*.1;
    float col_g = ((fract(atan(uv.x, uv.y)/(2.*pi) + ct_g)) > .5) ? 1. : 0.;
    float ct_b = (t+off)*(float(circid))*.1;
    float col_b = ((fract(atan(uv.x, uv.y)/(2.*pi) + ct_b)) > .5) ? 1. : 0.;
  
    // Output to screen
    glFragColor = vec4(col_r, col_g, col_b, 1.0);
}
