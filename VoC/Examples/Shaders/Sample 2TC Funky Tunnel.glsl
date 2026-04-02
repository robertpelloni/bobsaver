#version 420

// original https://www.shadertoy.com/view/4tsGDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main()
{
    float t = time, d;

    vec2 z = 8.*(2.*gl_FragCoord.xy-resolution.xy)/resolution.xx;
    d = 1./dot(z,z);
    
   
    glFragColor =
        // color
        vec4(d*3.,.5,0,0)*
        // stripes
        sin(atan(z.y,z.x)*30.+d*99.+4.*t)*
        // rings
        sin(length(z*d)*20.+2.*t)*
        // depth
        max(dot(z,z)*.4-.4,0.);
}
