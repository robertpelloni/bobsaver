#version 420

// original https://www.shadertoy.com/view/wlSyDh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float easeOutQuint(float x) {
    return 1. - pow(1. - x, 4.);
}

void main(void)
{
vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;

    float scale = 40.;
    float w = length(uv + vec2(0., 3.));
    w = pow(w, 4.) / scale;
    
    float a_time = time;
    float a1 = smoothstep(0., 1., a_time);
    float a2 = smoothstep(2., 3., a_time);
    float a3 = smoothstep(4., 4., a_time);
    float a4 = smoothstep(6., 8., a_time);

    uv = mix (uv, uv/w, a2);

    float p_scale = 100.;

    float time = 1. * time;
    float prog = clamp(time + 0.8, 0., 1.);
    prog = 1. - easeOutQuint(1. - prog);

    float p_start = -0.4;
    float p_end = 0.3;

    float p_size = (uv.y - p_start) / (p_end - p_start);
    p_size = 1. - p_size;
    p_size += a1 - 1.;
    float o_size = p_size;

    float s = smoothstep(max(0., p_size - 0.05), p_size, prog);

    p_size = mix(0., 0.75, smoothstep(0., 0.4, s));
    p_size = mix(p_size, o_size, smoothstep(0.4, 0.85, s));

    float clp = 0.9;
    p_size = mix(p_size, clp, step(clp, p_size) - step(1., p_size));
    p_size = clamp((1. - p_size) / 2., 0., 0.5);

    float pixel_speed = a3 * 4. * time;
    vec2 fv = vec2(fract(uv.x * p_scale), fract(uv.y * p_scale - pixel_speed));
    float mp = step(p_size, fv.x) - step(1. - p_size, fv.x);
    mp = min(mp, step(p_size, fv.y) - step(1. - p_size, fv.y));

    float wave_speed = 1. * time;
    vec2 wv = vec2(uv.x * scale * 0.7, uv.y * scale * 0.5);
    wv.x += a4 * 2. * sin(wv.y - wave_speed);
    float wave = sin(wv.x);
    wave = pow(wave, 6.);
    wave = smoothstep(0.4, 1., wave);
    wave *= step(p_start, uv.y) * mp;
    wave = clamp(wave, 0., 1.);
    vec3 col = vec3(0.1059, 0.0275, 0.0863);

    vec2 pv = floor(uv * p_scale) / p_scale;
    vec3 c1 = vec3(0.1608, 0.0196, 0.5882);
    vec3 c2 = vec3(0.5765, 0.1333, 0.6157);
    vec3 c3 = vec3(0.1059, 0.0275, 0.0863);
    //vec3 c12 = mix(c1, c2, step(0.5, fract(sin(pv.x * 123. + pv.y * 100.) * 123.)));
    vec3 c12 = mix(c1, c2, smoothstep(-0.5, 0.5, sin(-wv.x * 6. + wv.y * 6. - a3 * 12. * time)));

    col = mix(col, c12, wave);
    // col += fract(w * 2.)/4.;
    col = mix(c3, col, smoothstep(p_start, p_start + 0.2, uv.y));
    //col += c12/12.;
    

    glFragColor = vec4(col,1.);
}
