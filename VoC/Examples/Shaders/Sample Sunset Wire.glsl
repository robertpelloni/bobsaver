#version 420

// original https://www.shadertoy.com/view/3lKBDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 4.1414)) * 41253.12356)) * 2.0 - 1.0;
}

vec2 rand2(vec2 p) {
    return normalize(vec2(rand(p + 2.0), rand(p + 5.0))) * rand(p + 4.0);
}

vec3 rand3(vec2 p) {
    return normalize(vec3(rand(p + 0.0), rand(p + 1.0), rand(p + 2.0))) * rand(p + 4.0);
}

vec4 getrect(vec2 pos, vec3 alb) {
    vec4 col = vec4(1.0);
    float tm = 1.14 + time * 0.01;
    for(int i = 0 ; i < 64; i++) {
        float k = float(i + 123);
        vec2 p = vec2(cos(k * 1.4 + tm), sin(2.4 * k + tm)) * vec2(1.717, 1.0);
        p -= pos;
        float s = 0.0125;

        p *= (1.0 - dot(p * 0.18, p));
        if(abs(p.x) < s && abs(p.y) < s) {
            col *= vec4(alb, 0.0);
            break;
        }

        pos = pos.yx;
    }
    return col;
}

void main(void)
{
    vec2 uv = ( 2.0 * gl_FragCoord.xy - resolution.xy ) / min(resolution.x, resolution.y);
    vec3 col = vec3(0.0);
    for(int i = 0 ; i < 32; i++) {
        float k = (float(i) / 32.0) * 3.141592 * 2.0;
        vec2 dir = vec2(cos(k), sin(k));
        vec2 uvs = uv + dir * 0.005;
        vec2 uvc = uv + dir * 0.001;
        vec3 bc = vec3(1,2,3);
        vec4 s = getrect(uvs + vec2(0.05) * vec2(-1,1), bc * 0.05);
        vec4 c = getrect(uvc, bc * 0.3);
        if(s.w == 0.0 && c.w == 1.0)
            c = s;
        col += c.xyz;
    }
    col /= 32.0;
    float v = 1.0 - abs(uv.x / 2.0) * 0.25;
    col *= v;
    if(true)
    {
        col *= vec3(3,2,1) * v;
        col *= 0.5;
    }

    glFragColor = vec4(col + abs(rand3(uv)) * 0.1, 1.0);
}
