#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tlcz4

uniform int frames;
uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Chris M. Thomasson's Stupid Simple Xor Roller. ;^)
// version: pre-alpha 0.0.2

void main(void)
{ 
    vec2 uv = gl_FragCoord.xy / resolution.xy; 

    int x = int(gl_FragCoord.xy.x); 
    int y = int(gl_FragCoord.xy.y); 

    int xy_xor = (x + frames) ^ (y);
    float s = .01 + abs(sin(time * .01)) * (abs(cos(time * sin(time * .05) * .001) * .01));
    
    float cr = mod(float(xy_xor) * 1.1 * s, 1.0);
    float cg = mod(float(xy_xor) * abs(sin(time * 0.01)) * 1.234 * s, 1.0);
    float cb = mod(float(xy_xor) * 2.253 * s, 1.0);
    
    float dis = .5 + abs(sin(time * .5)) * .4;
    
    if (cr < dis)
    {
         cr = 0.;  
    }
    
    glFragColor = vec4(cr, cr, cr, 1.0);
}
