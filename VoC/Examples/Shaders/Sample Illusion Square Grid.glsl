#version 420

#extension GL_EXT_gpu_shader4 : enable

// original shadertoy.com/view/ttXyWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) 
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c,s,-s,c);    
}
#define PI 3.141596

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    ivec2 gridI = ivec2(uv * 10.);
    bool grid = (gridI.x % 2 == gridI.y % 2);
    vec3 col = grid ? vec3(0.749) : vec3(0.596);
    vec2 ruv = -1. + 2. * fract(uv * 10. + 0.5);
    float x = smoothstep(0., 0.5, fract(time*0.5))*(0.5*PI);
    ruv *= rot(x);
    float lineBlur = 0.05;
    float lineWidth = 0.07;
    float horizontal = smoothstep(lineWidth+lineBlur,lineWidth, abs(ruv.y)) * smoothstep(0.5 + lineWidth + lineBlur,0.5 + lineWidth, abs(ruv.x));
    float vert = smoothstep(0.5 + lineWidth + lineBlur,0.5 + lineWidth, abs(ruv.y)) * smoothstep(lineWidth + lineBlur,lineWidth, abs(ruv.x));
    float d = max(horizontal, vert); 
    ivec2 rotI = ivec2(uv * 10. + 0.5);
    bool rotGrid = rotI.x % 3 == rotI.y % 3;
    vec3 rotCol = rotGrid ? vec3(0.839) : vec3(0.533);
    col = mix(col, rotCol, d);
    glFragColor = vec4(col, 1.0);
}
