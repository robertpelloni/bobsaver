#version 420

// original https://www.shadertoy.com/view/7tSyW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))*43758.5453123);
}

mat2 rotate(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

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

float fbm ( in vec2 n) {
    float total = 0.0;
    float amplitude = 0.7;
    mat2 rot = rotate(0.5);
    for (int i = 0; i < 6; ++i) {
        total += amplitude * noise(n);
        n = rot *n * 2.0+300.;
        amplitude *= 0.45;
    }
    return total;
}
void main(void) {
    vec2 st =gl_FragCoord.xy / resolution.xy*3.;

    vec3 color = vec3(0.0);

    vec2 q = vec2(0.);
    q.x = fbm( st + 0.01*time);
    q.y = fbm( st + vec2(1.0));

    vec2 r = vec2(0.);
    r.x = fbm( st + 1.0*q + 0.15*time );
    r.y = fbm( st + 1.0*q + 0.1*time);

    float f = fbm(st +r);

    color = mix(vec3(0.3,0.5,0.6),
                vec3(0.3,0.3,0.4),
                clamp((f*f)*2.0,.0,.5));

    color = mix(color,
                vec3(0.3589,0.369,0.3875),
                clamp(length(r.x)*10.,0.0,.80));

    glFragColor = vec4((f*f*f+.9*f*f+0.5*f)*color,.5);
}
