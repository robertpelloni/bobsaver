#version 420

// original https://www.shadertoy.com/view/Wl3GzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI radians(180.)

float rand(vec3 p) {
    return fract(sin(dot(sin(p), vec3(12.9898, 78.233, 37.719))) * 143758.5453);
}

float noise(vec3 p, float scale) {
    vec3 ps = p * scale;
    vec3 id = floor(ps);
    vec3 q = smoothstep(0., 1., fract(ps));
    vec2 e = vec2(1., 0.);
    
    float n1 = smoothstep(0., 1., mix(rand(id), rand(id + e.xyy), q.x));
    float n2 = smoothstep(0., 1., mix(rand(id + e.yyx), rand(id + e.xyx), q.x));
    float n3 = smoothstep(0., 1., mix(rand(id + e.yxy), rand(id + e.xxy), q.x));
    float n4 = smoothstep(0., 1., mix(rand(id + e.yxx), rand(id + e.xxx), q.x)); 
    float n12 = smoothstep(0., 1., mix(n1, n2, q.z));
    float n34 = smoothstep(0., 1., mix(n3, n4, q.z));
    
    return smoothstep(0., 1., mix(n12, n34, q.y));
}

mat3 rot(float a, float b, float g) {
    float ca = cos(a);
    float sa = sin(a);
    float cb = cos(b);
    float sb = sin(b);
    float cg = cos(g);
    float sg = sin(g);
    mat3 ma = mat3(ca, sa, 0., -sa, ca, 0., 0., 0., 1.);
    mat3 mb = mat3(cb, 0., sb, 0., 1., 0., -sb, 0., cb);
    mat3 mg = mat3(1., 0., 0., 0., cg, sg, 0, -sg, cg);
    return ma * mb * mg;
}

float snoise(vec3 p, float scale, float steps) {
    float s = 0., sk = 0.; 
    for (float i = 0.; i < steps; i++) {
        float k = pow(2., i);
        s += noise(p, scale * k) / k;
        sk += 1. / k;
        float a = 2. * PI * (i + 1.) / steps;
        p *= rot(a, a, a);
    } 
    return smoothstep(0., 1., s / sk);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;    
    float n = snoise(vec3(uv, time * 0.035), 8., 32.);
    vec3 col = vec3(n);
    
    glFragColor = vec4(col,1.0);
}
