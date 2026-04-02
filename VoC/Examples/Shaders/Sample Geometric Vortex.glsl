#version 420

// original https://www.shadertoy.com/view/mdSGWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI       3.141592
#define S(a,b,d) mix(a, b, sin(d + n*PI*2.)*.5+.5)
#define rot(a)   mat2(cos( a +vec4(0,33,11,0)))
#define n        (-time*.04+.03)

void main(void) {
	vec4 O = glFragColor;
    vec2 u = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    for (float s = 0.; s < 3.; s++) { float p = 9.;
    for (float i = 0.; i < 25.; i++) {
        vec2  a = fract(rot(i*sin(n*PI*2.)*.25)*u*(i+S(1., 4., PI/2.))+.5)-.5;
        float r = mix(length(a), abs(a.x) + abs(a.y), S(0., 1.,));
        float t = abs(r + .1 - s*.02 - i*S(0.005, 0.05,));
        p = min(p, smoothstep(0., .1 + s*i*S(.0, .015, PI), t*S(s*.1 + .14, .2,)) +
            smoothstep(0., 20., i*S(.45, 1.,)) + smoothstep(0., 1., length(u)*i*.08));
    } O[int(s)] = .1/p; 
    } O.a=1.;
	glFragColor = O;
}
