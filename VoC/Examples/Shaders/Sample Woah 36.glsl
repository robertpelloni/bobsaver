#version 420

// original https://www.shadertoy.com/view/fdSyRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//by: twitter.com/mattywillo_
//for: twitter.com/sableRaph's #WCCChallenge 
//prompt: creative code jail
//birbs nest discord: https://discord.gg/S8c7qcjw2b
//expanded version of my tribute to my sol lewitt wall drawing 370:
//https://twitter.com/mattywillo_/status/1479469787105292288

#define PI 3.1415926535897932384626433832795
mat2 rot(float a) {return mat2(cos(a), -sin(a), sin(a), cos(a));}
void main(void) {
    vec2 p = (gl_FragCoord.xy/resolution.xy*2.-1.)/vec2(1,resolution.x/resolution.y)*1.5,q;
    float t = mod(time/8.,1.),u = fract(t*2.),
    r = .283*(2.+smoothstep(.0,.25,u)*.5);
    q = (mod(p*rot(.25*PI)+r*.5,r)-r*.5);
    #define sq(p) (1.-step(0.,max(abs((p).y),abs((p).x))-.283))
    q*=rot((.25+(smoothstep(.75,.5,u)*.5)*sq(q)-.5*sq(p*rot(.25*PI)))*PI);
    glFragColor.xyz = vec3(smoothstep(0.,.1,sin(mix(q.x,q.y,step(.5,t))*PI*20.-.5*PI)));
    //o.xyz = vec3(smoothstep(0.,smoothstep(0.,1.,length(p)),sin(mix(q.x,q.y,step(.5,t))*PI*20.-.5*PI)));
}
