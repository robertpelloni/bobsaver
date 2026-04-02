#version 420

// original https://www.shadertoy.com/view/lt3SRH

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform sampler2D backbuffer;

out vec4 glFragColor;

// based on <https://git.io/vz29Q>
// Copied from davidar's Smooth Life Gliders (https://www.shadertoy.com/view/Msy3RD)
//
// ---------------------------------------------
// SmoothLife (discrete time stepping 2D)
struct SmoothLifeParameters {
    float ra;       // outer radius
    float rr;       // ratio of radii
    float b;        // smoothing border width
    float b1;       // birth1
    float b2;       // birth2
    float d1;       // survival1
    float d2;       // survival2
    float sn;       // sigmoid width for outer fullness
    float sm;       // sigmoid width for inner fullness
    float dt;       // dt per frame
};

// SmoothLifeL
const SmoothLifeParameters p = SmoothLifeParameters(12.0,
                                                    3.0,
                                                    1.0,
                                                    0.305,
                                                    0.443,
                                                    0.556,
                                                    0.814,
                                                    0.028,
                                                    0.147,
                                                    .089);
    
float smooth_s(float x, float a, float ea) 
{ 
    return 1.0 / (1.0 + exp((a - x) * 4.0 / ea));
}

float sigmoid_ab(float x, float a, float b)
{
    return smooth_s(x, a, p.sn) * (1.0 - smooth_s(x, b, p.sn));
}

float sigmoid_mix(float x, float y, float m)
{
    float sigmoidM = smooth_s(m, 0.5, p.sm);
    return mix(x, y, sigmoidM);
}

// the transition function
// (n = outer fullness, m = inner fullness)
float snm(float n, float m)
{
    return sigmoid_mix(sigmoid_ab(n, p.b1, p.b2), sigmoid_ab(n, p.d1, p.d2), m);
}

float ramp_step(float x, float a, float ea)
{
    return clamp((a - x) / ea + 0.5, 0.0, 1.0);
}

// 1 out, 3 in... <https://www.shadertoy.com/view/4djSRW>
#define MOD3 vec3(.1031,.11369,.13787)
float hash13(vec3 p3) {
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract((p3.x + p3.y)*p3.z);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    // inner radius:
    const float rb = p.ra / p.rr;
    // area of annulus:
    const float PI = 3.14159265358979;
    const float AREA_OUTER = PI * (p.ra*p.ra - rb*rb);
    const float AREA_INNER = PI * rb * rb;
    
    // how full are the annulus and inner disk?
    float outf = 0.0, inf = 0.0;
    for (float dx = -p.ra; dx <= p.ra; dx++) {
        for (float dy = -p.ra; dy <= p.ra; dy++) {
            vec2 d = vec2(dx, dy);
            float r = length(d);
            vec2 txy = fract((gl_FragCoord.xy + d) / resolution.xy);
            float val = texture2D(backbuffer, txy).x;
            float inner_kernel = ramp_step(r, rb, p.b);
            float outer_kernel = ramp_step(r, p.ra, p.b) * (1.0 - inner_kernel);
            inf  += val * inner_kernel;
            outf += val * outer_kernel;
        }
    }
    outf /= AREA_OUTER; // normalize by area
    inf /= AREA_INNER; // normalize by area
    
    float s = texture2D(backbuffer, uv).x;
    float deriv = 2.0 * snm(outf, inf) - 1.0;
    s = clamp(s + (deriv * p.dt), 0.0, 1.0);  // Apply delta to state
    if (frames < 10) {
        s = hash13(vec3(gl_FragCoord.xy,frames)) * 0.65;
    }
    glFragColor = vec4(s, s, s, 1);
}
