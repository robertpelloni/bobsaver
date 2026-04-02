#version 420

// original https://www.shadertoy.com/view/ll2SDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy / resolution.xy-0.5)*5.;
    float an;
    for (int i=0; i<24; i++)
    {
        an =1.+cos(length(uv/=1.6)*5.+time/2.);
        uv += normalize(vec2(-uv.y, uv.x))*an/6.;
        uv = abs(uv*=1.8)-time/20.-2.5;        
    }
    float d=length(uv)*2.;
    glFragColor = normalize(vec4(sin(d),sin(d*1.2),sin(d*1.3),0.1));
}
