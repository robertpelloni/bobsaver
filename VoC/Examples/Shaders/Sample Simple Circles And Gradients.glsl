#version 420

// original https://www.shadertoy.com/view/llySW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 ratio;
    ratio.x = resolution.x / resolution.y;
    ratio.y = 1.0;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5; // center coordinates
    uv *= ratio;
    
    // calculate circles
    float distance1 = sin(length(uv - vec2(-cos(time * 5.0) * 0.05, -sin(time * 5.0) * 0.05)) * (30.0 + abs(sin(time) * 100.0)));
    float distance2 = sin(length(uv - vec2(+cos(time * 5.0) * 0.05, +sin(time * 5.0) * 0.05)) * 100.0);
    
    glFragColor.rgb = vec3(distance1 * distance2);
    glFragColor.a = 1.0;
    
    // calculate rotating color grading
    float angleRad = time;
    vec2 sc;
    sc.x = cos(angleRad);
    sc.y = sin(angleRad);
    mat2 m = mat2(sc.y, sc.x, -sc.x, sc.y); 
    
    uv = m * uv;
    vec4 color1 = vec4(1, 0.4, 0.0, 1);
    vec4 color2 = vec4(0.1, 0.8, 0.9, 1);
    glFragColor += mix(color1, color2, uv.y);
}
