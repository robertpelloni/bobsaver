#version 420

// original https://www.shadertoy.com/view/tdSGW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution.xy
#define Iterations 20.
mat2 r2(float angle) { return mat2(cos(angle), -sin(angle), sin(angle), cos(angle)); }

float sdCircle(vec2 p, float r) {
    return length(p) - r;    
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ) {
    return a + b*cos(6.28318 * (c*t + d));
}

vec2 T(vec2 p) {

    float s = 0.0006 + 0.0005 * cos(time/2.);
    for(float i=0.; i < Iterations; i++) {
        p = abs(p) - s - i/Iterations; 
        p *= r2(time / 4.);
        p *= (i/Iterations*.4 + 1.);
    }
    
    return p;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.*gl_FragCoord.xy-R)/R.y;

    // Time varying pixel color
    vec3 col = pal(fract(0.3*sdCircle(T(uv), 0.5) + time / 7.), vec3(.5), vec3(0.5), 
                   vec3(1.0,1.0,1.0), vec3(.0, .10, .2));
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
