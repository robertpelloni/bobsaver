#version 420

// original https://www.shadertoy.com/view/WsjyWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void) { //WARNING - variables void (out vec4 O, vec2 C ) { need changing to glFragColor and gl_FragCoord.xy
    for (float T, D, i = 0.; i < 99.; i += .1) {
        vec3 B, P = vec3((gl_FragCoord.xy - resolution.xy * .5) / resolution.y, 2) * T;
        P.y += sin(P.x + time) * .3 - 9.;
        P.xy *= mat2(cos(T + vec4(0, 5, 8, 0)));
        B = abs(mod(P + time, 10.) - 5.) - vec3(2, .01, .3);
        T += D = (length(max(B, 0.)) + min(max(B.x, max(B.y, B.z)), 0.)) * .02;
        glFragColor += (D < .001) ? .05 / i : 0.;
    }
}
