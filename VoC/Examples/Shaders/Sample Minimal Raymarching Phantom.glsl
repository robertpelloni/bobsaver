#version 420

// original https://www.shadertoy.com/view/wlscDH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 o;
    vec3 d=vec3(gl_FragCoord.xy/resolution.xy-.3*sin(time)-.5,.2*cos(time*.3)+.3),
    p=vec3(sin(time),cos(time),time)*9.,q,c;
    float s;for(int i=0;i<99;i++)
    p+=d*(s=max(abs(length(sin(p.zxy*.6)-cos(p))-.5),.02)),
    c+=exp(-s*9.);
    o=1.2*vec4(vec3(.8,1,1)-c/55.,1);
    glFragColor=o;
}
