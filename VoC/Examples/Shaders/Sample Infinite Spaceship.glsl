#version 420

// original https://www.shadertoy.com/view/tdjcRy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float r0 = sqrt(2.)/2.;
const float r1 = sqrt(2. - sqrt(2.))/2.;
const float a1 = 2.0 * r1;
const float r2 = sqrt(2. + sqrt(2.))/2.;
const mat2 mat45 = mat2(r0, r0, -r0, r0);
const mat2 mat22_5 = mat2(r2, r1, -r1, r2);
const mat2 mat90 = mat2(0, 1, -1, 0);
const vec3 c0 = vec3(.811,.819,.666);
const vec3 c1 = c0 * 0.7;

float box(vec2 r, vec2 p)
{
    return length(max(abs(p) - r, 0.));
}

void tile(out vec4 glFragColor, in vec2 uv)
{
    vec3 c = c0;
    c = mix(vec3(1.0), c, smoothstep(0., 0.01, box(vec2(0.46, 0.1), uv - vec2(0.5, 0.1))));
    c = mix(c1, c, smoothstep(0., 0.01, box(vec2(0.06, 0.32), uv - vec2(0.5, 0.6)) - 0.015));
    c = mix(vec3(0.0), c, smoothstep(0., 0.01, box(vec2(0.06, 0.32), uv - vec2(0.5, 0.6))));
    
    c = mix(c1, c, smoothstep(0., 0.01, box(vec2(0.04, 0.07), uv - vec2(0.32, 0.6)) - 0.015));
    c = mix(vec3(0.9), c, smoothstep(0., 0.01, box(vec2(0.04, 0.07), uv - vec2(0.32, 0.6))));
    
    c = mix(c1 * 0.9, c, smoothstep(0., 0.01, box(vec2(0.004, 0.02), uv - vec2(0.1, 0.9)) - 0.015));
    c = mix(c1 * 0.9, c, smoothstep(0., 0.01, box(vec2(0.004, 0.02), uv - vec2(0.1, 0.3)) - 0.015));
    
    c = mix(c1 * 0.9, c, smoothstep(0., 0.01, box(vec2(0.002, 0.12), uv - vec2(0.95, 0.8)) - 0.001));
    c = mix(c1 * 0.9, c, smoothstep(0., 0.01, box(vec2(0.002, 0.12), uv - vec2(0.95, 0.4)) - 0.001));
    
    glFragColor = vec4(c, 1.0);
}

void map(out vec4 glFragColor, in vec2 uv)
{
    vec3 ro = vec3(0.0, 0.0, -1.0 - time*0.2);
    vec3 rd = normalize(vec3(uv, -1));
    float e = 1. + sqrt(2.);
    vec4 plane = vec4(e, 1.0, 0.0, -e);
    float s = dot(rd, plane.xyz);
    if (s > 0.001) {
        float t = - (plane.w + dot(ro, plane.xyz)) / dot(rd, plane.xyz);
        vec3 q = ro + t * rd;
        q.x = -q.x;
        vec2 st = (mod(-q.xz/a1 + r1, 1.0) - 0.5)/r1 + 0.5;
        st.y *= a1;
        tile(glFragColor, mod(st, 1.0));
        glFragColor *= smoothstep(0.01, 1.0, 1.5 / t);
    }
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = 2. * uv - 1.;
    uv.y *= -resolution.y/resolution.x;
    uv *= mat22_5;
    
    if (uv.x * uv.y < 0.) {
        uv *= mat90;
    }
    if (uv.x < 0. && uv.y < 0.) {
        uv = -uv;
    }
    if (uv.x > 0. && uv.y > 0.) {
        if (uv.y > uv.x) {
           uv *= mat45;
        }
        map(glFragColor, uv);
    }
}
