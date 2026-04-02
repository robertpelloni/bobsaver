#version 420

// original https://neort.io/art/bvtak143p9f30ks57ekg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

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

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution)/min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    float x = (fbm(vec3(vec2(uv*5.0), time))) * 2.0 - 1.0;
    float y = (fbm(vec3(vec2(uv*7.0), time*2.0))) * 2.0 - 1.0;
    vec2 pos = vec2(x, y);
    color += 0.025 / length(pos - uv);
    
    x = (fbm(vec3(vec2(uv*6.0), time*2.0))) * 2.0 - 1.0;
    y = (fbm(vec3(vec2(uv*8.0), time))) * 2.0 - 1.0;
    pos = vec2(x, y);
    color += 0.015 / length(pos - uv) * vec3(0.0549, 0.451, 0.9059);

    x = (fbm(vec3(vec2(uv*4.0), time*2.0))) * 2.0 - 1.0;
    y = (fbm(vec3(vec2(uv*9.0), time*2.0))) * 2.0 - 1.0;
    pos = vec2(x, y);
    color += 0.02 / length(pos - uv) * vec3(0.9451, 0.1686, 0.0667);

    glFragColor = vec4(color, 1.0);
}
