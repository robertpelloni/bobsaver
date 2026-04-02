#version 420

// original https://www.shadertoy.com/view/ctdXzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2( cos(a), -sin(a), sin(a), cos(a) )

void main(void) //WARNING - variables void ( out vec4 C, vec2 U ) need changing to glFragColor and gl_FragCoord.xy
{
    vec2 U = gl_FragCoord.xy;

    vec2  R = resolution.xy,
          u = .4*( U+U - R ) / R.x; 

    for (int i=0; i++<7;)
        u = abs( 1.6 * u * rot( time/8. - sin(5.*time)/40. ) ) - 1.;
    
    vec4 q = vec4(.1 + .4*sin((u.x+u.y)*15.));
    
    glFragColor = smoothstep(q, q - .5, abs(u.x) - abs(u.y) + vec4(-.2,.1,.4,1));
}