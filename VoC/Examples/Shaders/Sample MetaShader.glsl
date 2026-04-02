#version 420

// original https://www.shadertoy.com/view/Wt23Rt

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU 6.2831853
float wave(float x, float freq, float phase) {
    return (sin(x * freq + phase) + 1.) * 0.5;
}

float rand(inout float seed) {
    seed += wave(seed, 1., 12.) * 0.6;
    return fract(sin(seed)*1000000.);
}

float rand (in vec2 st) {
    return fract(sin(dot(st.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

float choose(vec3 v, inout float seed) {
    return v[int(mod(seed++, 3.))];
}

float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
        (c - a)* u.y * (1.0 - u.x) +
        (d - b) * u.x * u.y;
}

#define OCTAVES 6
float fbm (in vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

vec3 hsb2rgb( in vec3 c ){
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),
                             6.0)-3.0)-1.0,
                     0.0,
                     1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

vec3 omni(vec3 v, inout float seed) {
    float p = rand(seed);
    vec3 res = v;
    for (int i = 0; i < 3; i++) {
        if (p < 0.15) {
            vec2 tmp = vec2(choose(v, seed), choose(v, seed));
            tmp = rotate2d((choose(v, seed)+1.) * TAU) * tmp;
            res[i] = wave(tmp.x, tmp.y*5.+0.6, choose(v, seed));
        } else if (p < 0.2) {
            res[i] = pow(choose(v, seed), choose(v, seed)+0.2);
        } else if (p < 0.3) {
            float s = choose(v, seed) + choose(v, seed);
            res[i] = mix(choose(v, seed), rand(s), choose(v, seed)*0.03);
        } else if (p < 0.35) {
            res[i] = length(vec2(choose(v, seed), choose(v, seed))) / 1.4;
        } else if (p < 0.40) {
            res[i] = pow(min(choose(v, seed), choose(v, seed)), 0.8);
        } else if (p < 0.48) {
            res[i] = noise(vec2(choose(v, seed), choose(v, seed)));
        } else if (p < 0.50) {
            res[i] = 1. - choose(v, seed);
        } else if (p < 0.55) {
            res[i] = choose(v, seed);
        } else if (p < 0.65) {
            res[i] = pow(max(smoothstep(choose(v, seed), choose(v, seed), choose(v, seed)), choose(v, seed)), 2.);
        } else if (p < 0.75) {
            float r = rand(seed) + 0.5;
            res[i] = pow(abs(choose(v, seed) - r + choose(v, seed)*r), 0.5);
        } else if (p < 0.85) {
            float modulus = choose(v, seed);
            res[i] = mod(choose(v, seed), modulus) + modulus/2.;
        } else {
            res[i] = fbm(vec2(choose(v, seed), choose(v, seed)) * 30. * pow(choose(v, seed), 3.));
        }
    }
    res = vec3(rotate2d(choose(v, seed)) * res.xy, res.z);

    return res;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy/vec2(min(resolution.x, resolution.y));
    float size = pow(wave(time, 0.3, -2.4) + 1., pow(wave(time, 0.08, 0.), 2.)*6.5) + 1.;
    float seed;
    vec2 cam = (vec2(wave(time, 0.02, 0.), wave(time, 0.0111, 0.5)));
    cam = (cam * resolution.xy + mouse*resolution.xy.xy) * 0.1;
    vec2 pos = (uv*size + cam);
    float border = 0.1 + size * 0.005;
    float brightness = 1.0;
    if (size < 100. && (fract(pos.x) < border || fract(pos.y) < border)) {
        seed = floor(time);
        pos = fract(pos * 0.01);
    } else {
        seed = floor(pos.x)*1.00180820 + floor(pos.y)*1000.58765 + date.z*101.;
        pos = fract(pos);

    }
    pos = rotate2d(rand(seed)) * pos * 0.7;
    vec3 warped = vec3(pos, noise(vec2(time*rand(seed)*2.)));
    int iters = int(pow(rand(seed), 2.) * 3. + 3.);
    for (int i = 0; i < iters; i++) {
        warped = omni(warped, seed);
    }
    float interval = pow(rand(seed), 5.);

    glFragColor = vec4(hsb2rgb(vec3(
        fract(rand(seed) + warped.x * interval),
        pow(warped.y, 0.8),
        pow(warped.z, 0.4))
    ), 1.0);
}
