#version 420

// original https://www.shadertoy.com/view/tldBzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// References:
// https://www.shadertoy.com/view/ltB3WW 
// https://www.shadertoy.com/view/3lSXz1
#define ITER 25
#define DEGREE 2
#define ANTI_ALIASING 2

#define VARY_A

vec2 complex_inv(in vec2 a) {
    return vec2(a.x, -a.y) / dot(a, a);
}

vec2 complex_mul(in vec2 a, in vec2 b) {
    return vec2(a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x);
}

vec2 complex_div(in vec2 a, in vec2 b) {
    return complex_mul(a, complex_inv(b));
}

vec3 newton_fractal(in vec2 z, in vec2 a) {
    for (int i = 0; i < ITER; i++) {
        vec2 z2 = complex_mul(z, z);
        vec2 z4 = complex_mul(z2, z2);
        vec2 z3 = complex_mul(z2, z);
        vec2 z5 = complex_mul(z4, z);
        
        // z^3 - 1
        #if DEGREE==2
        z -= complex_mul(a, complex_div(z3 - 1.0, 3.0 * z2));
        #endif
    } 
  
    vec2 z2 = complex_mul(z, z);
    vec2 z3 = complex_mul(z, z2);
    #if DEGREE==2
    vec2 remainder = z3 - 1.0;
    float remainder_magnitude = sqrt(dot(remainder, remainder));
    #endif
    return vec3(z.x, z.y, -z.y) * exp(-remainder_magnitude);
}

void main(void) {
    // Normalized pixel coordinates (from -1 to 1)
    vec2 uv = -1.0 + 2.0 * gl_FragCoord.xy/resolution.xy;
    uv.x *= resolution.x / resolution.y;
    
    float theta = time / 2.0;
    uv = vec2(uv.x * cos(theta) - uv.y * sin(theta), uv.x * sin(theta) + uv.y * cos(theta));
    
    vec2 aa_step = vec2(1.0 / float(ANTI_ALIASING), 1.0 / float(ANTI_ALIASING)) / resolution.xy;
    // aa_step.x *= resolution.x / resolution.y;
    // vec2 aa_step = vec2(0.01, 0.01) / resolution.xy;
    
    vec3 color = vec3(0);
    
    #ifdef VARY_A
    vec2 a = vec2(1.25 * sin(time) + 1.25, 0);
    #else
    vec2 a = vec2(1, 0);
    #endif
    
    for (int x = -ANTI_ALIASING + 1; x < ANTI_ALIASING; ++x) {
        for (int y = -ANTI_ALIASING + 1; y < ANTI_ALIASING; ++y) {
            color += newton_fractal(uv + aa_step * vec2(x, y), a);
        }
    }
    int sqrt_samples = ANTI_ALIASING * 2 - 1;
    glFragColor = vec4(color / float(sqrt_samples * sqrt_samples), 1.0);
}
