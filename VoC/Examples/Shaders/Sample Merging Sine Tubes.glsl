#version 420

// original https://www.shadertoy.com/view/tsKSWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float f(float x, float y)
{
    float arg = .9*time + 13.*y + 2.*sin(.3*time + 4.*x) - 20.*(x+.5)*y;
    return clamp(.7*cos(arg) + .2*cos(3.*arg) + .05*cos(5.*arg), -1., 1.);
}

float g(float x, float y)
{
    float arg = .9*time + 15.*x*1.+ .5*cos(.1*time) + 2.*cos(1.2*time + 10.*y);
    return clamp(-abs(.5*cos(arg)) + .7*cos(3.*arg) + .3*cos(5.*arg- 1.), -1., 1.);
}

void main(void)
{
    // Normalized pixel coordinates
    vec2 q =(gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    vec2 res = vec2(f(q.x, q.y), g(q.x, q.y));
    vec3 col = vec3(.0, .0, .5) + vec3( -1., .0, .5)*sqrt(res.x)*res.y;
    col += vec3(.0, 1., .0)*res.x*res.x * res.y*res.y;
    
    
    
    // Output to screen
    glFragColor = vec4(col,1.0);
}
