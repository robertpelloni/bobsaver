// https://www.shadertoy.com/view/ll2GWc

#version 400

uniform vec2 resolution;
uniform sampler2D image;

out vec4 glFragColor;

// by Nikos Papadopoulos, 4rknova / 2015
// WTFPL

#define THRESHOLD vec3(1.,.92,.1)

vec3 texsample(in vec2 uv)
{
    return texture(image, uv).xyz;
}

vec3 texfilter(in vec2 uv)
{
    vec3 val = texsample(uv);
    if (val.x < THRESHOLD.x) val.x = 1. - val.x;
    if (val.y < THRESHOLD.y) val.y = 1. - val.y;
    if (val.z < THRESHOLD.z) val.z = 1. - val.z;
	return val;
}

void main()
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    glFragColor = vec4(texfilter(uv)*0.9, 1);
}