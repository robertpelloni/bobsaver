#version 420

/*
 * LISSAJOUS FIGURES
 * Giulio Zausa
 */

 #define M_2PI 6.28318531
#define step 0.005
#define fx 3.0
#define fy 5.0
#define eps 0.005

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

float dist(vec2 pos)
{
    for (float t = 0.0; t < M_2PI; t += step)
        if(abs(cos(fx * t + time) - pos.x) < eps && abs(sin(fy * t) - pos.y) < eps)
            return 1.0;
    return 0.0;
}

void main()
{
    vec2 pos = (gl_FragCoord.xy / resolution.xy - 0.5) * 3.0;
    pos.x *= resolution.x / resolution.y;
    float color = dist(pos);
    
    glFragColor = vec4(vec3(color, 0.0, 0.0), 1.0);
}
