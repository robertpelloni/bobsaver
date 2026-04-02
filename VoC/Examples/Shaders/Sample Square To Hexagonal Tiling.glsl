#version 420

// original https://www.shadertoy.com/view/3d3BD4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Fork of "simple hexagonal tiles" by lomateron. https://shadertoy.com/view/MlXyDl
// 2020-11-10 21:54:30

void main(void)
{
    vec2 u = 8.*gl_FragCoord.xy/resolution.x;
    
    float t = sin(time*4.0)*0.5+0.5;
    
    vec2 s = vec2(1.,mix(2.0, 1.732, t));
    vec2 a = mod(u     ,s)*2.-s;
    vec2 b = mod(u+s*vec2(.5*t, .5),s)*2.-s;
    
    glFragColor = vec4(.5*min(dot(a,a),dot(b,b)));
}
