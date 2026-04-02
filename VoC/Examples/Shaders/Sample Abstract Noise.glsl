#version 420

// original https://www.shadertoy.com/view/st2czd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 150
#define MAX_DIST 20.0
#define MIN_DIST 0.0001

float random1(vec3 p) {
    return (fract(sin((p.x * 12.9898) + (p.y * 78.233) + (p.z * 195.1533)) * 43758.5453123) * 2.0) - 1.0;
}

float smoothNoise1(vec3 p) {
    vec3 i0 = floor(p),
         i1 = i0 + 1.0,
         f = p - i0;

    f *= f * (3.0 - (f * 2.0));

    return mix(mix(mix(random1(vec3(i0.x, i0.y, i0.z)), random1(vec3(i1.x, i0.y, i0.z)), f.x),
                   mix(random1(vec3(i0.x, i1.y, i0.z)), random1(vec3(i1.x, i1.y, i0.z)), f.x), f.y),
               mix(mix(random1(vec3(i0.x, i0.y, i1.z)), random1(vec3(i1.x, i0.y, i1.z)), f.x),
                   mix(random1(vec3(i0.x, i1.y, i1.z)), random1(vec3(i1.x, i1.y, i1.z)), f.x), f.y), f.z);
}

float fractalSmoothNoise1(vec3 p) {
    float y = 0.0;
    
    float amplitude = 0.5;
    float frequency = 1.0;
    
    float gain = 0.5;
    float lacunarity = 2.0;
    for(int i = 0; i < 8; i++) {
        y += smoothNoise1(p * frequency) * amplitude;
        frequency *= lacunarity;
        amplitude *= gain;
    }
    
    return y;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float map(vec3 p) {
    float d = ((fractalSmoothNoise1(p + vec3(0.5)) * 0.5) + 0.5) - 0.3;

    d = max(d, -sdSphere(p - vec3(0.0, 0.0, time * 3.0), 1.0));

    return d;
}

float march(vec3 ro, vec3 rd) {
    float d = 0.0;
    for(int i = 0; i < MAX_STEPS; i++) {
        float sd = map(ro + (rd * d));
        d += sd;
        if(d > MAX_DIST) return MAX_DIST;
        if(abs(sd) < MIN_DIST) break;
    }
    return d;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - (0.5 *  resolution.xy)) / min(resolution.x, resolution.y);

    vec3 col = vec3(0.0);

    vec3 ro = vec3(0.0, 0.0, time * 3.0);
    vec3 rd = normalize(vec3(uv, 1.0));

    float d = march(ro, rd);
    vec3 p = ro + (rd * d);

    col += abs(d) / MAX_DIST;

    glFragColor = vec4(col,1.0);
}
