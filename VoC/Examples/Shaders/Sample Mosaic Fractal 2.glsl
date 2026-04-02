#version 420

// original https://www.shadertoy.com/view/ft3XzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//change these constants to get different patterns!
#define c1 vec3(2.,0.5,1.5)

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+c1.xy)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;  
    float t1 = 36.*16.;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = c1.z;
    for(int i=0;i<6;i++)
    {
        vec2 t2 = vec2(0.);
        for(int k = 0; k < 9; k++){    
            uv += (t2.yx)/(scale);
            t2 = triangle_wave(uv.yx-.5,scale)*scale;
            vec2 t3 = triangle_wave(uv,scale)/scale;
            uv.yx = -(t2+t3);
        }
        col.x = abs(uv.y-uv.x+col.x);
        col = col.yzx;
    }
    glFragColor = vec4(col,1.0);   
}
