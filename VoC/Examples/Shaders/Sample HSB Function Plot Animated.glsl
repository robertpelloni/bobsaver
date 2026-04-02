#version 420

// original https://www.shadertoy.com/view/3tjyDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float tileSize = 1000.0;
float scale = 20.0;
float rangeEnd = 1.0;
float rangeStart = -1.0;

//some nice functions to try
//sin(x) * ((sin(y) + cos(x)) * sin(y) + cos(x)) * cos(y)
//sin(cos(x) * sin(y) * x) * cos(sin(y) * cos(x) * y)
//sin(cos(x) * sin(y) * 2.0 * sin(x * 0.2)) * cos(sin(y) * cos(x) * 2.0 * sin(y * 0.2))
//sin(cos(time * 0.5 + x) * sin(time * 0.2 + y) * 2.0 * sin(x * 0.5) + cos(x * 0.25) * 0.3) * cos(sin(y) * cos(time - x) * 2.0 * sin(time * 0.3 + y * 0.2) + 2.0)

//hsv2rgb is from https://gist.github.com/yiwenl/745bfea7f04c456e0101
vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.y;

    // Time varying pixel color
    //vec3 col = 0.5 + 0.5*cos(time+uv.xyx+vec3(0,2,4));
    
    float x = mod(uv.x, tileSize) * scale;
    float y = mod(uv.y, tileSize) * scale;
    
    //=== put the function to plot here ===
    float value = sin(cos(time * 0.5 + x) * sin(time * 0.2 + y) * 2.0 * sin(x * 0.5) + cos(x * 0.25) * 0.3)
        * cos(sin(y) * cos(time - x) * 2.0 * sin(time * 0.3 + y * 0.2) + 2.0) + time * 0.03;
    
    value = (value - rangeStart) / (rangeEnd - rangeStart);
    vec3 col = hsv2rgb(vec3(value, 1.0, 1.0));

    // Output to screen
    glFragColor = vec4(col,1);
}
