#version 420

// original https://www.shadertoy.com/view/4ly3zc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot2(spin) mat2(sin(spin),cos(spin),cos(spin),-sin(spin))

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.y*2.0-resolution.xy/resolution.y;
    
    float l = 0.0;
    vec2 rot = vec2(sin(time*0.1),cos(time*0.1));
    
    for(int i = 0; i < 256; i++) {
        
        uv = 1.1*(uv.x*vec2(rot.x,rot.y)+uv.y*vec2(-rot.y,rot.x));
        
        if((uv.y) > 1.0) {
            break;
        }
        l++;
    }
    
    glFragColor = vec4(mod(l, 2.0));
}
