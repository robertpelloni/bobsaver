#version 420

// original https://www.shadertoy.com/view/MdtGWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//Based off of https://www.shadertoy.com/view/lslGWr

const int max_iterations = 32;
const vec3 a = vec3(-.5, -.4, -1.5);

float field( vec3 p ) {
    float strength = 5.0;
    float prev = 0.;
    float acc = 0.;
    float tw = 0.;
    for(int i = 0; i < max_iterations; i++) {
        float mag = dot(p, p);
        p = abs(p) / mag + a;
        float w = exp(-float(i) / strength);
        acc += w * exp(-strength * pow(abs(mag - prev), 2.));
        tw += w;
        prev = mag + w;
    }   
    return max(0., acc / tw);
}

void main(void)
{
    vec2 uv = -1. + 2. * gl_FragCoord.xy / resolution.xy;
    vec2 uvs = uv * resolution.xy / max(resolution.x, resolution.y);
    vec2 offset = vec2(sin(time), cos(time));
    //vec2 offset = -1. + 2. * mouse*resolution.xy.xy / resolution.xy;
    
    float frc = 0.;
    for(int i = 0; i < 5; i++){
        frc += field(vec3(uvs, frc) + vec3(2. * offset / float(i + 1), 0.));
    }
    
    glFragColor = vec4(frc * frc * frc, frc * frc, frc, 1.0);
}
