#version 420

// original https://neort.io/art/c0jumss3p9f5tuggjacg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

mat2 rotate(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float random(float n){
    return fract(sin(n * 35.124) * 5325.12);
}

float repeat(float p, float repCoef){
    return (fract(p/repCoef - 0.5) - 0.5) * repCoef;
}

vec3 hsv2rgb(float h, float s, float v){
    vec3 rgb = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    rgb = rgb * rgb * (3.0 - 2.0 * rgb);
    return v * mix(vec3(1.0), rgb, s);
}

float sdLine(vec2 p, vec2 a, vec2 b){
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

vec3 leaf(vec2 p, float len, float seed, float rotCoef){
    p -= vec2(0.0, -len * 1.8);
    p *= rotate(sin(time + seed) * length(p) * rotCoef);
    p += vec2(0.0, -len);
    float sdLeaf = sdLine(p, vec2(0.0, 0.0), vec2(0.0, -len));
    vec3 leaf = step(sdLeaf, abs(sin(p.y * 0.5)) * 0.22) * hsv2rgb(0.3 * abs(sin(p.y * 0.7)) + 0.18, 1.0, 1.0);

    return leaf;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    for(float i = 0.0; i <= 1.0; i += 0.1){
        vec2 uv2 = uv + vec2(0.2 * i + 10.0, 0.1);
        vec2 p = vec2(repeat(uv2.x, 0.1 + 0.1+i/3.0), uv2.y - i);
        color += leaf(p, 0.6, p.x + i/10.0, 0.3 * uv2.x * 0.1 + (random(i) * 2.0 - 1.0) * 0.3);
    }
    color += mix(vec3(0.3765, 0.8667, 0.051), vec3(0.0, 0.5686, 0.898), uv.y);

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
