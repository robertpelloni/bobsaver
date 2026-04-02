#version 420

// original https://www.shadertoy.com/view/7lfBWj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAU (6.283185307)
#define HEX(x) (vec3((x >> 16) & 255, (x >> 8) & 255, x & 255) / 255.)

vec3 color(float x){
    const int colorCount = 8;
    vec3[] c = vec3[](
        HEX(0xb010b0),
        HEX(0xe020c0),
        HEX(0xf0e040),
        HEX(0xc0ff80),
        HEX(0xb0ffb0),
        HEX(0xa0ffe0),
        HEX(0x7080F0),
        HEX(0x8000a0)
    );
    x *= float(colorCount);
    int lo = int(floor(x));
    
    return mix(
        c[lo],
        c[(lo + 1) % colorCount],
        smoothstep(0.98, 1., fract(x))
    );
}

float zigzag(float x) {
    return 1. - (abs(1. - mod(x, 2.0)));
}

#define REP 7. // how many pairs of reflections do you want

// i am dumb and i can't think of a better way to do this than converting to polar coords and back
vec2 kaleido(vec2 uv, float tx_rot, float circ_rot) {
    float r = length(uv);
    float theta = atan(uv.y, uv.x);
    theta = zigzag(
        REP * 2. * (
            theta + circ_rot
        ) / TAU
    ) * TAU / (REP * 2.) + tx_rot;
    uv = r * vec2(
        cos(theta), sin(theta)
    );
    return uv;
}

vec3 spiral(vec2 uv, float time) {
    float logr = (uv.x * uv.x + uv.y * uv.y < 0.1) ? 0.0 : log(length(uv));
    float theta = (uv.y == 0.0 && uv.x == 0.0) ? 0.0 : atan(uv.y, uv.x);
    return color(
        fract(
            1.0 * logr + 8. * theta / TAU + 2. * time
        )
    );
}

void main(void)
{
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / length(resolution.xy);
    float time = fract(time / 6.0);
    vec2 uv_kal = kaleido(uv, time * TAU, -time * TAU / REP);
    vec3 colSpiral = spiral(
        (round(-1. * time + uv_kal * 12.) + 1. * time) / 8., time
    );

    glFragColor = vec4(colSpiral,1.0);
}
