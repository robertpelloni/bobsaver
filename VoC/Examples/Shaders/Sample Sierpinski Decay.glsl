#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/lttyRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    highp float X = gl_FragCoord.x;
    highp float Y = gl_FragCoord.y;
    highp float sloTime = time/3.;
    highp int color = int(time * 99. + float(int(sin(sloTime)*X + cos(sloTime)*Y) & int(- cos(sloTime)*X + sin(sloTime)*Y)))%610;

    // Output to screen
    glFragColor = vec4(1. - float(color)/100., float(color)/610., float(color)/610., 1);
}
