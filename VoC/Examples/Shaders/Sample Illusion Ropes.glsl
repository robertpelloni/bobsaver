#version 420

// original https://www.shadertoy.com/view/NdKyRV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// ropes are parallel

#define S(v) smoothstep(0.,1., abs( fract(v) *2. - 1. ) ).y   // smooth line

void main(void)
{
	vec2 u = gl_FragCoord.xy;
    vec2 R = resolution.xy,
         U = 14.*( u+u - R ) / R.y;
    vec4 O = vec4(   S( U )                                        // ropes
                   * S( U * mat2(3,1, abs(U.y)>6.5 ? -1 : 1 ,3) )  // threads
            );
    O = sqrt(O);                                              // to sRGB
	glFragColor = O;
}
