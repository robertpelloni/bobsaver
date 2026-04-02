#version 420

// original https://www.shadertoy.com/view/MtVSz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float t = fract(.2*time);
    vec2  R = resolution.xy;
    vec2  U = (gl_FragCoord.xy-.5*R)/R.y;
    vec4 O = floor( vec4(  U *= 10. / pow(10.,t) , U*10.) );
    O =   (.9+.1 *sin(6.28*t +length(gl_FragCoord)/R.y + vec4(0,2.1,-2.1,0)) )
        * mix( mod(O.x+O.y, 2.), mod(O.z+O.a, 2.), t);
    glFragColor=O;
}
