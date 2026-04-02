#version 420

// original https://www.shadertoy.com/view/NlX3zH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    @Title: Pulsing Color Pattern
    @Author: AshishKingdom
*/
void main(void)
{
    float t = time;
    vec2 P = gl_FragCoord.xy;
    P/=resolution.xy;
    vec2 R, S;
    float rad = abs(0.5*sin(t));
    S.x = 0.5+rad*sin(t*3.0);
    S.y = 0.5+rad*cos(t*3.0);
    R.x = abs(sin(t*3.0)*length(P));
    R.y = abs(cos(t*3.0)*length(P));
    glFragColor = vec4(R.x*2.0,length(P-S),R.y,1.0);
}
