#version 420

// original https://www.shadertoy.com/view/4tlfRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define r(a) mat2(cos(a),-sin(a),sin(a),cos(a))

void main(void)
{
    vec2 R = resolution.xy;
    vec2 u = gl_FragCoord.xy;
    vec2 U = r(time) * ( u+u - R ) / R.y;
    vec2 S = sign(U) * r(.1);
    vec4 O = vec4( sin( 8.* log( dot( U, S ) ) + atan(S.y,S.x) -10.*time) );
    glFragColor = smoothstep( .7, .5, abs(O) );
}
