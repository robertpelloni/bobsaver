#version 420

// original https://www.shadertoy.com/view/wlyGDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void main(void)
{
    float wave_uv_y = gl_FragCoord.xy.y / 12.0 + sin(gl_FragCoord.xy.x / 10.0) * 0.5;
    float wave_cos = cos(gl_FragCoord.xy.x / 10.0);
    
    float wave_fract = fract(wave_uv_y);
    
    float wave = 1.0 - clamp(abs(wave_fract * 2.0 - 1.0) * 6.0 - 1.0, 0.0, 1.0);
    wave *= mod(wave_uv_y, 4.0) < 2.0 ? 0.0 : 1.0;
    
    float wave_color_offset = (cos(time * 0.6) * 2.0) + (floor(wave_uv_y * 0.25) * acos(-1.0) * 0.5);
    float wave_color = sin(gl_FragCoord.xy.x / 10.0 + wave_color_offset) > 0.0 ? 0.65 : 0.35;
    
    vec2 uv = gl_FragCoord.xy/resolution.xx;
    float offset = sin(time * 0.5) * 0.35;
    //if (mouse*resolution.xy.z > 0.0)
    //    offset = 0.5 - mouse*resolution.xy.x / resolution.x;
    
    float diag = uv.x - 0.5 + offset - (uv.y - 0.5*resolution.y/resolution.x) * 0.5;
    float back_color = 0.5;
    back_color = mix(1.0, back_color, clamp((diag + 0.35) * resolution.x * 0.75, 0.0, 1.0));
    back_color = mix(back_color, 0.0, clamp((diag - 0.35) * resolution.x * 0.75, 0.0, 1.0));
    
    float col = mix(back_color, wave_color, wave);

    glFragColor = vec4(col, col, col, 1.0);
}
