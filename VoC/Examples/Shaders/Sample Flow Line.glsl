#version 420

// original https://www.shadertoy.com/view/WsBSDG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution

mat2 rot(float a)
{
    float s = sin(a);
    float c = cos(a);
    return mat2(s, c, -c, s);
}

mat3 camera(vec3 ro, vec3 ta)
{
    const vec3 up = vec3(0, 1, 0);
    vec3 cw = normalize(ta - ro);
    vec3 cu = normalize(cross(cw, up));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

float map(vec3 p)
{
    mat2 rm = rot(-time / 3.0 + length(p));
    p.xy *= rm;
    p.zy *= rm;
    
    vec3 q = abs(p) - time * 0.1;
    q = abs(q - round(q));
    
    float d1 = min(length(q.xy), length(q.yz));
    float d2 = min(d1, length(q.xz));
    return min(d1, d2);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - R.xy) / R.y;

    vec3 ro = vec3(mouse*resolution.xy.xy / R.xy, 5);
    vec3 ta = vec3(0, 0, 0);
    
    vec3 ray = camera(ro, ta) * normalize(vec3(uv, 1.5));
    
    float d = 0.0;
    
    float dist = 0.0;
    for (int i = 0; i < 200; i++)
    {
        dist = map(ro + ray * d) / 2.0;
                
        d += dist;
    }
    
    
    vec3 col = vec3(d * 0.03);   

    d *= 0.03;
    glFragColor = vec4(1.0 - d, exp(-d), 2.0 * exp(-d / 4.0 - 1.0), 1.0);
}
