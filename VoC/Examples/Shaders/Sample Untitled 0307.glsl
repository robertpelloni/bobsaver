#version 420

// Hi guys
// it's just for fun
// I know almost nothing about glsl
// I just take a shader written by someone and change something.

// So before using this shader in your projects,
// please make sure it can't be optimized significantly.
// me2beats, 2018

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

void main() {
    vec2  surfacePos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.y;
    vec2 p = surfacePos;
    float a = cos(sin((atan(p.x,p.y))));
    float r = (length(p)*1.2);
    r = sin(abs(1.5*sin(a-4.5*r+time*1.1)) - r + 1.3*abs(cos(a*7.+r*5.-time*2.))) - .7*abs(sin(a*2.-r*3.+time*1.3));
    r = sin(abs(1.5*sin(a-4.5*r+time*1.1)) - r + 1.3*abs(cos(a*7.+r*5.-time*2.))) - .7*abs(sin(a*2.-r*3.+time*1.3));
    //r = fract(r+fract(a)+fract(r));
    glFragColor = vec4(r,r*r,.4,1);
}
