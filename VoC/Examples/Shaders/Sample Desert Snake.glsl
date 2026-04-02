#version 420

// original https://www.shadertoy.com/view/tlyyzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 U=(gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;
    float angle=.75+atan(U.x+sin(U.y*10.+time*2.)*.1,U.y-.25)*.1;
    vec3 c=mix(vec3(1.,1.,0.),vec3(1.,.5,0.),angle);
    glFragColor = vec4(c,1.0);
}
