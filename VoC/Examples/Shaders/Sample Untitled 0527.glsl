#version 420

// original https://www.shadertoy.com/view/WlGSWK

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

float distCustom(float x, float y)
{
    float n = -0.5 * abs(x) + y;
    return log(
        x * x + 1.5 * n * n
    );
}

float fn(float x)
{
    return max(0.0, (sin(x) + 0.3) * 0.8);
}

void main(void)
{
    const float PI = 3.14159265;
    const float PI_3 = PI / 3.;
    const vec3 color0 = vec3(0.4, 0.1, 0.1);
    const vec3 color1 = vec3(0.9, 0.3, 0.4);
    const vec3 color2 = vec3(0.8, 0.5, 1.0);
    const vec3 color3 = vec3(0.1, 0.2, 0.2);
    const float speed = 5.;
    const float rotSpeed = -1.0;
    const float zoomSpeed = -4.;
    const float gridSize = 72.0 / PI;
    
    // Normalized pixel coordinates (from 0 to 1)
    float scale = min(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / scale;
    uv -= vec2(resolution.x / scale, resolution.y / scale) / 2.;
    
    float distance = log(uv.x*uv.x+uv.y*uv.y) / 2.;
    float distC = distCustom(uv.x, uv.y);
    float angle = atan(uv.y, uv.x);
    
    // Time varying pixel color
    float c1 = fn(distC * 3.5 + angle + time * speed + PI);
    float c2 = fn(distC * 4.5 - angle + time * speed * -1.5 + PI);
    
    float distZag = zigzag(gridSize * distance + time * zoomSpeed);
    float angleZag = zigzag(gridSize * angle + time * rotSpeed);
    
    float c3 = circle(distZag, angleZag, 0.5);

    // Output to screen
    glFragColor = vec4(
        color0[0] + c1 * color1[0] + c2 * color2[0] + c3 * color3[0],
        color0[1] + c1 * color1[1] + c2 * color2[1] + c3 * color3[1],
        color0[2] + c1 * color1[2] + c2 * color2[2] + c3 * color3[2],
        1
    );
}
