#version 420

// original https://www.shadertoy.com/view/fdjcWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Golfing by https://www.shadertoy.com/user/Xor

void main(void)
{
	vec4 O = gl_FragColor;    
	vec2 I = gl_FragCoord.xy;
	O -= O;
    
    for(int i=0; i++<36;)
    {
        vec2 r = resolution.xy,
             c = (I+I-r-1.+vec2(i%6,i/6)/3.) / r.y*8.-.5,
             p = fract(c)-.5;
    
        O += step(dot(p,p),.23) * fract(atan(p.x,p.y)/6.3
             + tan(length(ceil(c))*.2-time)*.1)/36.;
    }
	glFragColor = O;
}
