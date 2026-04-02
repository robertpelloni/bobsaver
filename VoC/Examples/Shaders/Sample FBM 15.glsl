#version 420

// original https://www.shadertoy.com/view/3syfzd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 random3(vec3 st){
    mat3 A = mat3(
        vec3(127.1, 251.1, 311.2),
        vec3(134.3, 321.5, 231.5),
        vec3(227.2, 141.3, 151.6)
    );

    st = A * st;
    return 2.0 * fract(sin(st) * 43758.0) - 1.0;
}

#define L 3.0
float dotRandOffset(in vec3 i, vec3 f, vec3 pos) {
    i += pos;
    i = vec3(i.xy, mod(i.z, L));
    return dot( random3(i), f - pos );
}

float noise(vec3 st) {
    vec3 i = floor(st);
    vec3 f = fract(st);
    
    // Polynomial Interpolation
    vec3 u = f * f * (3.0 - 2.0 * f);
    u = f * f * f * (f * (6.0 * f - 15.0) + 10.0);

    return mix( mix( mix( dotRandOffset(i, f, vec3(0.0, 0.0, 0.0)),
                          dotRandOffset(i, f, vec3(1.0, 0.0, 0.0)), u.x),
                     mix( dotRandOffset(i, f, vec3(0.0, 1.0, 0.0)),
                          dotRandOffset(i, f, vec3(1.0, 1.0, 0.0)), u.x), u.y),
                mix( mix( dotRandOffset(i, f, vec3(0.0, 0.0, 1.0)),
                          dotRandOffset(i, f, vec3(1.0, 0.0, 1.0)), u.x),
                     mix( dotRandOffset(i, f, vec3(0.0, 1.0, 1.0)),
                          dotRandOffset(i, f, vec3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
}

#define OCTAVES 8
float fBM(in vec3 st) {
    float value = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < OCTAVES; i++) {
        st += vec3(0.0, 0.0, 0.0);
        value += amplitude * noise(st);
        st *= vec3(2.0, 2.0, 1.0);
        amplitude *= 0.5;
    }
    return value;
}

vec3 distort3D(in vec3 p, mat3 A){
    return vec3(
            fBM(p + A[0]),
            fBM(p + A[1]),
            fBM(p + A[2])
            );
}

float pattern(in vec3 p, out vec3 r, out vec3 s, out vec3 t) {
    float v = .0;
    mat3 A = mat3(
        vec3(5.1, -2.4, 4.0),
        vec3(1.0, 1.4, -12.0),
        vec3(22.0, 111.0, 1.0)
    );
    mat3 B = mat3(
        vec3(-10.0, 0.0, 2.0),
        vec3(-8.1, 20.4, 1.0),
        vec3(2.6, 3.0, 0.2)
    );

    r = distort3D(p, B);
    s = distort3D(r * 2.5 + p, A);
    t = distort3D(s * 2.0 - r + p, B);

    v = fBM(t * 2.0 + r + s + p);
    return v;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.x;
    vec3 uvw = vec3(uv * 4.0, time * .5);

    vec3 r = vec3(0.0);
    vec3 s = vec3(0.0);
    vec3 t = vec3(0.0);

    float v = pattern(uvw, r, s, t);

    vec3 col = vec3(mix(s, t, v))*1.3+0.4;

    glFragColor = vec4(col,1.0);
}
