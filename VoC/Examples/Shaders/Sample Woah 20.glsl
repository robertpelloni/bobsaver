#version 420

// original https://www.shadertoy.com/view/ltSczz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv.x += sin(time + uv.y);
    int x = floatBitsToInt(sin(time / 3.0) * (uv.x + 1.0) / 2.0);
    int y = floatBitsToInt(cos(time/4.0) * (uv.y + 1.0) / 2.0);
    int n = 20;
    int stripeX = ((x & (1 << n)) >> n) % 2;
    int stripeY = ((y & (1 << n)) >> n) % 2;
    int f = (stripeX + stripeY) % 2;
    glFragColor = vec4(f, tan(cos(time * 3.0)), (sin(uv.y * 10.0 * 6.28) + 1.0) / 2.0, 1.0);
}
