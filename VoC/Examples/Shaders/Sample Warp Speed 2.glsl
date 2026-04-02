#version 420

// original https://www.shadertoy.com/view/4tjSDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 'Warp Speed 2'
// David Hoskins 2015.
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// Fork of:-   https://www.shadertoy.com/view/Msl3WH
//----------------------------------------------------------------------------------------

void main(void)
{
    float s = 0.0, v = 0.0;
    vec2 uv = (gl_FragCoord.xy / resolution.xy) * 2.0 - 1.0;
    float time = (time+20.)*60.0;
    vec3 col = vec3(0);
    vec3 init = vec3(sin(time * .001)+.25, 0.1 + cos(time * .0007), time * 0.002);
    for (int r = 0; r < 100; r++) 
    {
        vec3 p = init + s * vec3(uv, 0.05);
        p.z = fract(p.z);
        for (int i=0; i < 10; i++)    p = abs(p * 2.04) / dot(p, p) - .9;
        v += pow(dot(p, p), .7) * .08;
        col +=  vec3(v * 0.2+.1, 12.-s*4., .1 + v * 1.) * v * 0.00005;
        s += .02;
    }
    glFragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
