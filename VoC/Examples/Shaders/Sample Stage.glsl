#version 420

// original https://www.shadertoy.com/view/wtfcDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 o=glFragColor;
    vec3 u=normalize(vec3(2.*gl_FragCoord.xy-resolution.xy,resolution.xy.y))*1.2;
    for(float i=0.;i<4.;i++)
        u.y+=cos(u.y*i*5.)*.1,
        u.z+=sin(u.x*u.x+u.y*u.y-time*.3),
        u+=cos(u*i*7.)*.1,
        o=max(o,cos(3.*dot(u,u)+vec4(.3,.1,0,0)));
    glFragColor=o;
}
