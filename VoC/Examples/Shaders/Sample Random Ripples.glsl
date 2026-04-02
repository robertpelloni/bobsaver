#version 420

// original https://www.shadertoy.com/view/3dj3zV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI  3.141592653589793238462643383279

vec2 cmult(vec2 a, vec2 b) {
    return vec2(dot(a, b * vec2(1.,-1.)), dot(a, b.yx));
}
vec4 qmult(vec4 a, vec4 b) {
    return vec4(
        a.x * b.x - dot(a.yzw, b.yzw),
        a.x * b.yzw + b.x * a.yzw + cross(a.yzw, b.yzw)
    );
}

float randa(float v) {
    return fract(sin(v * 12.) * 1000. + PI);
}
float randb(float v) {
    return fract(sin(v * 9.) * 987. + 2. * PI);
}
vec2 randab(float v) {
    return vec2(randa(v),randb(v));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x;
    
    float t = time * 5.;
    int s = int(floor(t));
    #define NUMPOINTS 200
    float np = float(NUMPOINTS);
    vec3 col = vec3(0);
    for(int i = 0; i < NUMPOINTS; i++) {
        int n = s - i;
        //n = 0;
        vec3 point = vec3(
            randab(sqrt(2.)*float(n)) * (resolution.xy / resolution.x),
            t - float(n)
        );
        float d = distance(uv, point.xy);
        for(float ix = -1.; ix < 1.5; ix++)
            for(float iy = -1.; iy < 1.5; iy++) {
                d = min(d, distance(uv + vec2(ix,iy), point.xy));
            }
        float l = point.z - 20. * d;
        float amplitude = clamp(
            (2. - l) * l * exp(1. - l),
            0., 1.
        ) * clamp(1. - d / .5, 0., 1.);
        col += cos(7.5 * l) * amplitude;
    }

    col = col * .5 + .5;
    glFragColor = vec4(col,1.0);
}
