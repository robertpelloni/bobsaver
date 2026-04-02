#version 420

// original https://neort.io/art/c89p5ns3p9f5abd6m3e0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define COLOR_N vec3(0.15, 0.34, 0.6)
#define COLOR_T vec3(0.313, 0.816, 0.816)
#define COLOR_M vec3(0.745, 0.118, 0.243)
#define COLOR_K vec3(0.475, 0.404, 0.765)
#define COLOR_H vec3(1.0, 0.776, 0.224)
#define COLOR_S vec3(0.682, 0.706, 0.612)

float pi = acos(-1.0);
float pi2 = pi * 2.0;

float random1d1d(float n){
    return sin(n) * 21422.214122;
}

float random(vec3 v) { 
    return fract(sin(dot(v, vec3(12.9898, 78.233, 19.8321))) * 43758.5453);
}

float valueNoise(vec3 v) {
    vec3 i = floor(v);
    vec3 f = smoothstep(0.0, 1.0, fract(v));
    return  mix(
        mix(
            mix(random(i), random(i + vec3(1.0, 0.0, 0.0)), f.x),
            mix(random(i + vec3(0.0, 1.0, 0.0)), random(i + vec3(1.0, 1.0, 0.0)), f.x),
            f.y
        ),
        mix(
            mix(random(i + vec3(0.0, 0.0, 1.0)), random(i + vec3(1.0, 0.0, 1.0)), f.x),
            mix(random(i + vec3(0.0, 1.0, 1.0)), random(i + vec3(1.0, 1.0, 1.0)), f.x),
            f.y
        ),
        f.z
    );
}

float fbm(vec3 v) {
    float n = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        n += a * valueNoise(v);
        v *= 2.0;
        a *= 0.5;
    }
    return n;
}

float orb(vec2 p, float r){
    return r / length(abs(p));
}

vec3 skyTexture(vec2 uv, float size){
    vec2 uv2 = uv * size;
    vec3 col = vec3(0.0);

    vec3 noiseCol = pow(vec3(fbm(vec3(uv2 + vec2(time*0.1, 0.0), 122.2))), vec3(2.0));
    noiseCol += pow(vec3(fbm(vec3(uv2 + vec2(time*0.2, 0.0), 422.2))), vec3(3.2));
    noiseCol += pow(vec3(fbm(vec3(uv2 + vec2(time*0.3, 0.0), 522.2))), vec3(4.0));
    noiseCol += pow(vec3(fbm(vec3(uv2 + vec2(time*0.4, 0.0), 622.2))), vec3(7.0));
    noiseCol += pow(vec3(fbm(vec3(uv2 + vec2(time*0.5, 0.0), 722.2))), vec3(9.0));

    col += mix(COLOR_N, vec3(1.0), pow(noiseCol, vec3(3.0)));

    return col;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);
    color += mix(skyTexture(uv, 3.0), vec3(0.8863, 0.8196, 0.8196), orb(uv - vec2(1.0, 0.7), 0.2 + 0.03 * sin(time * 6.0)));
    
    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
