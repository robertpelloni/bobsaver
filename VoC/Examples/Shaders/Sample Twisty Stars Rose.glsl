#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wsBBz3

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
    return log(0.5 + fold(x));
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

vec3 hue(float x) {
    return (vec3(
        sin(x),
        sin(x + 2. * PI / 3.),
        sin(x + 4. * PI / 3.)
    ) + 1.0) * 0.6;
}

float star(float angle, float d, float roundness) {
    return foldPlus(angle * 10.) + d * roundness;
}

void main(void)
{
    float t = fract(time / 8.);
    
    // Normalized pixel coordinates
    float scale = min(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / scale;
    uv -= resolution.xy / scale / 2.;
    uv *= 2.;
    float dist = log(uv.x*uv.x+uv.y*uv.y); // not real distance, but useful for log spirals
    float angle = atan(uv.x, uv.y) / PI / 2.;
    float angleLayer = t / 5.;
    float offsetLayer = t * 3.;
    float spaceLayer = 0.5;
    vec3 colA = vec3(1.0, 0.3, 0.8);
    vec3 colB = vec3(0.3, 0.7, 1.0);
    vec3 colC = hue(t * 2. * PI);
    vec3 col = vec3(fold(t * 16.));
    
    if (dist >= -8.) {
        for (float iRing = 0.; iRing < 25.; iRing += 1.) {
            if (star(angle - (iRing * angleLayer), dist, 1.1) < spaceLayer * (iRing - offsetLayer) - 7.){
                switch (int(iRing) % 3) {
                    case 0:
                        col = colA;
                        break;
                    case 1:
                        col = colB;
                        break;
                    case 2:
                        col = colC;
                }
                break;
            }
        }
    }
    
    // Output to screen
    glFragColor = vec4(col, 1.0);
}
