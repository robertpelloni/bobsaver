#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/wsyGDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERATIONS 25
#define time (mod((.4*time), 2.*3.14159265))

vec2 rot(vec2 p, float t) {
    return mat2(cos(t), -sin(t), sin(t), cos(t)) * p;
}

float yinYang(vec2 p)
{
    for (int i = 0; i < ITERATIONS + 1; ++i) {
        p = rot(p, time*(i % 2 == 1 ? 1. : -2.));

        float yin = p.y > 0.
            ? 1.
            : 0.;

        vec2 p1 = p.y > 0.
            ? p-vec2(0,.5)
            : p+vec2(0,.5);

        float d = length(p1);

        if (d < .5) {
            if (i >= ITERATIONS) {
                if (d < .2) return 1. - yin;
                return yin;
            }
            p = 2.*p1;
            continue;
        }
    
        return p.x > 0. ? 1. : 0.;
    }
}

vec2 cam()
{
    vec2 p = vec2(0, .5);
    vec2 o = vec2(0);
    
    for (int i = 0; i < ITERATIONS; ++i) {
        p = rot(p, -time*(i % 2 == 1 ? 1. : -2.));
        o += p;
        p /= -2.;
    }

    return o;
}

vec2 getUV(vec2 c, vec2 gl_FragCoord, vec2 d)
{  
    vec2 uv = (gl_FragCoord.xy + .5*d)/resolution.yy - vec2(.5*resolution.x/resolution.y,.5);
    uv = rot(uv, 3.14159/2.);    
    uv /= pow(3., 1.+time);
    uv += c;
    return uv;
}

void main(void)
{
    vec2 c = cam();
    
    float sampleA = yinYang(getUV(c, gl_FragCoord.xy, vec2(-.75, .25)));
    float sampleB = yinYang(getUV(c, gl_FragCoord.xy, vec2(-.25,-.75)));
    float sampleC = yinYang(getUV(c, gl_FragCoord.xy, vec2( .25, .75)));
    float sampleD = yinYang(getUV(c, gl_FragCoord.xy, vec2( .75,-.25)));
    float aa = .25*(sampleA + sampleB + sampleC + sampleD);

    glFragColor = vec4(aa);
}
