#version 420

// original https://www.shadertoy.com/view/ssG3Wc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: bitless
// Title: Sacred Timeline Anomaly

// Thanks to Patricio Gonzalez Vivo & Jen Lowe for "The Book of Shaders"
// and Inigo Quilez (iq) for  http://www.iquilezles.org/www/index.htm
// and Fabrice Neyret (FabriceNeyret2) for https://shadertoyunofficial.wordpress.com/
// and whole Shadertoy community for inspiration.

#define hue(v) ( .6 + .6 * cos(6.3*(v) + vec4(0,23,21,0) ) )
#define rot(a)   mat2(cos(a + vec4(0,11,33,0)))
#define S smoothstep

float h21 (vec2 p) {
    p = mod(p,8.);
    return fract(sin(dot(p,vec2(12.9898,2.233)))*43758.5453123);
}

float N( in vec2 p ) 
{
    vec2 i = floor( p )
        ,f = fract( p )
        ,u = f*f*(3.-2.*f);
    return mix( mix( h21( i + vec2(0,0) ),h21( i + vec2(1,0) ), u.x),mix( h21( i + vec2(0,1) ), h21( i + vec2(1,1) ), u.x), u.y);
}

void wave (vec2 u, float n, float b, inout vec4 C)
{

     vec4 ac = hue(sin(u.x*.5-time+n+u.y)), //anomaly color
          tc = vec4(vec3(N(vec2(n,time))),.5); //timeline color
    float r = .8 //timeline circle radius
        ,t = (sin(time*.7)+1.)*.6 //anomaly strengh timer
        ,w = S(2.*t,0.,abs(u.x-4.)) //anomaly width
        ,tn = N(vec2(u.x*2.,u.x+n-time*.7))*.04
        ,an = N(vec2(u.x*2.,u.x+n+time*4.))*w*t 

    ,s = 5./resolution.y //smoothness
    ,l = S(.001+s,.001-s,abs(u.y-r-tn)) //timeline line
    ,a = S(.5-min(an,.3),.4-min(an,.4)-s,abs(.5 - fract(S(tn+an*.2,tn-an*.2,u.y-r)*5.))); //anomaly lines
    
    C = mix(C,ac,b*t*w*length(u.y*2.)*.2); //glowing
    C = mix(C, ac,a*t); //anomaly
    C = mix(C, tc,l); //timeline
}

void main(void)
{
	vec2 g=gl_FragCoord.xy;
	vec4 C=vec4(0.0);

    vec2 r = resolution.xy
        ,u = (g+g-r)/r.y;

    float rd = length(u);
    vec2 uv = u*rot(-rd*.2);
    float b = N(vec2(.8/rd + time, atan(uv.y,uv.x)/3.1415*8.)); 
    b *= N(vec2(b*5.))*rd*.5;
    C = vec4(vec3(0.,0.3,0.6)*b,1.); //background

    u = u*rot(-time*.25);
    u = vec2(4.+4.*atan(u.y,u.x)/3.14,length(u));
    for (float n = 0.; n< 10.; n++)
        wave(u,n,b,C);

	glFragColor=C;
}
