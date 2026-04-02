#version 420

// original https://www.shadertoy.com/view/ml2GWD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) {
	vec4 O = vec4(0.0);
	vec2 u = gl_FragCoord.xy;

    u = abs(u+u-(O.xy=resolution.xy))/O.y;
    O -= O;
    for (float i = 0., t = .5*time; i < 50.; O += .001
    /abs(abs(u.x + .75*sin(t+i*.20)) + u.y - 1.0*sin(t+i*0.5))
    *(2.0+sin(i+++vec4(0,1,2,3))));       

	glFragColor = O;
}
