#version 420

// original https://www.shadertoy.com/view/cldyR2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// reproducing Gianni Sarcone's https://twitter.com/gsarcone/status/1721681488628854791
// golfed version below

#define f(v)  sin( 27.*(v) )
#define S(v) smoothstep( -1., 1., ( f(v) -.7 ) / fwidth(f(v)) )

void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec2  R = resolution.xy,
          U = ( u - .5*R ) / R.y;                   // normalize coordinates
    float l = length(U), a = atan(U.y,U.x),         // polar coords
         s1 = S(a - l ),                            // still spirals
         s2 = S(a + l - .3*time );                 // rotating counter-spirals
    glFragColor = max( vec4(1,1,0,0) * max(s1,s2) ,           // yellow spirals
             s1 * s2 );                             // white intersection
}