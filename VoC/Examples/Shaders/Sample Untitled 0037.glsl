#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 pos = (gl_FragCoord.xy * 2.0 - resolution.xy) / resolution.y;
    float color = 0.0;
    float s = 1.0;
    
    for(int i=0; i<10; ++i) {
        float fi = float(i);
        float t = atan(pos.x, pos.y) + time * 0.02 * fi;
        float len = (0.0002 * fi) / abs(length(pos) - (0.5 + sin(t * (3.0 + fi)) * (0.2 - float(i) * sin(time + fi) * 0.01)));
        color += len * (1.0 - fi / 20.0);
    }
    
    color += length(pos) * 0.1;
    
    glFragColor = vec4(color) * vec4(2, 2, 4, 1);
}
