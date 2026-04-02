#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x;
    float f = 50.0;
    float t = time * .150;
    float e = 0.123;
    float i = 7.7123;
    uv.x += t + sin(uv.y*i)*e;
    uv.y += t - cos(uv.x*i)*e;
    float g = 100.0;
    float k = sin(uv.x * g) * tan(uv.y*g) * f;
    glFragColor = vec4(k);
}
