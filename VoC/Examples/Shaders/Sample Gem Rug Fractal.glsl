#version 420

// original https://www.shadertoy.com/view/7dlfWn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+vec2(0,1.5))*scale)-.5);
}
void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;  
    float t1 = 64.*32.*1.5;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = 1.5;
    for(int i=0;i<12;i++)
    {
        uv = triangle_wave(uv,scale);
        uv = triangle_wave(uv.yx,scale)+triangle_wave(uv-.5,scale);
        col.x = (uv.x+uv.y);
        col = abs(col.yzx-col);
    }
    col = col;
    glFragColor = vec4(col,1.0);
}
