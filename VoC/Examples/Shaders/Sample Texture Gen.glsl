#version 420

// original https://www.shadertoy.com/view/XdGBWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(in vec2 p)
{
    p = fract(p * vec2(821.35, 356.17));
    p += dot(p, p+23.5);
    return fract(p.x*p.y);
}

float noise(in vec2 p)
{
    vec2 ipos = floor(p);
    vec2 fpos = fract(p);
    
    float a = hash(ipos + vec2(0, 0));
    float b = hash(ipos + vec2(1, 0));
    float c = hash(ipos + vec2(0, 1));
    float d = hash(ipos + vec2(1, 1));
    
    vec2 t = smoothstep(0.0, 1.0, fpos);
    return mix(mix(a, b, t.x), mix(c, d, t.x), t.y);
}

float fbm(in vec2 p)
{
    p += 1.13;
    
    float res = 0.0;
    float amp = 0.5;
    float freq = 2.0;
    for (int i = 0; i < 6; ++i)
    {
        res += amp*noise(freq*p);
        amp *= 0.5;
        freq *= 2.0;
    }
    return res;
}

vec3 palette(float t)
{
    vec3 a = vec3(1, 1, 1);
    vec3 b = vec3(0, 0.3, 0);
    vec3 c = vec3(1, 0.7, 0);
    vec3 d = vec3(1, 0, 0);
    
    if (t < 0.333)
    {
        return mix(a, b, 3.0*t);
    }
    else if (t < 0.666)
    {    
        return mix(b, c, 3.0*(t - 0.3333));
    }
    else
    {
        return mix(c, d, 3.0*(t - 0.6666));
    }
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    float time = time;
    
    float x = fbm(uv);
    x = fbm(uv + x - 0.01*time);
    x = fbm(uv + x + 0.03*time);
    
    vec3 col = palette(x);
    glFragColor = vec4(col,1.0);
}
