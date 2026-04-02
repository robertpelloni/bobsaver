#version 420

// original https://www.shadertoy.com/view/NssSzf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERS 12

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col,col_prev;
    float t;
    vec2 uv = (gl_FragCoord.xy*10.0-resolution.xy)/resolution.y/10.0;
    uv.y += (time)/8.0;
    for(int c=0;c<ITERS;c++){
        float scale = 2.25;
        float scale1 = 1.9;
        float s1 = scale1*scale;
        col_prev = col;
        for(int i=0;i<ITERS;i++)
        {
            uv = fract(uv.yx/s1)*s1;
            uv= -fract(uv+((vec2(uv.x/scale-uv.y/scale1,uv.y/scale-uv.x/scale1)/(scale))))*scale/scale1;
            uv.y /= -scale1;
        }
        col[c] = abs(fract(uv.y)-fract(uv.x));
        col = ((col+col_prev.yzx))/2.0;
    }
    glFragColor = vec4(vec3(col*3.0),1.0);
    
}
