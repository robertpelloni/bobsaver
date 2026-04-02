#version 420

// original https://www.shadertoy.com/view/tsf3D7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float modValue = 512.0;

float permute(float x)
{
    float t = ((x * 67.0) + 71.0) * x;
    return mod(t, modValue);
}

float shift(float value)
{
    return fract(value * (1.0 / 73.0)) * 2.0 - 1.0;
}

float rand(vec2 c)
{
    return shift(permute(permute(c.x) + c.y));
}

float valueNoise(vec2 c)
{
    vec2 p = floor(c);
    vec2 f = fract(c);
    
    vec2 i00 = mod(p, modValue);
    vec2 i01 = mod(p + vec2(0.0f, 1.0f), modValue);
    vec2 i10 = mod(p + vec2(1.0f, 0.0f), modValue);
    vec2 i11 = mod(p + vec2(1.0f, 1.0f), modValue);
    
    float f00 = rand(i00);
    float f01 = rand(i01);
    float f10 = rand(i10);
    float f11 = rand(i11);
    
    vec2 t = f * f * (3.0 - 2.0 * f);
    return mix(mix(f00, f10, t.x), mix(f01, f11, t.x), t.y);
}

float height(vec2 c)
{
    return (valueNoise(c) + mod(c.x, modValue));
}
    
const float plankWidth = 0.2f;
const float plankLength = 1.2f;
const float randOffset = 5.0f;
const float rings = 8.0f;
const float ringWidth = 0.2f;
const float edgeWidth = 0.02f;
const float edgeLength = 0.02f;
const float colorOffset = 0.15f;
    
const vec3 color1 = vec3(0.76, 0.54, 0.26);
const vec3 color2 = vec3(0.88, 0.72, 0.5);
const vec3 edgeColor = vec3(0.35, 0.18, 0.07);

void main(void)
{ 
    vec2 FC=gl_FragCoord.xy;
    FC.y += time * 100.0f;
    vec2 uv = FC / resolution.yy;
    uv = mod(uv, 512.0f);
    
    float plank = floor(uv.x / plankWidth);
    float start = mix(0.0f, rand(plank * vec2(12.345, 67.89)), randOffset);
    float item = floor(uv.y / plankLength + start);
    
    float h = fract(height(uv / vec2(plankWidth, plankLength) + item) * rings);
    float val = 1.0f - pow(h, 1.0f / ringWidth);
    
    vec3 color = mix(color1, color2, val);
    float darkness = mix(1.0, rand(vec2(mod(plank * 12.345, modValue), mod(item * 67.89, modValue))), colorOffset);
    
    float line = step(plankLength * edgeWidth, fract(uv.x / plankWidth)) *
        step(plankWidth * edgeLength, fract(uv.y / plankLength + start));
    
    vec3 lineColor = edgeColor * step(line, 0.0f);
    glFragColor = vec4(color * darkness * line + lineColor, 1.0f);
}
