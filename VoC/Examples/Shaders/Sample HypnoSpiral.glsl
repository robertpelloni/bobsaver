#version 420

// original https://www.shadertoy.com/view/WdtBR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{vec2 uv=gl_FragCoord.xy/resolution.xy-0.5;uv.x*=16./9.;
float a=atan(uv.x,uv.y)*6.+cos(time)/1.5;float l=length(uv)*25.-1.5*time;
float b=pow(1.+cos(l+a),100.);float c=pow(1.+cos(l-a),100.);
glFragColor=vec4(1.-min(b,c),b,c,1.0);}
