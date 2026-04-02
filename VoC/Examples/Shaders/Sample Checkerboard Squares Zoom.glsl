#version 420

// original https://www.shadertoy.com/view/ltKSzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI     3.14159265358
#define TWO_PI 6.28318530718

void main(void)
{
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;  // center coordinates
    float time = time * 2.;                                           // adjust time
    float dist = length(uv) * 5.0;                                    // adjust distance from center
    float cellSizeAdjust = dist/2. + dist * sin(PI + time);           // adjust cell size from center
    float zoom = 4. * sin(time);                                      // oscillate zoom
    uv *= 7. + cellSizeAdjust + zoom;                                 // zoom out
    vec3 col = vec3(1. - fract(uv.y));                                // default fade to black
    if(floor(mod(uv.x, 2.)) == floor(mod(uv.y, 2.))) {                // make checkerboard when cell indices are both even or both odd
        col = vec3(fract(uv.x));                                      // use fract() to make the gradient along x & y
    }
    col = smoothstep(0.3,0.7, col);                                   // smooth out the color
    glFragColor = vec4(col,1.0);
}
