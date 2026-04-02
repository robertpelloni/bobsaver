#version 420

// original https://www.shadertoy.com/view/wtXcDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 o=vec4(0);
    vec3 u=normalize(vec3(2.*gl_FragCoord.xy-resolution.xy,resolution.y))*1e2*sin(time*.2);
    for(int i=0;i<99;i++)
        u+=cos(u+time*.05),
        o=cos(dot(u.xy,u.xy)+vec4(1,.1,0,0));
    glFragColor=o;
}
