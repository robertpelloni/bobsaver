#version 420

// original https://www.shadertoy.com/view/ldSfzm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Raymarched plasma
// Idea based on iq 2 tweet raymarch: https://www.shadertoy.com/view/MsfGzM

float f(vec3 p) 
{ 
    p.z+=5.*time; 
    return length(.2*sin(time)+cos(p/3.)-.1*sin(3.*(sin(p.x)+.8*p.y)))-.8; 
}

void main(void)
{
    vec2 p=gl_FragCoord.xy;
    vec3 d=.5-vec3(p,0)/resolution.x,o=d;for(int i=0;i<64;i++)o+=f(o)*d;
    glFragColor.xyz = abs(f(o+d)*vec3(.3,.15,.1)+f(o+sin(time))*vec3(.1,.05,0))*(8.-o.x);
}
