#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/NsXXzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Inspired by a discussion on hackaday at:
// https://hackaday.com/2021/04/13/alien-art-drawn-with-surprisingly-simple-math/
// Formula shared by "Joe" on that page..

void main(void)
{
    // Scale and move to make things a litle more interesting t look at.
    float scale = 0.2;
    float trans = time * 7.0;
    vec2 coord = (scale * gl_FragCoord.xy) + vec2(trans,trans);
    
    // Heart of color selection.
    int val = ((int(coord.x) & int(coord.y)) % 3);
    float result = 0.0;
    for(int i = 0; i < 3; i++){
        coord /= (3.5+result);        
        val = ((int(coord.x) | int(coord.y+result)) % (3-val));
        result = ((result + float(val))/2.0);
    }
    // Output.
    glFragColor = vec4((result));
}
