#version 420

// original https://www.shadertoy.com/view/3l2SD1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Based on Damn your eyes by  @P_Malin
//made by Chris the Wizz

#define divisions 1500.
//for fullscreen up the division to 5000

void main(void)
{
    vec4 c = glFragColor;
    vec2 p = gl_FragCoord.xy;

    vec2 uv = (p.xy / resolution.xy) * 2. - 1.;
    uv.x *= resolution.x / resolution.y;
    float r = max( 0.,  1. - length(uv) );
    float t = time ; 
    t = r * r * sin(r+t)*3.;    
    uv *= mat2( cos(t), -sin(t), sin(t), cos(t) );
    c = vec4( sin( uv.x*divisions   ) *sin(uv.y*divisions )* 0.8 + 0.5 );
    c *=  0.+ smoothstep(1.0-length(uv),0.,.05)*
        smoothstep(0.,1.0-length(uv),1.0);
    
    glFragColor = c;
}
