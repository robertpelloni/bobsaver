#version 420

// original https://www.shadertoy.com/view/fdcXWf

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

vec3 gradient(float r, float palette) {
    float mix0 = step(0.5, r);
    
    vec3 color0 = vec3(0, 192, 255) / 255.;
    vec3 color1 = vec3(255, 0, 128) / 255.;
    vec3 color2 = vec3(220, 255, 0) / 255.;
    vec3 color3 = vec3(64, 0, 128) / 255.;
    
    return mix(
        mix(color0, color1, mix0),
        mix(color2, color3, mix0)
    , palette);
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
    
    float dist = log(uv.x*uv.x+uv.y*uv.y);
    float angle = atan(uv.y, uv.x);
    const float spokes = float(6) / 2.;
    const float spokes2 = float(30) / 2.;
    
    float s1 = spikes(angle * spokes  + time * 2. * PI);
    float s2 = spikes(angle * spokes2 - 5. *  time * 2. * PI);
    float spiral = fract(
        3. * angle / (PI * 2.)
        + dist * 0.4
        + time * 18.
    );
    
    vec3 color = gradient(fract(
        (0.4 * dist * cos(3.0 * (time - 0.5)))
        + (3. * tan((time - 0.5) * 2.8))
        
      //  - 0.6 * s1
        - 0.2 * s2
    ), floor(0.5 + spiral));
    
    // Output to screen
    glFragColor = vec4(
        color,
        1
    );
}
