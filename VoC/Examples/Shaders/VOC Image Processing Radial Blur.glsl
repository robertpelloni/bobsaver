// https://www.shadertoy.com/view/ltVSRK

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

// by Nikos Papadopoulos, 4rknova / 2017
// WTFPL

float hash(in vec2 p) { return fract(sin(dot(p,vec2(283.6,127.1))) * 43758.5453);}

#define CENTER vec2(.5)

#define SAMPLES 10
#define RADIUS  .01

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3  res = vec3(0);
    for(int i = 0; i < SAMPLES; ++i) {
        res += texture(image, uv).xyz;
        vec2 d = CENTER-uv;
        uv += d * RADIUS;
    }
    
    glFragColor = vec4(res/float(SAMPLES), 1);
}