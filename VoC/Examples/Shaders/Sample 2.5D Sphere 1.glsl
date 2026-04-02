#version 420

// original https://www.shadertoy.com/view/sttSDn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define pi 3.14159

float thc(float a, float b) {
    return tanh(a * cos(b)) / tanh(a);
}

float ths(float a, float b) {
    return tanh(a * sin(b)) / tanh(a);
}

vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

float h21 (vec2 a) {
    return fract(sin(dot(a.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

const float num = 32.;

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/resolution.y;

    float r = 0.35 + 0.13 * thc(3.5, 8. * length(uv) - 1.5 * time);
    //float r = 0.35 + 0.13 * thc(3.5, time + 10. * h21(uv));
    vec2 p;
    float s = 0.;
    for (float i = 0.; i < num; i++) {
        p = vec2(r * sin(pi * i / num) * cos(i + time), -r + 2. * r * i / num);
        vec2 uv2 = uv;

        float d = 4. * length(uv2 - p);
        float R = r * sin(pi * i / num);
        float k = 0.1 + 0. * cos(10. * i + time) + 0.2 * R;
        s += smoothstep(-k, k, 0.5 * R * (1. + sin(i + time))-d);
        s += step(d, 0.4 * R * (1. + sin(i + time))) - step(d, 0.35 * R * (1. + sin(i + time)));
        s *= 0.99 * (1. - 0.22 * length(uv));
       // s += 0.28 * max(s,smoothstep(-0.2,0.5, 0.5 * R * (1. + sin(i + time))-d));
    }
    
    vec3 col = vec3(s);
    col = s * pal(s, vec3(1.), vec3(1.), vec3(1.), length(uv) + 0.35 * vec3(0.,0.33,0.66));
    col += vec3(0.025,0.,0.05);
   // Output to screen
    glFragColor = vec4(col,1.0);
}
