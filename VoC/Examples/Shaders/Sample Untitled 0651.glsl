#version 420

// original https://www.shadertoy.com/view/ssV3zy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec4 p=vec4((gl_FragCoord.xy/4e2),1,-4);
    for(int i=0;i<9;++i)p+=vec4(sin(-(p.x+time*.2))+atan(p.y*p.w),cos(-p.x)+atan(p.z*p.w),cos(-(p.x+sin(time*.8)))+atan(p.z*p.w),0);
    glFragColor=p;
}
