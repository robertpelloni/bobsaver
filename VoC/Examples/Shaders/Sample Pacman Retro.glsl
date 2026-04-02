#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/XdSfRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PIXELATION 30.
#define PIXELATE(uv) floor((uv)*PIXELATION)/PIXELATION

void main(void)
{
    vec2 screen = resolution.xy;
    
    vec2 uvBody = PIXELATE((gl_FragCoord.xy - screen / vec2(2.00, 2.00)) / screen.y),
         uvEye  = PIXELATE((gl_FragCoord.xy - screen / vec2(1.85, 1.25)) / screen.y);
    
    float newPos = 1.5 - float(int(time*10.) % 30)/10.;
    uvBody.x += newPos;
    uvEye.x  += newPos;
    
    float radiusBody = length(uvBody),
          radiusEye  = length(uvEye);
    
    glFragColor = vec4(1.,1.,0.,1.) *
                (
                    step(radiusBody, .5) *
                     step(uvBody.x / radiusBody, .85 - .15 * sin(time*8.)) - 
                     step(radiusEye, .05)
                );
}
