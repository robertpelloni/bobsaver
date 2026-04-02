#version 420

// original https://www.shadertoy.com/view/MltyRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

vec3 color1 = vec3(0x44, 0x4B, 0xFF) / 255.0;
vec3 color2 = vec3(0x44, 0xAF, 0xFF) / 255.0;
vec3 color3 = vec3(0x03, 0xD1, 0xAB) / 255.0;

vec3 rgb2hsb( in vec3 c ){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0, 4.0, 2.0), 6.0)-3.0)-1.0, 0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

float heart(in vec2 pt, in float radius) {
    float x = pt.x / radius * 0.75;
    float y = pt.y / radius;
    float r = pow(x, 2.0) + pow(y+0.5 - sqrt(abs(x)), 2.0);
    return smoothstep(r-0.4, r+0.4, 2.0);
}

float heart2(in vec2 pt, in float radius) {
    float x = pt.x / radius * 0.75;
    float y = pt.y / radius;
    float r = pow(x, 2.0) + pow(y+0.5 - sqrt(abs(x)), 2.0);
    return smoothstep(r-0.4, r, 2.0) - smoothstep(r, r+0.4, 2.0);
}

mat2 rotate(in float angle) {
    return mat2(cos(angle), -sin(angle),
                sin(angle),  cos(angle));
}

mat2 scale(in float sx, in float sy) {
    return mat2(1.0 / sx, 0.0,
                0.0,      1.0 / sy);
}

void main(void) {
    
    vec2 pt = ( gl_FragCoord.xy - .5* resolution.xy) / resolution.y;
    
    float t = mod(time, 2.0);
    float sx = 1.0 + 0.4 * exp(-t*3.0) * cos(20.0*t);
    float sy = 1.0 + 0.4 * exp(-t*3.0) * sin(20.0*t);
    float hue = floor(time / 2.0) / 6.0;
    
    vec2 ptf = scale(sx, sy) * pt;
    
    float f = heart(ptf, 0.2);
    float g = heart2(pt, 0.18 + t);
    
    vec3 col = hsb2rgb(vec3(hue, 1.0, f))
        + hsb2rgb(vec3(hue, 0.5, g));

    // Output to screen
    glFragColor = vec4(col, 1.0);
}
