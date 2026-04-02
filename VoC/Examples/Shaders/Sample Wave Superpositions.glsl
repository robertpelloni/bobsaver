#version 420

// original https://www.shadertoy.com/view/tslyDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define WAVE_SPEED -0.005
#define WAVE_FRONT_SPEED 0.3
#define WAVE_FREQUENCY 500.
#define WAVE_DELAY 0.41
#define WAVE_WIDTH 0.2
#define NUM_WAVES 7.
#define TWO_PI 6.2831853

vec3 gradient(in float t) {    
    vec3 a = vec3(.5, .5, .5);
    vec3 b = vec3(.5, .5, .5);
    vec3 c = vec3(1., 1., .5);
    vec3 d = vec3(.8, .9, .3);
    return a + b * cos(6.28318 * ( c * t + d));
}

float sineWave(in vec2 uv, in vec2 dir, float t) {
    float wave = 0.;
    if (abs(uv.x * dir.y - uv.y * dir.x) < WAVE_WIDTH) {
        float theta = -dot(dir, uv) + WAVE_DELAY;
        if (theta > WAVE_FRONT_SPEED * t) {
             theta = 0.;   
        } else {
             theta += WAVE_SPEED * t;   
        }
        wave = 0.5 - 0.5 * cos(WAVE_FREQUENCY * theta);   
    }
    return wave;
}

float elbow(float t) {
    if (t < 0.) {
        return 0.;
    }
    if (t > 1.) {
        return t - 0.5;
    }
    return .5 * (t * t);
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;
    uv *= 1. - 0.55 * smoothstep(7., 10., time);
    float waveProd = 1.;
    float waveSum = 0.;
    for (float i = 0.; i < NUM_WAVES; i += 1.) {
        vec2 dir = vec2(
            cos(TWO_PI * i / NUM_WAVES),
            sin(TWO_PI * i / NUM_WAVES));
        float wave = sineWave(uv, dir, elbow(time - i));
        waveProd *= (1. - wave);   
        waveSum += wave;
    }
    waveSum = 0.5 + 0.5 * tanh(0.3 * waveSum - 0.5);

    vec3 rgb = gradient(waveSum);
    
    glFragColor = vec4(rgb, 1.);
}
