#version 420

// original https://www.shadertoy.com/view/sdXGW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 barycoords(in vec2 p, in vec2 a, in vec2 b, in vec2 c) {
    vec2 pa = p - a, pb = p - b, pc = p - c;
    vec2 ba = b - a, cb = c - b, ac = a - c;

    float abc = abs(ba.y * ac.x - ba.x * ac.y);
    float abp = abs(ba.x * pa.y - ba.y * pa.x);
    float bcp = abs(cb.x * pb.y - cb.y * pb.x);
    float cap = abs(ac.x * pc.y - ac.y * pc.x);

    return vec3(bcp, cap, abp) / abc;
}

float map(in vec3 p) {
    float c = cos(time), s = sin(time);
    mat2 rot = mat2(c, -s, s, c);

    p.xy *= rot;
    p.xz *= rot;

    //return length(vec2(length(p.xz) - 0.5, p.y)) - 0.25;

    //return length(p) - 0.75;

    vec3 q = abs(p) - 0.5;
    //return max(q.x, max(q.y, q.z));
    return length(max(q, 0.0)) + min(0.0, max(q.x, max(q.y, q.z)));
}

vec3 grad(in vec3 p) {
    vec3 e = vec3(0.001, 0.0, 0.0);
    return normalize(vec3(map(p + e.xyy) - map(p - e.xyy),
                          map(p + e.yxy) - map(p - e.yxy),
                          map(p + e.yyx) - map(p - e.yyx)));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    float unit = 2.0 / resolution.y;

    vec2 a = vec2(-0.5, -0.5);
    vec2 b = vec2( 0.5, -0.5);
    vec2 c = vec2( 0.0,  1.0);

    vec3 uvw = barycoords(uv, a, b, c);
    glFragColor = vec4(grad(uvw), 1.0);
    //glFragColor = vec4(smoothstep(unit, 0.0, map(uvw)));
}
