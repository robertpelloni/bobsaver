#version 420

// original https://www.shadertoy.com/view/mtfXRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* "Spirality" by @kishimisu (2023) - https://www.shadertoy.com/view/mtfXRB
   [248 chars]
*/

void main(void) {
	vec4 O = vec4(0.0);
	vec2 u = gl_FragCoord.xy;

    vec2  r = resolution.xy; u += u - r;     
    float i = 0.;
    
    for (O *= i; i++ < 1e2; O += pow(.005/               // attenuation
        length(u/r.y + i*(sin(time)*.5+.5)*.007 - .7)   // position
        *(cos(.1*i+vec4(0,1,2,0))+1.), O-O+1.3)          // color
    ) u *= mat2(cos(vec4(0,33,11,0) +                    // rotation
        (i < 2. ? time : sin(time/4.)*.1+.9) ));

	glFragColor = O;
}
