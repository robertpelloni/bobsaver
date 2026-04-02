#version 420

// original https://neort.io/art/c28l5d43p9f8s59b8vog

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float pi = acos(-1.);

mat2 rotate(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float random1d2d(vec2 n){
    return fract(sin(dot(n, vec2(22.234, 12.44512)))*81276.212);
}

float random1d1d(float n){
    return fract(sin(n*234.12)*1276.212)*2.0 - 1.0;
}

float hex(vec2 uv){
    uv = abs(uv);
    float c = dot(uv, normalize(vec2(1.0, sqrt(3.0))));
    c = max(c, uv.x);
    return c;
}

vec3 lattice(vec2 uv, float s, float tSeed, float tCoef){
    vec3 color = vec3(0.0);
    uv *= s;

    vec2 r = vec2(1.0, 1.0);
    vec2 h = r * 0.5;

    vec2 a = mod(uv, r)-h;
    vec2 b = mod(uv-h, r)-h;

    vec2 fPos = (length(a) < length(b)) ? a : b;

    vec2 iPos = uv - fPos;
    float angle = atan(uv.x, uv.y);

    color += smoothstep(0.05, 0.01, sin(hex(fPos)+length(iPos)-(time+tSeed+angle)*tCoef));

    return color;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    color += lattice(uv, 12.0, -0.05, 5.0) * vec3(1.0, 0.0, 0.0);
    color += lattice(uv, 12.0, 0.0, 5.0) * vec3(0.0, 1.0, 0.0);
    color += lattice(uv, 12.0, 0.05, 5.0) * vec3(0.0, 0.0, 1.0);

    color *= abs(0.2/sin(length(uv*10.0)+time*2.0));
    color = pow(color, vec3(4.0));

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    vec2 texUv = vec2(gl_FragCoord.xy/resolution);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0)+texture2D(backbuffer, texUv)*0.9;
}
