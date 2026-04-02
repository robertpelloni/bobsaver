#version 420

// original https://www.shadertoy.com/view/ttVfz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//original - http://glslsandbox.com/e#71176.0
//This is only a remix
const float Radius = 1.; // cell radius
const float Bounds = 1.; // round number, adjust this to accomodate Radius

// hash without sine
// https://www.shadertoy.com/view/4djSRW
#define MOD3 vec3(443.8975, 397.2973, 491.1871)
float hash12(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}
vec3 hash33(vec3 p3) {
    p3 = fract(p3 * MOD3);
    p3 += dot(p3, p3.yxz+23.47);
    return fract(vec3((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y, (p3.y+p3.z)*p3.x));
}

// map offset and value
vec3 mapOV(vec2 p, vec2 o, float z) {
    return
        mix(
            hash33(vec3(floor(p)-o, floor(z)-1.)),
            hash33(vec3(floor(p)-o, floor(z))),
            smoothstep(0., 1., fract(z))
        );
}

float map(vec2 p) {
    float f = 0.;
    for(float y=-Bounds; y<=Bounds; y++) {
        for(float x=-Bounds; x<=Bounds; x++) {
            float t = time + hash12(floor(p)-vec2(x, y));
            vec3 ov = mapOV(p, vec2(x, y), t);
            float cell = 1. - length(fract(p)-ov.xy+vec2(x, y)) / Radius;
            f = max(f, cell * ov.z);
        }
    }
    return f;
}

mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

void main(void)
{
    vec2 res = resolution.xy;
    vec2 p = 8.*(2.+sin(time/9.))*(gl_FragCoord.xy-res/2.)/res.y;
    p.x+=49.*sin(time/9.);
    p.y+=39.*cos(time/7.);
    p*=rotate(time/6.);
    glFragColor = vec4(mix(
                        .7-vec3(.9), 
                        1.3-vec3(
                            abs(cos(time/2.)), 
                            1.-abs(cos(time/3.)), 
                            abs(sin(time/4.))),
                          map(p)), 1.);
}
