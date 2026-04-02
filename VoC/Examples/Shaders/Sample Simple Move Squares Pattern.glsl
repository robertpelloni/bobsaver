#version 420

// original https://www.shadertoy.com/view/4d2Bz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// s = checker size
#define s 64.

bool P(vec2 p) {
    vec2 d = mod(p, s *2.);
    return (d.x < s) ^^ (d.y < s);
}

void main(void) {
    vec2 U=gl_FragCoord.xy;

    vec3 c = vec3(0);        // background black

    float t = (time +.5) *64.;  // +.5 Needed to be visible for 0 sec launch (startup).
    vec2 m = vec2(U.x -t, U.y +t);

    if ( P(vec2(m.x, U.y)) )
        c = vec3(.9, 0, 0);  // red pattern (.9 is enough for lighting.) :D

    if ( P(vec2(U.x, m.y)) )
        c = vec3(0, 0, .9);  // blue pat.

    glFragColor = vec4(c, 1);
}
