#version 420

// original https://neort.io/art/c3u0tpc3p9f8s59bht3g

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define D(Q) abs(dot(sin(Q), cos(Q.yzx)))

mat3 rotate3D(float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
}

vec3 hsv(float h, float s, float v) {
    vec4 a = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + a.xyz) * 6.0 - vec3(a.w));
    return v * mix(vec3(a.x), clamp(p - vec3(a.x), 0.0, 1.0), s);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2. - resolution) /min(resolution.x, resolution.y);
    vec3 col = vec3(0);
    
    vec3 P = vec3(0, 0, 2);
    vec3 ray = normalize(vec3(uv, -2.));
    
    float d = 0.;
    float c = 0.;
    for(int i=0; i<99; i++) {
        vec3 Q = P * rotate3D(time, vec3(1));
        d = length(Q) - .8;
        Q *= 10.;
        d = max(d, (D(Q) - .03) / 10.);
        Q *= 10.;
        d = max(d, (D(Q) - .3) / 100.);
        if(d < 1e-4) {
            break;
        }
        P += ray * d * .6;
        c++;
    }
    col += hsv(.3 - length(P), .7, 20./c);
    
    glFragColor = vec4(col, 1.0);
}
