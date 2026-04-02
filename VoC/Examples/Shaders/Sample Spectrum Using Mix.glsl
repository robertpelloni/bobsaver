#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wt3yW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (3.14159265358979 * 2.)

// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
uint hash( uint x ) {
    x += ( x << 10u );
    x ^= ( x >>  6u );
    x += ( x <<  3u );
    x ^= ( x >> 11u );
    x += ( x << 15u );
    return x;
}

float random(uint seed) {
    return uintBitsToFloat(0x007FFFFFu & hash(seed) | 0x3F800000u) - 1.;
} 

vec3 spectrum(float x) {
    x = mod(x, 3.);
    return mix(
       mix(vec3(1, 1, 0), vec3(0, 1, 1), x),
       mix(vec3(1, 0, 1), vec3(1, 1, 0), x-2.),
       x-1.
    );
}

float odd(int x) {
    return float(x & 1) * 2. - 1.;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    float scale = length(resolution);
    vec2 uv = gl_FragCoord.xy / scale;
    uv -= (resolution.xy / scale) / 2.;
    uv *= 2.0;
    
    float distSq = uv.x*uv.x+uv.y*uv.y;
    float angle = atan(uv.x, uv.y);
    int ring = int(time + log(distSq) * 0.6);
    float rand = random(uint(ring)) - 0.5;
    float angleAdd = (time * rand);
    
    vec3 col = spectrum(
        angleAdd + angle / TAU * 3. * odd(ring)
    );
    // Output to screen
    glFragColor = vec4(col,1.0);
}
