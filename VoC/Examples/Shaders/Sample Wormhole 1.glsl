#version 420

const float PI = 3.14159265358979323846264;
const float TWOPI = PI*2.0;

const vec4 WHITE = vec4(0.4, 0.4, 0.4, 1.0);
const vec4 BLACK = vec4(0.2, 0.2, 0.2, 1.0);
const vec2 CENTER = vec2(0.1, 0.5);

const int MAX_RINGS = 100;
const float RING_DISTANCE = 0.03;
const float WAVE_COUNT = 20.0;
const float WAVE_DEPTH = 0.02;

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
   vec2 position = gl_FragCoord.xy / resolution.xy;
    float rot = mod(time*0.9, TWOPI);
    float x = position.x;
    float y = position.y;

    bool black = false;
    float prevRingDist = RING_DISTANCE;
    for (int i = 0; i < MAX_RINGS; i++) {
        vec2 center = vec2(0.5, 1.2 - RING_DISTANCE * float(i)*1.3);
        float radius = 0.5 + RING_DISTANCE / (pow(float(i+6), 1.1)*0.004);
        float dist = distance(center, position);
        dist = pow(dist, 0.2);
        float ringDist = abs(dist-radius);
        if (ringDist < RING_DISTANCE*prevRingDist*5.0) {
            float angle = atan(y - center.y, x - center.x);
            float thickness = 0.2 * abs(dist - radius) / prevRingDist;
            float depthFactor = WAVE_DEPTH * tan((angle+rot*radius) * WAVE_COUNT);
            if (dist > radius) {
                black = (thickness < RING_DISTANCE * 1.0 + tan(-122.0)*depthFactor);
            }
            else {
                black = (thickness < RING_DISTANCE * 1.0 + sin(122.0)*depthFactor);
            }
            break;
        }
        if (dist > radius) break;
        prevRingDist = ringDist;
    }

    glFragColor = black ? BLACK : WHITE;
}
