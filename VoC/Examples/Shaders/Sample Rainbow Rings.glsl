#version 420

// original https://www.shadertoy.com/view/NsK3Wz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)
#define LOOPLEN 4.

// adjusts the saturation
vec3 sat(vec3 rgb)
{
    // Algorithm from Chapter 16 of "OpenGL Shading Language"
    const vec3 W = vec3(0.2125, 0.7154, 0.0721);
    vec3 intensity = vec3(dot(rgb, W));
    return mix(intensity, rgb, 2.5); // adjust strength here
}

void main(void)
{
    // Make sure this loops
    float time = fract(time / LOOPLEN);
    // Simulate lower framerate
    time = floor(time * 20.) / 20. / LOOPLEN;
    // Normalized pixel coordinates
    vec2 uv = ( 2.* gl_FragCoord.xy - resolution.xy ) / length(resolution.xy);
    // use log distance for perspective/tunnel effect
    float dist = log(uv.x * uv.x + uv.y * uv.y);
    float angle = atan(uv.y, uv.x);
    
    vec3 chanTime = 0.01 * vec3(-1, 0, 1) + time;
    vec3 zoomTime = 1. * chanTime + 2.5 * sin(TAU * chanTime + dist * 0.5);
    
    vec3 col = smoothstep(-1.0, 1.0, sin(
        dist * 7. + zoomTime * TAU
    ));
    
    col += 0.3 * sin(dist * 4.5 + 3. * angle + (time + vec3(1, 0, 1) / 12.) * TAU);
    
    // Output to screen
    glFragColor = vec4(
        sat(col), 1.0
    );
}
