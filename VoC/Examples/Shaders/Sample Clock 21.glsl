#version 420

// original https://www.shadertoy.com/view/wdffz7

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define M(p) = (.2- smoothstep (0.2, .5, length(U)))* \
 fract( atan(U.x,U.y) / 6.28 -p ),
void main(void)
{
    vec2 u = gl_FragCoord.xy;
    vec4 O = glFragColor;

   vec2 U = (.6*u-.3*resolution.xy)/resolution.y;
   float
    i=date.w/60.,
    s M(i)
    m M(i/60.)
    h M(i/7.2e2)  
    b = length(U);
      O = vec4(h,m,s,.0)/b;   

    glFragColor = O;
}
