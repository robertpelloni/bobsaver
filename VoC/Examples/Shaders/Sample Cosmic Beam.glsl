#version 420

// original https://www.shadertoy.com/view/WsScRR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float time = (time+29.) * 60.0;

    float s = 0.0, v = 0.0;
    vec2 uv = (-resolution.xy + 7.0 * gl_FragCoord.xy ) / resolution.y;
    float t = time*0.111;
    uv.x += sin(t) * 0.5;
    float si = sin(t + 3.17); // ...Squiffy rotation matrix!
    float co = cos(t);
    uv *= mat2(co, si, -si, co);
    vec3 col = vec3(0.0);
    vec3 init = vec3(0.25, 0.25 + sin(time * 0.001) * 0.4, floor(time) * 0.0008);
    for (int r = 0; r < 100; r++) 
    {
        vec3 p = init + s * vec3(uv, 0.143);
        p.z = mod(p.z, 3.0);
        for (int i=0; i < 10; i++)    p = abs(p * 2.04) / dot(p, p) - 0.75;
        v += length(p * p) * smoothstep(0.0, 0.5, 0.9 - s) * .002;
        // Get a purple and cyan effect by biasing the RGB in different ways...
        col +=  vec3(v * 5.8, 5.1 - s * 2.5, .7 + v * 0.5) * v * 0.013;
        s += .01;
    }
    glFragColor = vec4(col, 3.0);
}
