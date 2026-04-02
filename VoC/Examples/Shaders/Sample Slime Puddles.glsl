#version 420

// original https://www.shadertoy.com/view/Ml2Xzc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by randy read - rcread/2015
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//    mod of https://www.shadertoy.com/view/MtjXzc

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy - .5 -time*.1;
    vec3 c = abs(cos(vec3(time*.06,
                  time*.045,
                  time*.015))*2.+2.);
    for (int i = 0; i < 27; i++) {
        vec3 p = vec3(uv*float(i),float(i));
        c += abs( vec3( sin(c.y+sin(p.x)),
                   cos(c.z+sin(p.z)),
                   -sin(c.x+sin(p.y)) ) );
    }
    glFragColor = vec4((c*.04-.66)*3.,1.);
}
