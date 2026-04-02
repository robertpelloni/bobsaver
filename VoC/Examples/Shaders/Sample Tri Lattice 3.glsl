#version 420

// original https://www.shadertoy.com/view/XssfRr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 uv)
{
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 hue2rgb(float h)
{
    h = fract(h) * 6.0 - 2.0;
    return clamp(vec3(abs(h - 1.0) - 1.0, 2.0 - abs(h), 2.0 - abs(h - 2.0)), 0.0, 1.0);
}

vec2 uv2tri(vec2 uv)
{
    float sx = uv.x - uv.y / 2.0; // skewed x
    float sxf = fract(sx);
    float offs = step(fract(1.0 - uv.y), sxf);
    return vec2(floor(sx) * 2.0 + sxf + offs, uv.y);
}

float tri(vec2 uv)
{
    vec2 p = floor(uv2tri(uv));
    p = vec2(p.x + p.y, p.y * 2.0);
    float d = length(p + 1.0);
    float f1 = 1.6 + sin(time * 0.5765) * 0.583;
    float f2 = 1.3 + sin(time * 1.7738) * 0.432;
    return abs(sin(f1 * d) * sin(f2 * d));
}

void main(void)
{  
    float t = smoothstep(0.2, 0.8, fract(time));

    vec2 uv = gl_FragCoord.xy - resolution.xy / 2.0;
    uv *= (2.0 - t) / resolution.y;

    float c = mix(tri(uv * 4.0), tri(uv * 8.0), t);
    glFragColor = vec4(c, c, c, 1.0);
}
