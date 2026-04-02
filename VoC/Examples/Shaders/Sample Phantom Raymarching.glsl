#version 420

// original https://www.shadertoy.com/view/7l3SWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

const float pi = acos(-1.0);
const float pi2 = pi*2.0;

vec2 pmod(vec2 p, float r) {
    float a = atan(p.x, p.y) + pi/r;
    float n = pi2 / r;
    a = floor(a/n)*n*sin(time*0.01);
    return p*(rot(-a));
}

float box( vec3 p, vec3 b ) {
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float ifsBox(vec3 p) {
    for (int i=0; i<5; i++) {
        p = abs(p) - 1.0;
        p.xy *= rot(time*0.3);
        p.xz *= rot(time*0.1);
    }
    p.xz *= rot(time);
    return box(p, vec3(0.4,0.8,0.3));
}

float map(vec3 p, vec3 cPos) {
    vec3 p1 = p;
    p1.x = mod(p1.x-5., 10.) - 5.;
    p1.y = mod(p1.y-5., 10.) - 5.;
    p1.z = mod(p1.z, 32.)-16.;
    p1.xy = pmod(p1.xy, 5.0);
    return ifsBox(p1);
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    vec3 cPos = vec3(0.0,0.0, sin(time)*0.1);
    vec3 cDir = normalize(vec3(0.0, 0.0, -1.0));
    vec3 cUp  = vec3(0., 1.0, 0.0);//sin(time) in x for spin
    vec3 cSide = cross(cDir, cUp);

    vec3 ray = normalize(cSide * p.x + cUp * p.y + cDir);

    float acc = 0.;
    float acc2 = 0.0;
    float t = 0.0;
    for (int i = 0; i < 60; i++) {
        vec3 pos = cPos + ray * t;
        float dist = map(pos, cPos);
        dist = max(abs(dist), 0.014);
        float a = exp(-dist*7.0);
        if (mod(length(pos)+22.0*time, 30.0) < 2.0) {
            a *= 1.6;
            acc2 += a;
        }
        acc += fract(a*1.2);
        t += dist * 0.7;
    }

    vec3 col = vec3(acc * 0.01, acc * 0.011 + acc2*0.007, acc * 0.013+ acc2*0.006);
    glFragColor = vec4(col, 1.0 - t * .5);
}
