#version 420

// original https://www.shadertoy.com/view/MssBWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    glFragColor += 1.-fract((gl_FragCoord.y*.02+gl_FragCoord.x*.4)*fract(gl_FragCoord.x*.61)+time)*7.-glFragColor;
}
