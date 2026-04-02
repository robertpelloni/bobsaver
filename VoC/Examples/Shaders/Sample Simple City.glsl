#version 420

// original https://www.shadertoy.com/view/WdXcDX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rotate(float ang)
{
    float ca = cos(ang),sa = sin(ang);
    return mat2(ca, sa, -sa, ca);
}

float sdBox(vec3 p, vec3 b)
{
    vec3 h = abs(p) - b;
    return max(h.x, max(h.y, h.z)) * 0.8;
    return length(max(h, 0.0));
}

float rand(vec2 uv)
{
    return fract(sin(dot(uv, vec2(12.493, 94.329))) * 2994.382);
}

float rand(vec3 p)
{
    return fract(sin(dot(p, vec3(12.943,94.493, 158.03))) * 4948.8);
}

float building(vec3 p, float s)
{
    p /= s;
    float d = sdBox(p, vec3(2.0, 5.0, 2.0));
    return d * s;
}

float buildings(vec3 p, float rep)
{
    vec2 id = floor(p.xz / rep);
    p.xz = mod(p.xz, rep) - 0.5 * rep;
    float d = building(p, 1.0 + rand(id) * 2.0);
    return d;
}

float getColor(vec3 p)
{
    return rand(floor(p));
}

float map(vec3 p)
{
    float d = buildings(p, 20.0);
    d = min(d, buildings(p + vec3(25.0, 0.0, -10.), 20.0));
    d = min(d, buildings(p + vec3(-10.0, 0.0, 25.0), 20.0));
    return min(d, p.y + 5.0);
}

vec3 norm(vec3 p)
{
    vec2 e = vec2(0.001, 0.0);
    return normalize(vec3(
        map(p + e.xyy) - map(p - e.xyy),
        map(p + e.yxy) - map(p - e.yxy),
        map(p + e.yyx) - map(p - e.yyx)
    ));
}

void main(void)
{   
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    vec3 r0 = vec3(0.0, 40.0, -200.0);
    float time = mod(time, 25.0);
    r0.xz *= rotate(0.75);
    r0.z -= time * 10.;
    vec3 tgt = vec3(-40.0);
    tgt.z -= time * 10.;
    vec3 ww = normalize(tgt - r0);
    vec3 uu = normalize(cross(vec3(0,1,0), ww));
    vec3 vv = normalize(cross(ww, uu));
    vec3 rd = normalize(uv.x * uu + uv.y * vv + ww);

    float d = 0.0;
    vec3 ld = normalize(vec3(0.5, 1.0, -0.5));    
    vec3 col = vec3(0.0);
    for(int i = 0; i < 100; ++i)
    {
        vec3 p = r0 + d * rd;
        float t = map(p);
        d += t;
        if(t < 0.001)
        {
            break;
        }
        if(d > 400.0) break;
    }
    
    vec3 at = vec3(0.0);
    if(d < 400.0)
    {
        vec3 p = r0 + d * rd;
        float albedo = 0.0;
        float rnd = getColor(floor(p * 1.5));
        albedo = step(rnd, 0.90) * rnd;
        vec3 n = norm(p);
        if(n.y > 0.9) albedo += 0.2;
        at += 0.001 / (0.001 + albedo);
    }
    col += at * vec3(1.28, 1.20, 0.9);
    float fog = 1.0 - clamp(d / 400.0, 0.0, 1.0);
    col *= fog;
    col = smoothstep(0.0, 1.0, col);
    glFragColor = vec4(col, 1.0);
}
