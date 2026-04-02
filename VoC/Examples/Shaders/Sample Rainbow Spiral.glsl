#version 420

// original https://www.shadertoy.com/view/clfGW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/* @kishimisu - 2022 [226 chars] */

void main(void) { //WARNING - variables void (out vec4 O, vec2 F) { need changing to glFragColor and gl_FragCoord.xy
	vec2 F = gl_FragCoord.xy;
	vec4 O = vec4(0.0);

    vec2 r = resolution.xy;
    float i = .3, l = length(F+=F-r)/r.y + i, t = time;

    for (O *= 0.; i < 12.; 
         O += length(min(r.y/abs(F),r))/3e2*(cos(++t+i+vec4(0,1,2,0))*l+l)) 
         F *= mat2(cos(l*.2-i++*--t/1e2+vec4(0,33,11,0)));

	glFragColor = O;
}
