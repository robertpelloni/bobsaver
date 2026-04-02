#version 420

// original https://www.shadertoy.com/view/7lS3D3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float noise(vec2 p) {
    return sin(p.x * 11.0 + p.y * 8.0);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy/resolution.xy * 2.0 - 1.0) * resolution.xy / max(resolution.x, resolution.y) * 2.0;
    float time = float(time) * 0.4 - 0.15;
    
    float a = atan(uv.x, uv.y);
    float r = length(uv) * 2.0;
    vec2 p = vec2(a, r);

    for (int i = 1; i < 5; i++) {
        vec2 newp = p + time;
        newp.x += (0.1 + sin(time - 0.15)) * noise(p.xy);
        newp.y += (0.1 + sin(time - 0.15)) * noise(p.yx);
        p = mix(p, newp, 0.5);
    }

    glFragColor = vec4(0.5 * sin(p.x) + 0.5, 0.4 * sin(p.y) + 0.5, 0.4 * sin(p.x + p.y + 1.5) + 0.5, 1.0);
}
