#version 420

// original https://neort.io/art/bqd2mn43p9fdlitd9ijg

#define r resolution
#define t time
#define b backbuffer
precision highp float;
uniform vec2 resolution;
uniform float time;
uniform sampler2D backbuffer;

out vec4 glFragColor;
#define F(a)if(length(vec2(sin(a*30.+t*6.8)*.4,cos(a*40.+t*7.9)*.4)-p)<.03*sin(a*90.+t*9.)+.04){c+=vec4(.5,cos(a*90.+t)+1.,sin(a*90.+t)+1.,0);}
void main(){vec2 p=gl_FragCoord.xy/r-.5;p*=1.05;vec4 c=texture2D(b,p+.5);F(0.);F(1.);F(2.);F(3.);c-=.01;c.a=1.;glFragColor=c;}
