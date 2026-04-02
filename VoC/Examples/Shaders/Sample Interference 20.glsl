#version 420

// original https://www.shadertoy.com/view/3tlfW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.28318530718
#define COUNT_RADIUS 5

vec4 colorSin(float value) {
    vec4 preNormal =  vec4(
        sin(value),
        sin(value - TAU/3.0),
        sin(value - 2.0 * TAU/3.0),
        1.0
    );
    
    return 2.0 * preNormal - 1.0;
}

float sinSource(vec2 origin, float frequency, float phase, vec2 point) {
    float t = distance(origin, point);

    return sin(TAU * (frequency * t - phase) - time*5.0);
}

void main(void) {
    vec2 xy = 2.0 * gl_FragCoord.xy - resolution.xy;
    float sum = 0.0;

    for (int i = -COUNT_RADIUS; i < COUNT_RADIUS; ++i) {
        sum += sinSource(vec2(100*i, 0.0), 0.02, sin(time / 5.0), xy);
    }

    
    for (int i = -COUNT_RADIUS; i < COUNT_RADIUS; ++i) {
        sum += sinSource(vec2(0.0, 100*i), 0.02, cos(time / 5.0), xy);
    }
    
    float envelope = 1.0 / (1.0 + exp(pow(length(xy) / 300.0, 2.0)));

    glFragColor = colorSin(envelope * sum);
    glFragColor = vec4(vec3(sum / 6.0), 1.0) + 0.1 * glFragColor;
}
