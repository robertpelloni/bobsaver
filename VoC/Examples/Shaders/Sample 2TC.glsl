#version 420

// original https://www.shadertoy.com/view/4tl3W8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//2 Tweets Challenge by nimitz (@stormoid)

//The rules:
//  -Label your shaders with [2TC 15]
//    -280 Chars or less (as counted by shadertoy)
//    -Submissions end Feb 2 2015 (2 weeks)
//    -You can use macros as much as you want
//  -Don't expect any sort of large prize

#define t time
void main(void){
    vec2 p = gl_FragCoord.xy/resolution.y - vec2(.9,.5)+sin(t+sin(t*.8))*.4;
    float r = length(p), a = atan(p.y,p.x);
    vec4 c=vec4(0.0,0.0,0.0,0.0);
    for (float i = 0.;i<60.;i++){
        c = c*.98 + (sin(i+vec4(5,3,2,1))*.5+.5)*smoothstep(.99, 1., sin(log(r+i*0.05)-t-i+sin(a)))*r;
        a += t*.01;
    }
    glFragColor = c;
}
