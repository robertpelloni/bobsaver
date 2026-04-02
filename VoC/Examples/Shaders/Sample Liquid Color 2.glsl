#version 420

// original https://www.shadertoy.com/view/sscGWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
     vec2 coord = 6.0 * gl_FragCoord.xy / resolution.xy;
    for(int i = 1;i < 190;i++){
        float n = float(i);
        coord += vec2(0.7 / n * sin(n * coord.y + time  + 0.3) + 0.8, 0.4 / n * sin(n * coord.x + time + 0.3 ) + 0.6);
    }
    vec3 color = vec3(0.5 * sin(coord.x) + 0.5, 0.5 * sin(coord.y) + 0.5,sin(coord.x+coord.y));
    glFragColor = vec4(color,1.0);
}
