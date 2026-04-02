#version 420

// original https://www.shadertoy.com/view/td2fDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/(resolution.xy);
    uv.y = gl_FragCoord.xy.y/(resolution.y / 10.0);
    uv.y = float(int(uv.y));
    uv.x = gl_FragCoord.xy.x/(resolution.x / 17.0);
    uv.x = float(int(uv.x));

    // Time varying pixel color
    vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));

    // Output to screen
    glFragColor = vec4(col,1.0);
}
