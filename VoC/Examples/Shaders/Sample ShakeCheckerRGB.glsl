#version 420

// original https://neort.io/art/cbj8a6k3p9f2v73usor0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

float pi = acos(-1.0);
float twopi = pi * 2.0;

float bounceOut(float t) {
    const float a = 4.0 / 11.0;
    const float b = 8.0 / 11.0;
    const float c = 9.0 / 10.0;
    
    const float ca = 4356.0 / 361.0;
    const float cb = 35442.0 / 1805.0;
    const float cc = 16061.0 / 1805.0;
    
    float t2 = t * t;
    
    return t < a
        ? 7.5625 * t2
        : t < b
        ? 9.075 * t2 - 9.9 * t + 3.4
        : t < c
        ? ca * t2 - cb * t + cc
        : 10.8 * t * t - 20.52 * t + 10.72;
}

float linearStep(float start, float end, float t){
    return clamp((t - start) / (end - start), 0.0, 1.0);
}

vec3 latticeTex(vec2 uv){
    vec3 col = vec3(0.0);
    float checker = mod(floor(uv.x) + floor(uv.y), 2.0);

    col += checker;
    return col;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    uv *= 12.0; 
    float ft = fract((time * 2.2 - length(uv * 0.8) * 0.22) * 0.25);  // 0 ~ 1
    float tR = linearStep(0.1, 0.4, ft);
    float tG = linearStep(0.2, 0.5, ft);
    float tB = linearStep(0.3, 0.6, ft);

    float tRT = bounceOut(tR) * twopi;
    float tGT = bounceOut(tG) * twopi;
    float tBT = bounceOut(tB) * twopi;

    color.r += latticeTex(uv - vec2(sin(tRT) * 0.4)).r;
    color.g += latticeTex(uv - vec2(sin(tGT) * 0.4)).g;
    color.b += latticeTex(uv - vec2(sin(tBT) * 0.4)).b;

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
