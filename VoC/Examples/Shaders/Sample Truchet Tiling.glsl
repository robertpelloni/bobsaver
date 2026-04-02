#version 420

// original https://www.shadertoy.com/view/WscGWN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash21(vec2 p)
{
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.24);
    return fract(p.x * p.y);
}

void main(void)
{
    const float PI = 3.14159;
    
    float scale = 8.0;
    
    vec2 staticuv = gl_FragCoord.xy/resolution.y;
    vec2 uv = staticuv + time / 10.0;
    vec2 celluv = fract(uv * scale);
    
       vec2 cellNum = floor(uv * scale);
       if (hash21(cellNum) > 0.5) celluv.y = 1.0 - celluv.y;
    
    if (celluv.y > 1.0 - celluv.x) celluv = 1.0 - celluv;
    
    float radius = 0.5;
    float thickness = sin(PI * staticuv.y) / 8.0;

    float dist = length(celluv);
    float minrad = radius - thickness;
    float maxrad = radius + thickness;
    
    float vertical = (dot(celluv, vec2(0, 2.0)) + 1.0) / 2.0;
    float horizontal = (dot(celluv, vec2(2.0, 0)) + 1.0) / 2.0;
    float opacity = dist < maxrad && dist > minrad ? 1.0 : 0.0;

    vec3 col = vec3(opacity, opacity, opacity);
    
    // if (celluv.x < 0.01 || celluv.y < 0.01) col = vec3(1.0, 0.0, 0.0);

    glFragColor = vec4(col, 1.0);
}
