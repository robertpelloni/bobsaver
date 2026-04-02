#version 420

// original https://www.shadertoy.com/view/wsjfWy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float plasma(vec2 uv, float t) {
    // these are just random values with time added (I'm not sure if I actually need this many)
    vec2 p0 = vec2(0.23 + t, 0.76 - 0.4 * t);
    vec2 p1 = vec2(-0.77 + 0.1 * t, 0.11 + 0.7 * t);
    vec2 p2 = vec2(0.63 - 0.3 * t, 0.26 + 0.2 * t);
    vec2 p3 = vec2(-0.47 - 0.55 * t, 0.91 - 0.35 * t);
    float a = 2.0;
    // here is the formula
    float grey = dot(sin(p0 + uv + a * sin(p1 + 1.6 * uv.yx)), sin(p2 + 1.4 * uv.yx + a * sin(p3 + 1.2 * uv)));
    return 0.5 + grey * 0.25;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    // Time varying pixel color
    uv *= 4.0;
    vec3 col = vec3(plasma(uv, 0.0 + time), plasma(uv, 0.3 + time), plasma(uv, 0.6 + time));
    // Output to screen
    glFragColor = vec4(col,1.0);
}
