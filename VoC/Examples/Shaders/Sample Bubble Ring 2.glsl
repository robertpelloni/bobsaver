#version 420

// original https://www.shadertoy.com/view/WlfczM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 o = glFragColor;
    vec3 u=normalize(vec3(2.*U-resolution.xy,resolution.y));
    for(int i=0;i++<6;)
        u.x+=sin(u.z+time*.1),
        u.y+=cos(u.x+time*.1),
        o=max(o*.9,cos(3.*dot(u,u)+vec4(.3,.1,0,0)));
    glFragColor = o;
}
