#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/WtXGD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float s = sin(time);
    float c = cos(time);
    
    ivec2 fc = ivec2(abs(gl_FragCoord.xy * mat2(c, -s, s, c) * s)) % 256;
    
    float xor = float(fc.x ^ fc.y) / 256.0;
    
    glFragColor = vec4(vec3(xor),1.0);
}
