#version 420

// original https://www.shadertoy.com/view/tdjcDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 O = glFragColor;
    vec2 C = gl_FragCoord.xy;

    O-=O;
    for(float i=0.;i<500.;i++)    
        O+=vec4((1.-cos((vec3(3,7,99)+i*9.)))
            *exp(-9.*length(cross((abs(fract(fract(
                99.*sin((vec3(1,5,9)+i*9.)))+time*.2)*2.-1.)*2.-1.)*9.,
                   vec3(gl_FragCoord.xy/resolution.y-.5,1)))),1)+1e-4;

    glFragColor = O;
}
