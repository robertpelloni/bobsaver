#version 420

// original https://www.shadertoy.com/view/XtyGDR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by evilryu
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

#define PI 3.1415926535

mat3 m_rot(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return mat3( c, s, 0, -s, c, 0, 0, 0, 1);
}
mat3 m_trans(float x, float y)
{
    return mat3(1., 0., 0., 0., 1., 0, -x, -y, 1.);
}
mat3 m_scale(float s)
{
    return mat3(s, 0, 0, 0, s, 0, 0, 0, 1);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 pos = (gl_FragCoord.xy - resolution.xy*.5) / resolution.yy;
   
    pos*=6.0;
    pos.y+=1.9;
       vec3 p = vec3(pos, 1.);
    float d = 1.0;
    float iter = mod(floor(time), 20.0);
    float len = fract(time);
    for(int i = 0; i < 20; ++i)
    {
        if(i<=int(iter))
        {
            d=min(d,(length(max(abs(p.xy)-vec2(0.01,1.0), 0.0)))/p.z);
            p.x=abs(p.x);
            p=m_scale(1.22) * m_rot(0.25*PI) * m_trans(0.,1.) * p;
        }
        else
        {
            d=min(d,(length(max(abs(p.xy)-vec2(0.01,len), 0.0)))/p.z);
        }
    }
    d=smoothstep(0.1, 0.15,d);
    glFragColor = vec4(d,d,d,1.);    
}
