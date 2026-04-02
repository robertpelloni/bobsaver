#version 420

// original https://www.shadertoy.com/view/ftByR1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float angle = time * 0.1;
    vec2 normalizedCoord = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    for (float i = 0.0; i < 128.0; i += 1.0) {
    normalizedCoord = abs(normalizedCoord);
    normalizedCoord -= 0.5;
    normalizedCoord *= 1.03;
    normalizedCoord *= mat2(
        cos(angle), -sin(angle),
        sin(angle), cos(angle)
    );
    }
    glFragColor = vec4(length(normalizedCoord),
    length(normalizedCoord + vec2(0.2, -0.3)),
    length(normalizedCoord + vec2(-0.4, -0.1)),1.0);
}
