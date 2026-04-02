#version 420

// original https://www.shadertoy.com/view/3sSGRh

#extension GL_EXT_gpu_shader4 : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 cossin(float a) { return vec2(cos(a), sin(a)); }
const int[] beyond = int[](
    0,    4064,    2336,    2336,    1728,
    0,    448,    672,    672,    288,
    0,    448,    32,        36,        504,
    0,    192,    288,    288,    192,
    0,    480,    256,    256,    224,
    0,    192,    288,    288,    4080,    16,
    0
);
float sdBox( in vec2 p, in vec2 b )
{
    vec2 d = abs(p)-b;
    return length(max(d,vec2(0))) + min(max(d.x,d.y),0.0);
}

vec2 rotate(vec2 uv, float a) {
    vec2 cs = cossin(a);
    return uv * mat2x2(cs.x, -cs.y, cs.y, cs.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 getColor(vec2 uv, int id) {
    switch(id%6) {
        case 0: break;
        case 1: uv.x = abs(uv.x); break;
        case 2: uv.y = abs(uv.y); break;
        case 3: uv   = abs(uv);   break;
        case 4: uv.x *= -1.0; break;
        case 5: uv.y *= -1.0; break;
    }
    switch(id%5) {
        case 0: return hsv2rgb(vec3(uv.y*.1-time, 1, 1));
        case 1: return hsv2rgb(vec3(uv.x*.1-time, 1, 1));
        case 2: return hsv2rgb(vec3(length(uv)*.1-time, 1, 1));
        case 3: return hsv2rgb(vec3(-time*.1616, 1, 1));
        case 4: return hsv2rgb(vec3((abs(uv.x)+abs(uv.y))*.1 - time, 1, 1));
    }
    return vec3(1,0,1);
}

float heart(vec2 pixel_uv) {
    pixel_uv.x = abs(pixel_uv.x); // left = right side.
    pixel_uv.y += 2.0; // shift picture down leds
    float arm_length = 5.0;
    float heart_diameter=3.0;
    float heart_thickness=1.0;
    // rotate 45 degrees so that y-axis is pointed up/right /
    pixel_uv = rotate(pixel_uv, 3.14159/4.0);
    float rect_dist = sdBox(pixel_uv, vec2(0.0,arm_length));
    float mask = abs(rect_dist-heart_diameter);
    return mask < heart_thickness ? 1.0 : 0.0;    
}

void main(void)
{
    
    float boolean_mask = 1.0;
    vec3 color = vec3(1.0);
    
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    
    uv*=20.0; // cells tall.
    uv.x += .5;
    
    vec2 pixel_uv = floor(uv);
    
    
    boolean_mask = heart(pixel_uv);
    
    
    pixel_uv = rotate(pixel_uv, -3.14159/4.0);
    int id = int(time);
    color = mix(
        getColor(floor(uv), id),
        getColor(floor(uv), id+1),smoothstep(0.0,1.0, fract(time)));
    
    vec2 subpixel_uv = fract(uv);
    float led = 1.0-length(subpixel_uv-.5)*2.0;
    glFragColor = vec4(1);
    glFragColor *= boolean_mask;
    glFragColor *= led*2.0;
    glFragColor.rgb *= color;
}
