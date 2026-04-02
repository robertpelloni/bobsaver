#version 420

// original https://www.shadertoy.com/view/WsGBRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Waves of information" by CoolerZ. https://shadertoy.com/view/Wd3Bz8
// 2020-11-29 03:26:02

#define STEP .25
#define XLIM 1.
#define YLIM 1.
#define SPEED (10.0f)

#define PI (3.14159265358979323846)
#define sq(a) (a*a)

float cherenkov_radiation(out float b, in float h, in float dt)
{
    const float c = 299792458.0f;  // universal constant for speed of light in a vacuum (m/s)
    const float n = 1.33f; // refraction index of water
    const float e = 10e5f; // total energy emitted
    const float q = 24e3f; // energy in a particle
    
    // n = refraction index of medium
    // c/n < v < c  : speed of particle is greater than speed of light
    //                  in the medium, but still less than the speed of light in a vacuum
    // B = v/c        : speed of particle in medium / speed of light
    // cos = 1/(nB) : angle of emission
    
    // (modified) frank-tamm formula
    // sq(d) * e      sq(q)                sq(c)
    // ---------  =  -------  *  1 -  --------------- 
    //     d           4pi             sq(v) * sq(n)
    
    //                sq(q) * (sq(n)*sq(v) - sq(c))
    //     d       = -------------------------------
    //                  4 * e * pi * sq(n) * sq(v)
    
    float v = c/n;
    v += (h) * v * dt;
    v = min(v, c);
    
    b = (1.0f / (n * (v / c)));
    
    float d;
    d = sq(q) * (sq(n)*sq(v) - sq(c));
    d /= 4.0f * e * PI * sq(n) * sq(v);
    
    return (d);
}

float circ(vec2 p) {
    const float r = .1;
    return length(p)-r;
}

float linearstep(float edge0, float edge1, float x)
{
    return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

float oracle(vec2 p, float t) {
    float dist = circ(p+vec2(cos(t),sin(t)));
    return linearstep(1.0, 0.0, dist);
}

float electricfield(vec2 p, float t) {
    float velocity = length(p) * time;
    float acc = 0.;
    float count = 0.;
    for(float y = -YLIM; y <= YLIM; y+=STEP) {
        for(float x = -XLIM; x <= XLIM; x+=STEP) {
            vec2 q = vec2(x, y);
            float d = length(p - q);
            
            float angle;
            float rad = cherenkov_radiation(angle, d, STEP);
            
            float delay = rad/velocity;
            acc += oracle(q, t+delay)/angle;
            ++count;
        }
    }
    return acc/count;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    float background = electricfield(uv, time*SPEED);

    vec3 col = vec3(background * 2.0f);
    glFragColor = vec4(col,1.0);
}
