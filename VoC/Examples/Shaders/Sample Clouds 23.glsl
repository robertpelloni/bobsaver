#version 420

// original https://www.shadertoy.com/view/lddcRl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(vec2 uv)
{
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 uv)
{
    vec2 ipos = floor(uv);
    vec2 fpos = fract(uv);
    
    float a = hash(ipos);
    float b = hash(ipos + vec2(1.0, 0.0));
    float c = hash(ipos + vec2(0.0, 1.0));
    float d = hash(ipos + vec2(1.0, 1.0));
    
    vec2 u = smoothstep(0.0, 1.0, fpos);
    
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 uv)
{
    float amp = 0.5;
    float freq = 1.0;
    
    float acc = 0.0;
    float total_weight = 0.0;
    for (int i = 0; i < 5; ++i)
    {
        acc += amp * noise(freq * uv);
        total_weight += amp;
        
        amp *= 0.5;
        freq *= 2.0;
    }
    
    acc /= total_weight; //normalize fbm value
    return acc;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv *= resolution.x/resolution.y;
    uv *= 3.0;

    float t = fbm(uv + fbm(uv + fbm(uv - 0.35*time) + 0.2*time) + 0.3*time);
    vec3 base_col = vec3(0.2, 0.5, 0.7);
    vec3 layered_col = vec3(0.9);
    
    vec3 col = mix(base_col, layered_col, t);
    col = sqrt(col);
    glFragColor = vec4(col, 1.0);
}
