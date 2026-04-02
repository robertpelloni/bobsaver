#version 420

// original https://www.shadertoy.com/view/wdlczn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ============== PARAMS ==============
float _Thickness = 8.0; // In pixels   
float _Hardness = 1.0;
float _Scale = 2.0;
// ====================================

float circle(vec2 center, float radius, vec2 point) {
    return length(point - center) - radius;   
}

float segment(vec2 start, vec2 end, vec2 point) {
    vec2 offset = point - start;
    vec2 seg = end - start;
    float t = clamp(dot(offset, seg) / dot(seg, seg), 0.0, 1.0);
    return length(offset - seg * t);
}

vec3 paint(vec3 col, vec3 paintColor, float dist) {
    return col = mix(col, paintColor, 1.0 - pow(smoothstep(0.0, _Thickness / resolution.y, dist), _Hardness));
}

void main(void)
{

    // Pixel coordinates mapped to [-aspectRatio, aspectRatio] x [-1, 1]
    vec2 uv = 2.0 * gl_FragCoord.xy / resolution.y - vec2(resolution.x / resolution.y, 1.0);
    uv *= _Scale;    
    vec2 point = vec2(cos(time), sin(time));
    
    
    // Background color
    vec3 col = vec3(1.0);
    
    // Grid
    col = paint(col, vec3(0.7), abs(fract(uv.x + 0.5) - 0.5));
    col = paint(col, vec3(0.7), abs(fract(uv.y + 0.5) - 0.5));
    
    // Axes
    col = paint(col, vec3(0.3), abs(uv.x));
    col = paint(col, vec3(0.3), abs(uv.y));
    
    // Radius
    col = paint(col, vec3(0.1), segment(vec2(0.0), point, uv));
    
    // Sin cos
    col = paint(col, vec3(0.5, 0.5, 0.8), segment(vec2(point.x, 0.0), point, uv));
    col = paint(col, vec3(0.8, 0.5, 0.5), segment(vec2(0.0, point.y), point, uv));
   
    col = paint(col, vec3(0.6, 0.0, 0.0), segment(vec2(point.x, 0.0), vec2(0.0), uv));
    col = paint(col, vec3(0.0, 0.0, 0.6), segment(vec2(0.0, point.y), vec2(0.0), uv));
    
    // Unity Circle
    float c = circle(vec2(0.0, 0.0), 1.0, uv);
    col = paint(col, vec3(0.0), abs(c));
    
    // Moving Point
    c = circle(point, 0.1, uv);
    col = paint(col, vec3(0.2, 0.6, 0.2), c);
    
    glFragColor = vec4(col, 1.0);
}
