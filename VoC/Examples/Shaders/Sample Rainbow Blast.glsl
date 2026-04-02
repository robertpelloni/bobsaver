#version 420

// original https://www.shadertoy.com/view/msyGDm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    float time = time * 2.0;

    float dist = length(uv);
    float angle = atan(uv.y, uv.x);

    float radius = pow(dist, 0.5) * 2.0;
    float wave = sin(radius * 10.0 - time) * 0.1 + sin(radius * 20.0 - time) * 0.2 + sin(radius * 30.0 - time) * 0.3;
    float intensity = smoothstep(0.5, 0.4, dist) * wave;

    vec3 color = vec3(0.0);
    color.r = intensity * sin(angle * 5.0 + time);
    color.g = intensity * cos(angle * 10.0 + time);
    color.b = intensity * sin(angle * 15.0 + time);
    color = color * 2.0;
    glFragColor = vec4(color, 1.0);
}
