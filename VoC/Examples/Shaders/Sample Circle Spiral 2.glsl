#version 420

// original https://www.shadertoy.com/view/WlKXDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float circle(float x, float y, float thres)
{
    float r_sq = x * x + y * y;
    return 0.5 - clamp((r_sq - thres) * 8.0, -0.5, 0.5);
}

float zigzag(float x)
{
    return abs(1. - mod(x, 2.0));
}

void main(void)
{
    const float PI = 3.14159265;
    const float rotSpeed = -5.;
    const float zoomSpeed = -3.;
    const float spiralSpeed = 3.;
    
    // Normalized pixel coordinates (from 0 to 1)
    float scale = min(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / scale;
    uv -= vec2(resolution.x / scale, resolution.y / scale) / 2.;
    uv *= 2.0;
    
    float distance = log(uv.x*uv.x+uv.y*uv.y) / 2.;
    float angle = atan(uv.y, uv.x) / PI;
    
    float spiral = 0.7 * zigzag(distance * 2.0 + angle * 4.0 + time * spiralSpeed) + 0.15;
    
    float distZag = zigzag(16.0 * distance + time * zoomSpeed);
    float angleZag = zigzag(48.0 * angle + time * rotSpeed);
    
    float circle = circle(distZag, angleZag, spiral);
    
    // Output to screen
    glFragColor = vec4(circle, circle, circle, 1);
}
