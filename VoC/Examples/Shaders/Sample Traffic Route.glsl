#version 420

// original https://www.shadertoy.com/view/WdjyDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 O = glFragColor;
    vec2 C = gl_FragCoord.xy;

    O-=O-.05;
    for(float i,j=0.;j<12.;j++)
    for(i=0.;i<200.;i++)
        O+=abs(cos(vec4(6,3,5,0)+i*5.)+.2-.3)*
        exp(-40.*length(cross((abs(fract(fract(37.*sin((vec3(6,5,9)+i*.3)))+
        (time+j*.07)*.1)*2.-1.)*2.-1.)*3.,
        vec3(C.xy/resolution.y,1))));

    glFragColor = O;
}
