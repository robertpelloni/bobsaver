#version 420

// original https://www.shadertoy.com/view/ltf3DN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(){
    vec2 q=resolution.xy,p=gl_FragCoord.xy-.5*q;
    float u=length(p)*2./q.x,t=30.*sin(time*.02);
    u+=.05*sin(50.*u)+.02*sin(40.*atan(p.y,p.x))-.5;
    u=(1.+exp(-16.*u*u))*t;
    p=smoothstep(-t,t,mat2(cos(u),-sin(u),sin(u),cos(u))*p);
    glFragColor.xyz = vec3(p.x+p.y-p.x*p.y*2.);
}
