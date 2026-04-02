#version 420

// original https://www.shadertoy.com/view/td33RN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float TWOPI = 2.0*3.14159265358979;
const float fac = 10.0 / TWOPI;

// 240, 23, 24
// 246, 128, 126
// 255, 255, 255

vec2 eval( vec2 p, vec2 c, float strength )
{
    p -= c;
    float l = log( length( p ) );
    float ang = atan( p.y, p.x );
    return strength * vec2( l, ang );
}

vec4 getColour( vec2 sp )
{
    vec2 p = 3.*(2.*sp - resolution.xy) / resolution.x;

    vec2 ep = eval( p, vec2( -1.5, 1 ), 1.0 ) 
        + eval( p, vec2( 1.5, -1 ), 1.0 )
        + eval( p, vec2( -1.5, -1 ), -1.0 )
        + eval( p, vec2( 1.5, 1 ), -1.0 );
    float d = fwidth(ep).x * 4.*fac;
    ep = ep + 4.*vec2(-ep.y,ep.x);
    vec2 si = smoothstep(-.5*d,.5*d,abs(mod(fac*ep + time*0.75,2.)-1.)-.5);  

    return 1.- (1.-vec4(1,.5,.5,0)) * (si.x+si.y);
}

void main(void)
{   
    glFragColor = getColour( gl_FragCoord.xy );
}
