#version 420

// original https://www.shadertoy.com/view/XlSfWW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SQ_LENGTH 50.0
#define PI 3.1415926535897932384626433832795
#define BLUR 1.0 // 1.0 is good for antialiasing

const float period = 60.0 / 120.0;
const vec4 white = vec4(1.0);
const vec4 black = vec4(vec3(0.0), 1.0);

float theta() {
    return mod(time, period) / period;
}

float ease(float x) {
    return x;//pow(x, 3.0);
}

vec4 rect(vec2 p, float padding) {
    float horizontal =
        smoothstep(padding - BLUR, padding + BLUR, p.x) -
        smoothstep(SQ_LENGTH - padding - BLUR, SQ_LENGTH - padding + BLUR, p.x);
    float vertical =
        smoothstep(padding - BLUR, padding + BLUR, p.y) -
        smoothstep(SQ_LENGTH - padding - BLUR, SQ_LENGTH - padding + BLUR, p.y);
    
    return vec4(vec3(horizontal * vertical), 1.0);
    
}

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    if (mod(u.x, 2. * SQ_LENGTH) > SQ_LENGTH) {
        u.y += SQ_LENGTH / 2.;
    }
    
    float paddingMultiplier = ceil(u.x / SQ_LENGTH) / SQ_LENGTH;
    paddingMultiplier *= ceil(u.y / SQ_LENGTH) / SQ_LENGTH;
    float padding = paddingMultiplier + 1.0;
    padding *= PI;
    
    padding = 0.5 + 0.5 * sin(padding * 15.0 + 1.5 * time);
    padding = ease(padding);
    padding = 5. + 15. * padding;
    
    vec2 p = mod(u, SQ_LENGTH);
    
    glFragColor = rect(p, padding);
}
