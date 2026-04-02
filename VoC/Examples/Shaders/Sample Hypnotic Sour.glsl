#version 420

// original https://www.shadertoy.com/view/mdXSW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 5.415926535897932384 // yeah changing pi can be fun o.O
#define NUM_BLADES 10.0
#define TWIST_AMOUNT 3.5

// orto
vec2 orto(vec2 a) {
    return vec2(a.x + a.y, - a.x + a.y);
}

float atan_n(vec2 uv) {
    return (atan(uv.y, uv.x) + PI)/(2.0*PI);
}

float sin_n(float x) {
    return 0.5*(1.0 + sin(2.0*PI*x));
}

float cos_n(float x) {
    return 0.5*(1.0 + cos(2.0*PI*x));
}

vec2 rotate(vec2 v, float a) {
    float c = cos(a);
    float s = sin(a);
    return vec2(v.x*c + v.y*s, -v.x*s + v.y*c);
}

void main(void) {

    float N = NUM_BLADES;
    float rm = TWIST_AMOUNT;

    vec2 uv = (resolution.xy - 2.0*gl_FragCoord.xy)/resolution.y;
   
    uv *= 2.0;
    
    float t = time;
    float r = length(uv);
    
    uv = rotate(uv, (r - 2.0)*rm*sin(t));
    
    float fan = N*atan_n(uv);
    float fan_mod = mod(fan, 1.0);
    float woo = 2.0*abs(fan_mod - 0.5);
    
    float shade = woo*(0.8*r*r*(2.0 - r));
    
    glFragColor = shade*vec4(sin_n(fan), cos_n(fan), sin_n(fan), 1.0);
}
