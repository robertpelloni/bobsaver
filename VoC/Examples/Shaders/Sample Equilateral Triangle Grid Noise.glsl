#version 420

// original https://www.shadertoy.com/view/3lBXWc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hex(vec2 u)
{
    vec3 a = u*mat3x2(0.           ,1. ,
                       .86602540378, .5,
                       .86602540378,-.5);
    return max(1.-dot(abs(a),vec3(.57735026919)),0.);
}
void main(void)
{
    vec2 u = 8.*(2.0*gl_FragCoord.xy-resolution.xy)/resolution.y+time;
    
    vec2 s = vec2(2.,1.73205080757);
    vec2 a0 = (u+s*vec2(.0 ,.0))/s;
    vec2 a1 = (u+s*vec2(.5 ,.0))/s;
    vec2 a2 = (u+s*vec2(.25,.5))/s;
    vec2 a3 = (u+s*vec2(.75,.5))/s;
    vec2 a0f = fract(a0)*s-s*.5;
    vec2 a1f = fract(a1)*s-s*.5;
    vec2 a2f = fract(a2)*s-s*.5;
    vec2 a3f = fract(a3)*s-s*.5;
    float a0n = fract(sin(dot(floor(a0)+.0,vec2(37.341,97.784)))*47925.950837);
    float a1n = fract(sin(dot(floor(a1)+.1,vec2(37.341,97.784)))*47925.950837);
    float a2n = fract(sin(dot(floor(a2)+.2,vec2(37.341,97.784)))*47925.950837);
    float a3n = fract(sin(dot(floor(a3)+.3,vec2(37.341,97.784)))*47925.950837);
    glFragColor = vec4(hex(a0f)*a0n+
                     hex(a1f)*a1n+
                     hex(a2f)*a2n+
                     hex(a3f)*a3n);
}
