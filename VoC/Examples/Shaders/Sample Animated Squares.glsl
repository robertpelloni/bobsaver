#version 420

// original https://www.shadertoy.com/view/3tfyRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 r(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c,-s,s,c);
}

void main(void) {
    vec2 uv = ((gl_FragCoord.xy-.5*resolution.xy)/resolution.y*5.+10.)*r(time*.1);
    float id = mod(floor(uv.x)+floor(uv.y),2.);
    float f = smoothstep(-.6,.6,cos(fract(time*(id*2.-1.)+id*.5)*3.1415));
    vec2 guv = (fract(uv)-.5)*(cos(fract(time+id*.5)*6.282)*.5+1.5)*r(f*1.5707);
    glFragColor = vec4(.5,.2,1,1)*(length(max(abs(guv)-.25,0.)) < .1 ? 1. : .6);
}
