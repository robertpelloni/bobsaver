#version 420

// original https://www.shadertoy.com/view/stX3RB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERS 6

vec2 triangle_wave(vec2 a){
    return abs(fract((a/2.))-.5)*2.0;
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col=vec3(0.0),col_prev=vec3(0.0);
    float t=0.0;
    vec2 uv = (gl_FragCoord.xy*10.0-resolution.xy)/resolution.y/15.0;
    uv += vec2((time)/30.0,time/70.0)*2.5;
    for(int c=0;c<ITERS;c++){
        float scale = 1.45;
        float scale1 = 1.1;
        float s1 = scale1*scale;
        col_prev = col;
        for(int i=0;i<ITERS;i++)
        {
            uv.x /= -scale1;
            uv= triangle_wave(uv+((vec2(uv.x/scale-uv.y/scale1,uv.y/scale-uv.x/scale1)/(scale))))/scale1;
            
            uv = triangle_wave(uv.yx/s1)*s1;
            uv.y *= scale1;
        }
        col[2] = abs((uv.y)-(uv.x));
        col = ((col+col_prev.yzx));
    }
    glFragColor = vec4(vec3(col/float(ITERS)),1.0);
    
}
