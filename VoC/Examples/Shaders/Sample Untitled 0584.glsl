#version 420

// original https://www.shadertoy.com/view/wdcBWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

vec3 palette(in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) {
    return a + b * cos(6.28318 * (c * t + d));
} 

void main(void) {
    float scale = 2.0;
    
    vec2 st = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y * scale;
    vec2 uv = vec2(atan(st.x, st.y), length(st));
    
    float t = time * 1.5;
    float circle = sdCircle(sin(uv.yy * 1.0 - t + cos(uv.yy - t + sin(uv * 6. - t + cos(uv.yx * 10. + t)))), 0.0);    

    vec3 a = vec3(0.5, 0.5, 0.5);        
    vec3 b = vec3(0.5, 0.5, 0.5);    
    vec3 c = vec3(2.0, 1.0, 0.0);    
    vec3 d = vec3(0.00, 0.10, 0.20);

    vec3 color = palette(circle, a, b, c, d);
    
    glFragColor = vec4(color, 1.0);
}
