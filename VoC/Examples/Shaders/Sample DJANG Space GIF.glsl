#version 420

// original https://www.shadertoy.com/view/wsfXDN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float Xor(float a, float b)
{
    return a * (1.0 - b) + b * (1.0 - a);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;

    vec3 col = vec3(0.0);
    
    float a = sin(time * 0.01) * 3.14;
    float c = cos(a);
    float s = sin(a);
    
    uv *= mat2(c, -s, s, c);
    uv *= 15.0;
    
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    
    float m = 0.0;
    float t = time;
    
    for (float y = -1.0; y <= 1.0; ++y)
    {
        for (float x = -1.0; x <= 1.0; ++x)
        {
            vec2 offs = vec2(x, y);
            
            float d = length(gv + offs);
            float dist = length(id - offs) * 0.3;
            
            
            float r = mix(0.3, 1.5, sin(dist - t) * 0.5 + 0.5);
            
            m = Xor(m, smoothstep(r, r * 0.85, d));
        }
    }
    
    // col.rg = gv;
    // col += mod(m, 2.0);
    col += m;

    glFragColor = vec4(col,1.0);
}
