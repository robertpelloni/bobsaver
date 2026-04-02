#version 420

// original https://www.shadertoy.com/view/XtsyWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 O;
    float t = time*.1, m = .4*sin(t*.2);
    vec2 R = resolution.xy;
    O = vec4 ( dot( R = (2.+1.4*cos(t))*(U+U-R)/R.y,R ) *
             sin( abs (mod (.2*t+atan (R.y,R.x), 2.094) - 1.05) + t + vec2(1.6,0) ), m,0);
    for (int i=0; i< 45; i++)
        O.xzyw = vec4(1.3,.999,.678,0) * abs( abs(O)/dot(O,O) - vec4(1,1.02,.4*m,0) );
   glFragColor = O;
}
