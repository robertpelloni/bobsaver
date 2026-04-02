#version 420

// original https://www.shadertoy.com/view/WlXyR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 o = glFragColor;
    vec3 u = vec3(U/resolution.xy,resolution.y)*4.;
    for(float i=0.;i++<6.;)
        u.x+=sin(u.z+time*.2),
        u.y+=cos(u.x+time*.2),
        o=max(o*.95,cos(2.*dot(u,u)*i*.1+vec4(.3,.1,0,0)));
    glFragColor = o;
}
