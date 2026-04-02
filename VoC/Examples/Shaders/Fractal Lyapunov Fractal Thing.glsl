#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tddGDB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int pattern[] = int[](1,1,0,0,1,1,1,1,0);

void main(void)
{
    vec2 pos = (gl_FragCoord.xy - resolution.xy * .5) / resolution.y + .5;
    if(any(lessThan(pos, vec2(0.))) || any(greaterThanEqual(pos, vec2(1.)))) {
        glFragColor = vec4(.2);
        return;
    }
    pos *= 2.;
    pos += 2.;
    float x = .314;
    float sa = 1.;
    float sb = 0.;
    for(int i = 0; i < 32; i++) {
        float a = pos[pattern[i % pattern.length()]];
        sa *= abs(a * (1. - 2. * x));
        //     if(sa >    256.) {sa /= 256.; sb += 8.;}
        //else if(sa < 1./256.) {sa *= 256.; sb -= 8.;}
        x = a * x * (1. - x);
    }
    glFragColor = vec4(sin((log2(sa) + sb) * .1) * .5 + .5);
}
