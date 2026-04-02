#version 420

// original https://www.shadertoy.com/view/slsfRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Tweet: https://twitter.com/XorDev/status/1519343739419959297
//Twigl: https://t.co/FELzNSfU40
//Based on "Molecules 2": https://www.shadertoy.com/view/7llBzS

void main(void) //WARNING - variables void (out vec4 O, vec2 I) need changing to glFragColor and gl_FragCoord.xy
{
	vec2 I=gl_FragCoord.xy;
    vec3 r=vec3(resolution,1.0),
    c = vec3(0,2,1),
    T=time+c,
    P=(I+I-r.xy)/r.y*mat3x2(-7,4, 0,-8, 7,4) / 6.+.2;
    int A=int(T.z)/2%3;
    glFragColor=min((.08-length(max(abs(fract(
    P+=(T-sin(T*6.283)/6.).x*floor(mod(T,3.)-1.)*cos(ceil(P[int(T.y)%3])*3.14)
    )-.5)-.4,0.)))*.2*r.y,1.)
    *(sin(dot(mod(ceil(P+vec3(A<1,A<2,A-1)),2.),c+7.)-c)*.5+.5).xzyz;
}
