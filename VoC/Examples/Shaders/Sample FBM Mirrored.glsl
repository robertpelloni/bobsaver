#version 420

// original https://www.shadertoy.com/view/3tj3DV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define v2 vec2
#define v3 vec3
#define v4 vec4
#define f32 float
#define s32 int
#define b32 bool
#define m2 mat2
#define TAU 6.283185307179586
#define DEG_TO_RAD (TAU / 360.0)
#define zero_v2 vec2(0,0)

v2 uv;

f32 random (v2 p) {
    return fract(sin(dot(p.xy,vec2(12.9898,78.233)))*43758.5453123);
}

f32 noise (v2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

f32 fbm(v2 p, f32 freq, f32 amp, f32 lacunarity, f32 gain, s32 octave) {
    f32 accum = 0.;
    //f32 ang = 1.6180339;
    f32 ang = 0.5;

    for(s32 i = 0; i < octave; i++) {
        f32 n = noise(p) * amp;
        accum += n;

        amp *= gain;

        p = (m2(cos(ang), sin(ang), -sin(ang), cos(ang)) * p) * freq + v2(1000., 0.);
        p *= 2.;

        freq *= lacunarity;
    }

    return accum;
}

f32 fbm_s(v2 p) {
    return fbm(p, 1.5, .6, 1.1, .5, 5);
}

void main(void) {
    vec4 out_color = glFragColor;

    f32 time = time * .1;
    v2 resolution = resolution.xy;
    uv = (2. * gl_FragCoord.xy / resolution) - 1.;
    uv.y *= resolution.y / resolution.x;

    out_color.rgba = v4(0,0,0,1);
    
   
    v2 p = abs(uv);
    p *= 2.;
    p += v2(1000. - time * .02);

    v2 f1 = v2(fbm_s(p) + time * .02, fbm_s(p));
    v2 f2 = v2(fbm_s(p + f1 + atan(fbm_s(f1) + p.x * p.y)), fbm_s(p + f1 * 2.));
    v2 f3 = v2(fbm_s(p + f2 * 5.), fbm_s(p + f2 + atan(fbm_s(f2))));
    f32 final = fbm_s(p + f3 * 4. + time * 4.);

    f32 r = clamp(final - 0.3, 0., 1.);
    f32 g = clamp(final, 0., .2);

    out_color.rb = v2(1) * v2(r, g);
    out_color.rgb *= (1.1 - length(uv)) * (1.2 - length(uv));

    glFragColor = out_color;
}
