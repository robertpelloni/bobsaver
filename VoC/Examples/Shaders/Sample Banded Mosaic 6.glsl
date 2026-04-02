#version 420

// original https://www.shadertoy.com/view/NlyyWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 triangle_wave(vec2 a){
    return abs(fract((a+vec2(1.,0.5))*1.5)-.5);
}

void main(void)
{
    glFragColor = vec4(0.0);
    vec3 col = vec3(0.);
    float t1 = 8.*4.;
    vec2 uv = (gl_FragCoord.xy)/resolution.y/t1/2.0;
    uv += vec2(time/2.0,time/3.0)/t1/8.0;
    float scale = 1.5;
    vec2 t2 = vec2(0.);
    for(int k = 0; k < 12; k++){
        uv = (uv+t2)/scale;
        t2 = -triangle_wave(uv-.5);
        uv = t2-triangle_wave(uv.yx);
        col = abs(vec3(uv.y-uv.x,col.yz));
        if(t2.x-t2.y < 0.) col = col.yzx;
    }
    glFragColor = vec4(col*2.,1.0);
}
