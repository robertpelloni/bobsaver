#version 420

// original https://www.shadertoy.com/view/3s2fz3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float density=3.1415926*5.;//controls how small the checkers are

    //normalize stuff
    vec2 uv = gl_FragCoord.xy/(.5*resolution.y)-vec2(resolution.x/resolution.y,1.);
    
    //transform space
    vec2 t=uv/(length(uv)*length(uv));
    t+=vec2(sin(time*0.2),cos(time*0.2));

    //checkerboard pattern
    float col=ceil(cos(t.x*density)+cos(t.y*density));
    
    // Output to screen
    glFragColor = vec4(vec3(col),1.0);
}
