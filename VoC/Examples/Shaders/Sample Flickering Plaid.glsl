#version 420

// original https://www.shadertoy.com/view/wslBRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy)/resolution.xy;
    // Time varying pixel color
    vec2 col = (uv.yx*10.0);
    for(float i = 1.0; i <5.0; i++){
        uv += col.yx;
        col.xy = cos(uv.yx*i+time);
    }
    // Output to screen
    glFragColor = vec4(col,1.0,1.0);
}
