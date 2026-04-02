#version 420

// original https://www.shadertoy.com/view/3tGGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    float t = time, a = atan(uv.y, uv.x), r = length(uv) / sqrt(2.);
    // some parameters to play with:
    float stripes = 11.;
    float speed = 3.;
    float spiralFactor = 2.;
    float wobblyFactor = 0.4;
    float wobblyFreq = 20.;
    float v = cos(speed * t + stripes * a + exp(spiralFactor * r + 2. + wobblyFactor * sin(0.66 * speed * t + wobblyFreq * r)));
    glFragColor = vec4(v / fwidth(v));
}
