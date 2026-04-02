#version 420

// original https://www.shadertoy.com/view/WllyR7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 U=gl_FragCoord.xy;
    vec4 O=vec4(0);
    vec3 u=vec3(2.*U-resolution.xy,resolution.y)*time/5e2;
    for(int i=0;i<2;i++){
        u=cos(u+time*.2)*2.;
        u+=sin(u-time*.2);
        O-=cos(3.*dot(u.xy,u.xy)+vec4(.3,.1,0,0));
    }
    glFragColor=O;
}
