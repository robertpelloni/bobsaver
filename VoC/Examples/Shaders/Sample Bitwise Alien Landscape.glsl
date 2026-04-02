#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/sdXSzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "Bitwise cloud landscape" by jarble. https://shadertoy.com/view/7slSDM
// 2021-04-18 19:42:52

#define ITERS 8
void main(void)
{
    // Scale and move to make things a litle more interesting t look at.
    float scale =7000.0;
    float trans = time * 220.0;
    vec2 coord = (scale * gl_FragCoord.xy/resolution.xy * 0.5) + vec2(0,trans-3000.0);
    coord.x += cos((coord.y + time) * 0.001)* 18.;
    coord.y += cos((coord.x + time) * 0.01)* 28.;
    int val = 0;
    float result = 0.0;
    vec3 col = vec3(0.0);
    vec3 col_prev = vec3(0.0);
    for(int i = 0; i < ITERS; i++){
        col_prev = col;
        coord.y -= (result-11.0);
        coord += coord.yy/(6.0+3.0 * sin(time*0.004))+col.x;
        coord = coord.yx/(3.4);
        result = ((result + float(val = ((int(coord.x+coord.y/abs(2.5 + cos(time*0.001))) & int(coord.y+coord.x/2.4)) % 3)))/(2.0));
        col.x = smoothstep(1.00,0.59,result*1.35);
        col = ((col.yzx)*1.7+col_prev)/3.06;
    }
    // Output.
    glFragColor = vec4((col),0.0);
}
