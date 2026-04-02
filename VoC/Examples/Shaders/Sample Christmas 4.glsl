#version 420

// original https://www.shadertoy.com/view/mllGzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
@kishimisu - 2022 [256 chars]
An happy christmas tree !
*/

void main(void) { //WARNING - variables void (out vec4 O, vec2 F) {  need changing to glFragColor and gl_FragCoord.xy
	vec4 O =vec4(0.0);
	vec2 F = gl_FragCoord.xy;

    vec2 r = resolution.xy; O *= 0.;
    for (float i=0.,y, t=time*.04; i<150.; O +=
        .05/abs(length(1.3*(F+F-r)/r.y+
        vec2(cos(i*4.+t*40.)*(y*.5+.5),y) * (1.+sin(y*10.)*.2))
        /.01+cos(t+i)-1.)*(y+3.)*(cos(i++/2.+vec4(4,1,6,0))+1.)
    ) y = sin(i*.1+t);

	glFragColor = O;
}
