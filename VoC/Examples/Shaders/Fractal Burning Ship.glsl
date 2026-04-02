#version 420

// Created by Jetro Lauha (tonic) 2014
// Based on Mandelbrot shadertoy by Iñigo Quilez (iq)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// original https://www.shadertoy.com/view/ls23RG

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    vec2 sp = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
    sp.x *= resolution.x/resolution.y;

    // 0.29 ... 1.1
    float zoo = 0.695 + 0.405 * cos(0.1 * time);
    float coa = 1.0;
    float sia = 0.0;
    zoo = pow(zoo, 8.0);
    vec2 cc = vec2(1.77831, 0.056095) + sp*zoo;

    float co = 0.0;

    vec2 p = vec2(0.0, 0.0);
    vec2 n = vec2(0.0, 0.0);

    for (int i = 0; i < 256; i++)
    {
        if (p.x + p.y < 2.0)
        {
            n.x = p.x * p.x - p.y * p.y - cc.x;
            n.y = 2.0 * abs(p.x * p.y) - cc.y;
            p = n;
            co += 2.0;
        }
    }

    co = sqrt(co / 256.0);
    glFragColor = vec4(0.5 + 0.5 * cos(6.2831 * co + 0.0),
                        0.5 + 0.5 * cos(6.2831 * co + 0.4),
                        0.5 + 0.5 * cos(6.2831 * co + 0.7),
                        1.0);
}
