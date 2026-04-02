#version 420

// original https://www.shadertoy.com/view/tdsBRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy)/resolution.xy;
    // Time varying pixel color
    vec2 col = (uv*10.0);
    for(float i = 1.0; i <6.0; i++){
        uv += col;
        col = cos(uv.yx*i+time);
    }
    // Output to screen
    glFragColor = vec4(col,1.0,1.0);
}
