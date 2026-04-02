#version 420

// original https://www.shadertoy.com/view/ftdGzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//change these constants to get different patterns!
#define c2 1.5

#define c1 vec4(1.0+c2,.5+c2,-1.5,0)

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+c1.xy)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;  
    float t1 = 4.5*3./2.;
    float t = time/8.;
    vec2 uv = (gl_FragCoord.xy-resolution.xy)/resolution.y/t1/128.0/12.;
    uv += vec2(t/2.0,t/3.0)/t1/128.0/6.;
    float scale = c1.z;
    for(int j = 0; j < 18;j++){
        uv = (triangle_wave(uv.yx+scale,scale)+triangle_wave(uv,scale));
        col[0] += fract(uv.x*.5-uv.y);
        col = abs(col.yzx*col.x)/(col.x+col.y);
    }
    glFragColor = vec4(vec3(col),1.0);  
}
