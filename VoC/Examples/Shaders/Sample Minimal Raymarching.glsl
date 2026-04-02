#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3lfcz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time
#define r resolution

//Based on https://twitter.com/yosshin4004/status/1251357672504360966

void main(void)
{
    vec2 U = gl_FragCoord.xy;
    vec4 o = glFragColor;
    vec3 d=vec3(U/r.xy-.5,.5),p=vec3(0,0,t),q;
    for(int i=0;i<99;i++)
    {
        p+=d*(length(sin(p.zxy)-cos(p.xyz))-.5);
        //p+=d*(length(sin(p.zxx)-cos(p.xyz))-.5);
        if(i==95)q=p+=d=vec3(.6);
    }
    ivec3 u=ivec3(q*5e2);
    o+=float((u.x^u.y^u.z)&150)/2e3*length(p-q)+(p.z-t)*.03;
    glFragColor = o;
}
