#version 420

// original https://www.shadertoy.com/view/tl2XRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{

    vec2 position = ( gl_FragCoord.xy / resolution.xy );
    vec2 splines = vec2(pow(1.0-abs(position.y-cos(position.x*9.0+(time*0.912))/5.0-0.75),40.0),
                pow(1.0-abs(position.y+cos(position.x*7.0+(time*0.934))/3.0-0.45),50.0));
    
    splines += pow(splines.x+splines.y, 2.0);
    
    vec3 color = vec3(0.15 * splines.x * splines.y,
              0.15 * splines.x * splines.y,
              0.8 * splines.x * splines.y);
    
    
    glFragColor = vec4( color.r,color.g,color.b, 1.0 );
}
