#version 420

// original https://www.shadertoy.com/view/Mts3WH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2TC in 2T - 1
// 
// by bergi 
// 
// character encoding from movAX13h https://www.shadertoy.com/view/lssGDj

#define C(n)p+=2.+4.*sin(p.x+t)/(p.y+9.);q=floor(p*vec2(4.,-4.));if(int(mod(n/exp2(q.x+5.*q.y),2.))==1)f=sin(p.x+t),e=cos(p.y+t); 

void main()
{
    vec2 p = gl_FragCoord.xy / resolution.y * 9. - 9., q=p; float e = 0., f=e, t = time;
    C(32584238.) C(4329631.) C(15238702.) glFragColor = vec4(f,e,f-e,1.);
}
