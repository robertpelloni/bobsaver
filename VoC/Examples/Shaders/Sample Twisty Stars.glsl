#version 420

// original https://www.shadertoy.com/view/3djBzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265;
const float PI_2 = PI / 2.;

float fold(float x) {
    return abs(mod(x, 2.0) - 1.0);
}

float foldPlus(float x) {
    return log(1.0 + fold(x));
}

float smoothThres(float x, float strength) {
    return smoothstep(0.5 - strength, 0.5 + strength, x);
}

float smoothFold(float x, float strength) {
    return smoothThres(fold(x), strength);
}

vec3 colMap(float x, vec3 a, vec3 b) {
    return a * (1.0 - x) + b * x;
}

void main(void)
{
    float t = fract(time * 64. / 60.);
    
    // Normalized pixel coordinates
    float scale = min(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / scale;
    uv -= resolution.xy / scale / 2.;
    uv *= 2.;
    float dist = log(uv.x*uv.x+uv.y*uv.y); // not real distance, but useful for log spirals
    float angle = atan(uv.y, uv.x) / PI;
    
    //angle -= t * 1. / 5.;
    
    float twistiness = 0.5 * (fold(t * 2.) - 0.5);
    twistiness += cos(t * 2. * PI) * 0.2;
    
    float value = foldPlus(angle * 5. + (dist - 1.) * twistiness);
    
    value = smoothFold(value * 1.5 + dist * 1. + t * 02.0, 0.05);
    
    vec3 colA0 = vec3(1.0, 0.3, 0.8);
    vec3 colA1 = vec3(0.0, 0.1, 0.7);
    vec3 colB0 = vec3(0.6, 0.2, 0.0);
    vec3 colB1 = vec3(0.0, 0.8, 1.0);
    vec3 colA = colMap(value, colA0, colA1);
    vec3 colB = colMap(value, colB0, colB1);
    
    vec3 col = colMap(smoothFold((angle * 5. + 0.5) + (dist - 1.) * twistiness, 0.02),
                     colA, colB);
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
