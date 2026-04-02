#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/4lffzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
uniform int frames;

out vec4 glFragColor;

// Chris M. Thomasson's Stupid Simple Xor Roller. ;^)
// version: pre-alpha 0.0.1

void main(void)
{ 
    vec2 uv = gl_FragCoord.xy / resolution.xy; 

    int x = int(gl_FragCoord.x); 
    int y = int(gl_FragCoord.y); 

    int xy_xor = (x + frames) ^ (y + frames * int(mod(time, 1.0)));
    float s = .01 + abs(sin(time * .01)) * (abs(cos(time * sin(time * .05) * .001) * .01));
    
    float cr = mod(float(xy_xor) * 1.1 * s, 1.0);
    float cg = mod(float(xy_xor) * abs(sin(time * 0.01)) * 1.234 * s, 1.0);
    float cb = mod(float(xy_xor) * 2.253 * s, 1.0);
    
    glFragColor = vec4(cr, cg, cb, 1.0);

    //glFragColor = vec4(1.0-frames/255,frames/255,frames/255,1.0);
}
