#version 420

// original https://www.shadertoy.com/view/ctVcWw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI     3.141592658979

float easeOutQuad(float x)
{
    return 1. - (1. - x) * (1. - x);
}

float degModifier(float x)
{
    return step(1., mod(x - 1., 2.)) * (1. - easeOutQuad(abs(mod(x - 1., 2.) - 1.))) * PI * 2.;
}

float triangle(vec2 pos, float r, float deg)
{
    vec2 rotated = vec2(pos.x * cos(deg) - pos.y * sin(deg), pos.x * sin(deg) + pos.y * cos(deg));
    float a = step(rotated.y, -sqrt(3.) * rotated.x + r);
    float b = step(rotated.y, sqrt(3.) * rotated.x + r);
    float c = step(-r / 2., rotated.y);
    
    return a * b * c;
}

void main(void)
{
    float cellSize = 80.;
    float deg = time;
    int xCell = int(ceil(gl_FragCoord.xy.x/cellSize));
    int yCell = int(ceil(gl_FragCoord.xy.y/cellSize));
    int cellCount = int(ceil(resolution.x / cellSize + resolution.y / cellSize));
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    vec2 pos = mod(gl_FragCoord.xy, cellSize) / cellSize - (0.5, 0.5);
    
    float d = deg + float(xCell + yCell - cellCount) / float(cellCount);
    float tBig = triangle(pos, 0.5, degModifier(d));
    float tSmall = 1. - triangle(pos, 0.45, degModifier(d));
    float v = 1. - tBig * tSmall;
    vec3 targetColor = vec3(int(ceil(time / 2.)) % 3 == 0 ? 1. : 0.3, int(ceil(time / 2.)) % 3 == 1 ? 0.5 : 0.3, int(ceil(time / 2.)) % 3 == 2 ? 1. : 0.3);
    vec3 color = mix(vec3(0., 0., 0.), targetColor, degModifier(d) / PI);
    
    
    vec3 res = v == 0. ? color : vec3(v, v, v);
    // Output to screen
    glFragColor = vec4(res, 1.);
}
