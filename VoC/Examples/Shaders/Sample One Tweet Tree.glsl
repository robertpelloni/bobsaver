#version 420

// original https://www.shadertoy.com/view/XlfGW7

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 p=gl_FragCoord.xy/resolution.y;
    for(int i=0;i<18;++i)
        p=reflect(p,p.yx)*1.1;
    glFragColor=vec4(0,1.-dot(p,p),0,0);
}
