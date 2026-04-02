#version 420

// original https://www.shadertoy.com/view/XtlGDj

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    glFragColor = vec4((gl_FragCoord.xy-resolution.xy/2.)*(gl_FragCoord.yx*.002)
                   *mat2(sin(time),cos(time),-cos(time), sin(time))
                   *(1.-length(gl_FragCoord.xy/resolution.xy-.5)*4.)                           
                    ,0,0);
}
