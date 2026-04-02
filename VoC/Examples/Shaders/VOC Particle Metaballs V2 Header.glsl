#version 420

// original https://www.shadertoy.com/view/3lycWd

// SLOWER than the V1 metaball shader!!
// To see how this could be implemented/tested see _ParticleLife unit

uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//simplified by iq
float smin(float a, float b, float k, float p, out float t)
{
    float h = max(k - abs(a-b), 0.0)/k;
    float m = 0.5 * pow(h, p);
    t = (a < b) ? m : m-1.0;
    return min(a, b) - (m*k/p);
}
#define smix(a, b, t) mix(a, b, abs(t))

void main(void)
{
    vec4 O = gl_FragColor;
    vec2 pos = gl_FragCoord.xy;

