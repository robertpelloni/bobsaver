#version 420

// original https://www.shadertoy.com/view/tllSDs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// by Nikos Papadopoulos, 4rknova / 2019
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI  3.14159265359

#define BG_COLOR  vec3(0.0745, 0.0862, 0.1058)
#define AMPLITUDE (0.1)
#define PERIOD    (11.) 
#define PHASE     (time * 10.)
#define DELTA     (PI)
#define DECAY     (6.)
#define SCALE     (1.1)
#define RING_MIN  (0.98)
#define RING_MAX  (1.00)

float ring(float r) 
{ 
    return step(r, RING_MAX) - step(r, RING_MIN); 
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    p.x *= resolution.x / resolution.y;

    // Polar Coordinates
    float r = SCALE * length(p);
    float theta = atan(p.y, p.x);

    // remap [0,1] to [0,1]->[1,0]
    float decay     = pow(abs(theta/PI),DECAY);
    float amplitude = AMPLITUDE * decay;
    float period    = theta * PERIOD + PHASE;

    float w0 = amplitude * cos(period)
        , w1 = amplitude * cos(period + DELTA);
 
    vec3 f = ring(r-w0) + ring(r-w1) + BG_COLOR;    
    glFragColor = vec4(vec3(f), 1);
}
