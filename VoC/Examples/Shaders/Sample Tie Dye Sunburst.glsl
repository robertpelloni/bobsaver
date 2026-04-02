#version 420

// original https://www.shadertoy.com/view/WtBXz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

vec3 palette(float l) {
    float m = 2.0*PI * l;
    return vec3(
        cos(m),
        cos(m + 2.0 * PI / 3.0),
        cos(m + 4.0 * PI / 3.0)
    );
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;
    //uv += vec2(0.0, -1.5);
    float th = atan(uv.y, uv.x);
    float baseLength = length(uv);
    vec2 wavy = vec2(
        sin(th * 19.0 + time),
        cos(th * 23.0 + time)
    );
    float waveScale = max(0.01, baseLength * 0.2);
    wavy *= waveScale;
    float f = length(uv + wavy);
    f -= time / 10.0;
    f = floor(8.0 * f)/8.0;

    vec3 col = palette(f);
    col = pow(col, vec3(1.0/2.2));

    // Output to screen
    glFragColor = vec4(col,1.0);

}
