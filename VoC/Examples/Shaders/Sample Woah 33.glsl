#version 420

// original https://www.shadertoy.com/view/sdGGRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float smootherstep(float edge0, float edge1, float x) {
  // Scale, and clamp x to 0..1 range
  x = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  // Evaluate polynomial
  return x * x * x * (x * (x * 6. - 15.) + 10.);
}

float softsquare(float x) {
    float x2 = abs(2. * fract(x) - 1.);
    return smoothstep(0.1, 0.9, x2);
}

vec3 gradient(float r) {
    float mix0 = smoothstep(0.00, 0.25, r);
    float mix1 = smoothstep(0.25, 0.50, r);
    float mix2 = smoothstep(0.50, 0.75, r);
    float mix3 = smoothstep(0.75, 1.00, r);
    
    vec3 color0 = vec3(0.0);
    vec3 color1 = vec3(255, 113, 91) / 255.;
    vec3 color2 = vec3(1.0);
    vec3 color3 = vec3(79, 71, 137) / 255.;
    
    return (
        color0 * (mix0 - mix1) +
        color1 * (mix1 - mix2) +
        color2 * (mix2 - mix3) +
        color3 * (mix3 - mix0 + 1.)
    );
}

float spikes(float x) {
    x = 1. - abs(sin(x));
    return x * x;
}

void main(void)
{
    
    float time = fract(time / 5.);
    const float PI = 3.14159265;
    float hue = time * 2. * PI;
    
    // Normalized pixel coordinates (from 0 to 1)
    float scale = distance(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / scale;
    uv -= vec2(resolution.x / scale, resolution.y / scale) / 2.;
    uv *= 2.0;
    
    float dist = log(uv.x*uv.x+uv.y*uv.y + 0.10) * 1.25;
    float angle = atan(uv.y, uv.x);
    const float spokes = float(8) / 2.;
    const float spokes2 = float(24) / 2.;
    
    float s1 = spikes(angle * spokes  + time * 2. * PI);
    float s2 = spikes(angle * spokes2 - time * 2. * PI);
    
    vec3 color = gradient(fract(
        (0.8 * dist * cos(3.0 * (time - 0.5)))
        + (3. * tan((time - 0.5) * 2.8))
        - 0.6 * s1
        - 0.3 * s2
    ));
    // Output to screen
    glFragColor = vec4(
        color,
        1
    );
}
