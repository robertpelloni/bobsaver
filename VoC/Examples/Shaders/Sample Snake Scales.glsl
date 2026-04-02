#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tt3SDf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SIZE 15.0
#define COL1 vec3(32, 43, 51) / 255.0
#define COL2 vec3(235, 241, 245) / 255.0

#define SF 1. / min(resolution.x, resolution.y) * SIZE * .5
#define SS(l, s) smoothstep(SF, -SF, l - s)

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy * 0.5) / resolution.x;
    float ssf = SF * resolution.y * .004;

    uv *= SIZE;
    vec2 id = floor(uv);
    uv = fract(uv) - 0.5;

    float mask = 0.0;
    float rmask = 0.0;

    for (int k = 0; k < 9; k++) {
        vec2 P = vec2(k % 3, k / 3) - 1.;
        vec2 rid = id - P;
        vec2 ruv = uv + P + vec2(0, mod(rid, 2.) * .5) + vec2(0, sin(time * 2. + rid.x * 5. + rid.y * 100.) * .2);

        float l = length(ruv);

        float d = SS(l, .75) * (ruv.y + 1.);

        mask = max(mask, d);
        if (d >= mask) {
            mask = d;
            rmask = SS(abs(l - .65), SF * resolution.y * .007);
        }
    }

    vec3 col = mix(COL1, COL2, rmask);

    glFragColor = vec4(col, 1.0);
}
