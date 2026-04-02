#version 420

// original https://www.shadertoy.com/view/7d2BDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define c1 vec3(1.,0.5,1.5)

vec2 triangle_wave(vec2 a,float scale){
    return abs(fract((a+c1.xy)*scale)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col;  
    float t1 = 36.*16.*16.*1.5;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = c1.z;
    float offset = 0.;
    float offset1 = time/1000.;
    for(int i=0;i<9;i++)
    {
        vec2 t2 = vec2(0.);
        vec2 t3 = vec2(0.);
        for(int k = 0; k < 3; k++){
            uv += (t2.yx);
            uv /= -1.35;
            vec2 temp = t2;
            t2 = triangle_wave(uv.yx-.5,scale);
            t3 = -triangle_wave(uv,scale);
            uv.yx = (t2+t3)/scale;
            //uv += uv/scale;
        }
        col.x = min(uv.y+uv.x+col.x,col.x*2.);
        //uv.x *= -1.;
        col = abs(col.yzx-vec3(col.x)*2.)/2.;
        uv.y *= -1.;
    }
    glFragColor = vec4(col*2.,1.0);
}
