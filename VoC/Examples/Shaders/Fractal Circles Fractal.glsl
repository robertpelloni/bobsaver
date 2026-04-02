#version 420

// original https://www.shadertoy.com/view/MtlGW8
 
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* Circles Fractal   *
 * By Célestin Marot */

// colored shape on black background if Iter is odd
// black shape on colored background if Iter is even
const int Iter=21;

float x;

void main(void)
{
    //((1,1) if x<0  | divergence if x>0.5)
    x=cos(0.5*time)*0.25+0.25;

    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy) / resolution.y;
    
    for (int i=0; i<Iter; i++)
             // = (∥uv∥*∥uv∥)/|uv| - x
            uv = abs(uv)/dot(uv,uv)-x;
    
    glFragColor = vec4(uv,uv.y-uv.x,1.0);
}
