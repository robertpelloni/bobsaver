#version 420

// original https://www.shadertoy.com/view/tlXcRN

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

vec3 gradient(float x, float y) {
    const float _2PI3 = 2.094395102393193;
    float g1 = softsquare(x);
    float g2 = softsquare(x - 0.3);
    vec3 blend = (vec3(sin(y), sin(y + _2PI3), sin(y - _2PI3)) + 1.) * 0.5;
    return blend * g2 + (1. - blend) * g1;
}

float spikes(float x) {
    x = 1. - abs(sin(x));
    return x * x;
}

float time2(float x) {
    return cos(smoothstep(0.92, 1.0, fract(x)) * 3.14159265);
}

float time3(float x) {
    return smootherstep(0.92, 0.93, fract(x))
        //* (1.0 - smootherstep(0.99, 1.0, fract(x)))
        ;
}

void main(void)
{
    const float FastPeriod = 8.3;
    
    float time = floor(time * 60.) / 60.;
    const float PI = 3.14159265;
    const float speed = 4.;
    float hue = fract(time / 12.) * 2. * PI;
    float flash = (24. * time) * time3(time / FastPeriod)  * PI;
    
    // Normalized pixel coordinates (from 0 to 1)
    float scale = distance(resolution.x, resolution.y);
    vec2 uv = gl_FragCoord.xy / scale;
    uv -= vec2(resolution.x / scale, resolution.y / scale) / 2.;
    uv *= 2.0;
    
    float dist = log(uv.x*uv.x+uv.y*uv.y + 0.05) * 1.1;
    float angle = atan(uv.y, uv.x);
    float spokes = 8.5;
    
    vec3 color = gradient(
        dist +
        (0.3 + 0.1 * time3(time / FastPeriod)) * spikes(
            angle * spokes
            + sin(time / 32.)
        ) +
        fract(time / -24.)
        -16. * time2(time / FastPeriod)
    , hue + flash);

    // Output to screen
    glFragColor = vec4(
        color,
        1
    );
}
