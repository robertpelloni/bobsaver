#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/llGcD3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 rand(vec3 xyz) {
    return fract(vec3(sin(dot(xyz, vec3(43.238, 27.874, 57.982))),
                      sin(dot(xyz, vec3(91.922, 11.838, 77.133))),
                      sin(dot(xyz, vec3(43.238, 27.874, 57.982))))*
                 vec3(9283.9502,8329.9128,3201.1984));
}

vec3 curp(vec3 v0, float t, vec3 v1) {
    t = t * t * (3.0 - 2.0 * t);
    return mix(v0, v1, t);
}

vec3 lerp(vec3 v0, float t, vec3 v1) {
    return mix(v0, v1, t);
}

vec3 noise(vec3 xyz) {
    vec3 v0 = floor(xyz);
    vec3 f = xyz - v0;
    return
      curp(curp(lerp(rand(v0),               f.z, rand(v0 + vec3(0,0,1))),
                f.y,
                lerp(rand(v0 + vec3(0,1,0)), f.z, rand(v0 + vec3(0,1,1)))),
           f.x,
           curp(lerp(rand(v0 + vec3(1,0,0)), f.z, rand(v0 + vec3(1,0,1))),
                f.y,
                lerp(rand(v0 + vec3(1,1,0)), f.z, rand(v0 + vec3(1,1,1)))));
}

vec3 simplex(vec3 xyz, int octaves) {
    float a = 1.0;
    vec3 result = vec3(0);
    for (int o = 1 << octaves; o > 0; o >>= 1, a /= 2.) {
        result += (2. * noise(xyz / float(o)) - 1.) * a;
    }
    return result;
}
        

void main(void) {
    vec2 uv = gl_FragCoord.xy/resolution.x - vec2(0.5, 0.5 * resolution.y / resolution.x);
    vec3 per = simplex(vec3(uv * 120., time * 2.), 5);
    float a = dot(normalize(per), normalize(vec3(uv, 0.1)));
    a = 1. * pow(a, 5.);
    glFragColor.rgb = vec3(a) * 1.;
    glFragColor.a = 1.0;
}
