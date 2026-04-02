#version 420

// original https://www.shadertoy.com/view/wsSGRD

#extension GL_EXT_gpu_shader4 : enable

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define N 300.0
#define TWISTS 106.0

const float tau = atan(1.0)*8.0;

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy) / resolution.y * 1.2;
    
    vec3 col = vec3(0);
    for(int i = 0; i < int(N); i++) {
        float ii = tau * float(i) / N;
        vec3 pos = vec3(
            sin(ii + time/TWISTS),
            cos(ii + time/TWISTS),
            cos(ii*TWISTS + time) + 1.5
        );
        pos.xy += pos.xy*sin(ii*TWISTS + time)/5.0;
        col[i%3] += smoothstep(0.0, 0.5, pos.z*0.002/length(uv-pos.xy));
    }
    glFragColor = vec4(col,1.0);
}
