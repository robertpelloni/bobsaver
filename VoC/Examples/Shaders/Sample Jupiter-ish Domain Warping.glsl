#version 420

// original https://www.shadertoy.com/view/3tGBRm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 p) {
    return fract(
        cos(
            dot(p, vec2(5981.43, 85749.43))
        ) * 28497.41
    );
}

float noise(vec2 p) {
    vec2 pi = floor(p);
    vec2 pf = fract(p);
    
    float ca = rand(pi);
    float cb = rand(pi + vec2(1., 0.));
    float cc = rand(pi + vec2(0., 1.));
    float cd = rand(pi + vec2(1., 1.));
    
    vec2 u = smoothstep(0., 1., pf);
    return mix(
        mix(ca, cb, u.x),
        mix(cc, cd, u.x),
        u.y
    );
}

float fbm(vec2 p) {
    const int octaves = 12;
    const float lacunarity = 2.;
    const float gain = 0.55;
    
    float freq = 1.;
    float amp = 0.5;
    
    float n = 0.;
    for(int i = 0; i < octaves; i++) {
        n += noise(p * freq) * amp;
    
        freq *= lacunarity;
        amp *= gain;
    }
    
    return n;
}

float pattern(vec2 p, out vec2 q, out vec2 r) {
    q = vec2(
        fbm(p + vec2(4., 0.5) + time * 0.2),
        fbm(p + vec2(2., 32.))
    );
    
    r = vec2(
        fbm(p + q + time * 0.3),
        fbm(p + q + vec2(1.3, 2.4))
    );
    
    return fbm(p + r);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    
    vec2 p = uv * 8.;
    vec2 q, r;
    float pct = pattern(p, q, r); 
    vec3 col = mix(vec3(0.8), vec3(1., 0.43, 0.), q.x);
    col = mix(col, vec3(1.0, 0.75, 0.4), p.x / q.x * r.x / 12.);
    col *= pct;

    glFragColor = vec4(col,1.0);
}
