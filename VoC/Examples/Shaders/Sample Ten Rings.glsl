#version 420

// original https://www.shadertoy.com/view/DlXGD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec2  r;
    float red = p.x;
    float blue = p.y;
    float green = abs(red + blue / 2.0);
    vec3 destColor = vec3(red, green, blue);
    float f = 0.0;
    for(float i = 0.0; i < 10.0; i++){
        float s = sin(time * 4.0 + i * 0.628318) * 0.5;
        float c = cos(time * 9.0 + i * 0.628318) * 0.5;
        f += 0.005 / abs(length(p + vec2(c, s)) - abs(sin(time) * 0.8));
    }
    glFragColor = vec4(vec3(destColor * f), 1.0);
}
