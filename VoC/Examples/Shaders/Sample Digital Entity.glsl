#version 420

// original https://www.shadertoy.com/view/mdf3Ws

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define S(a,b,d) mix( a, b, sin( d + t*PI*2. )*.5+.5 )
#define rot(a)   mat2(cos( a +vec4(0,33,11,0)))
#define PI       3.14
#define t        (time*.08)

float dRect(vec2 p, float b) {
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}

void main(void) { //WARNING - variables void (out vec4 O, in vec2 F) {     need changing to glFragColor and gl_FragCoord.xy
    vec4 O = vec4(0.0);
	vec2 F = gl_FragCoord.xy;
	vec2 u = (-resolution.xy/2. + F)/resolution.y, u0 = u;  
    u = fract(vec2(abs(u.x), u.y) * (4. + S(-2., 2.,)));
        
    float d;
    for (int k=0; k<75; k++) {
        if (k%25==0) d = 9.;
        float c = float(k/25);
        vec2  n = u + vec2(k%5, (k/5)%5)-3.;
        n = rot(length(u0)*length(n)*sin(t*PI*2.)*14. + c*S(.0,.2,PI)) * n;
        d = min(d, dRect(n + c*S(.0,.1,) + S(-.6,.8,), S(-.1,-.1,)));
        O[k/25] = pow(.3/d, 1.4);
    }
	glFragColor=O;
}
