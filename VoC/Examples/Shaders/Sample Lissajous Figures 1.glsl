#version 420

/*
 * LISSAJOUS FIGURES
 * Giulio Zausa
 */

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float dist(vec2 pos)
{
    float fx = 3.0, fy = 1.0;
    float t = asin(pos.y) / fy;
    return cos(fx * t + time) + sin(fy * t) - pos.x - pos.y;
}

void main()
{
    vec2 pos = gl_FragCoord.xy / resolution.xy;
    pos.x -= 0.5;
    pos.x *= resolution.x / resolution.y;
    pos.y -= 0.5;
    float d1 = dist(pos * 3.0), d2 = dist(-pos * 3.0);
    float color = ((d1 > -0.01 && d1 < 0.01) || (d2 > -0.01 && d2 < 0.01)) ? 1.0 : 0.0;
    
    glFragColor = vec4(vec3(color), 1.0);
}
