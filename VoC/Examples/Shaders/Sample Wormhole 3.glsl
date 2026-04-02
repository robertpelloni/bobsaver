#version 420

// original https://www.shadertoy.com/view/XlXGD4

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

// http://stackoverflow.com/questions/5451376/how-to-implement-this-tunnel-like-animation-in-webgl
// Converted to ShaderToy by Michael Pohoreski in 2015
// https://www.shadertoy.com/view/XlXGD4

const float PI = 3.14159265358979323846264;
const float TWOPI = PI*2.0;

const vec4 WHITE = vec4(1.0, 1.0, 1.0, 1.0);
const vec4 BLACK = vec4(0.0, 0.0, 0.0, 1.0);

const vec2 CENTER = vec2(0.0, 0.0);

const int   MAX_RINGS     = 30;
const float RING_DISTANCE = 0.05;
const float WAVE_COUNT    = 60.0;
const float WAVE_DEPTH    = 0.04;

uniform float uTime;
varying vec2 vPosition;

void main(void) 
{
//    vec2 vPosition = gl_FragCoord.xy;
    vec2 vPosition = -1.+2.*gl_FragCoord.xy/resolution.xy;
    
    float rot = mod(time*0.6, TWOPI);
    float x = vPosition.x;
    float y = vPosition.y;
    
    bool black = false;
    float prevRingDist = RING_DISTANCE;
    for (int i = 0; i < MAX_RINGS; i++) {
        vec2 center = vec2(0.0, 0.7 - RING_DISTANCE * float(i)*1.2);
        float radius = 0.5 + RING_DISTANCE / (pow(float(i+5), 1.1)*0.006);
        float dist = distance(center, vPosition);
        dist = pow(dist, 0.3);
        float ringDist = abs(dist-radius);
        if (ringDist < RING_DISTANCE*prevRingDist*7.0) {
            vec2 d = vPosition - center;
            float angle = atan( d.y, d.x );
            float thickness = 1.1 * abs(dist - radius) / prevRingDist;
            float depthFactor = WAVE_DEPTH * sin((angle+rot*radius) * WAVE_COUNT);
            if (dist > radius) {
                black = (thickness < RING_DISTANCE * 5.0 - depthFactor * 2.0);
            }
            else {
                black = (thickness < RING_DISTANCE * 5.0 + depthFactor);
            }
            break;
        }
        if (dist > radius) break;
        prevRingDist = ringDist;
    }
    
    glFragColor = black ? BLACK : WHITE;
}
