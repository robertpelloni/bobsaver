#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NssSRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//#define ITERS 9 //normal world map
#define ITERS 12 //swamp world

void main(void)
{
    // Scale and move to make things a litle more interesting t look at.
    float scale = 10000.0;
    float trans = time * scale/8.0;
    vec2 coord = (scale * gl_FragCoord.xy/resolution.xy) + vec2(trans+30000.0,0.0);
    
    // Heart of color selection.
    int val = ((int(coord.x) & int(coord.y)) % 3);
    float result = 0.0;
    vec3 col = vec3(0.0);
    vec3 col_prev = vec3(0.0);
    for(int i = 0; i < ITERS; i++){
        col_prev = col;
        coord.y -= (4.0-result);
        coord -= coord.yy/16.0;
        coord = coord.yx/(2.5);
        result = ((result + float(val = ((int(coord.x-coord.y/2.0) & int(coord.y+coord.x/2.0)) % 3)))/(2.0));
        col.x = result;
        col = ((col.yzx)*3.0+col_prev)/4.0;
    }
    // Output.
    glFragColor = vec4((col),0.0);
}
