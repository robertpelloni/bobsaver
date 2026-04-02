#version 420

// original https://www.shadertoy.com/view/fsjXDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

bool scene(vec3 p)
{
    vec3 d = mod(abs(p) + 18.0, 36.0) - 18.0;
    return length(d) > 24.0;
}

vec4 palette(float s, float n, float k)
{
    float r, g, b;
    float c = (1.0 - s) - n * 0.01;
    if (c > 0.5)
    {
        r = 1.0;
        g = (c - 0.5) * 2.0;
    }
    else
    {
        r = c * 2.0;
    }
    
    if (k == 0.0) { b = max(c, 0.0) / 2.0; }
    b += n / 512.0;

    return vec4(r, g, b, 1.0);
}

void main(void)
{
    float t = time * 0.05;
    vec2 uv = (gl_FragCoord.xy / resolution.xy) - vec2(0.5, 0.5);
    uv *= vec2(2.3, 1.3);

    vec3 o = vec3(10.01) + vec3(0, t * 50.0, 0.0);
    vec3 a = normalize(vec3(sin(t * 11.0), cos(t * 9.0), sin(t * 7.0)));

    vec3 u = vec3(0.0, 0.0, 1.0);
    vec3 c = normalize(cross(a, u));
    vec3 b = normalize(cross(a, c));

    vec3 d = a + b * uv.y + c * uv.x;
    vec3 p = floor(o);

    vec3 tmax = (p + step(vec3(0.0), d) - o) / d;
    vec3 delta = 1.0 / abs(d);
    vec3 step = sign(d);

    vec3 oldp;
    float k;

    int n = 0;
    do
    {
        if (tmax.x < tmax.y && tmax.x < tmax.z)
        {
            tmax.x += delta.x;
            p.x += step.x;
        }
        else if (tmax.y < tmax.x && tmax.y < tmax.z)
        {
            tmax.y += delta.y;
            p.y += step.y;
        }
        else
        {
            tmax.z += delta.z;
            p.z += step.z;
        }

        if (scene(p))
        {
            k = 0.0;
            break;
        }

        if (scene(p + 18.0))
        {
            k = 1.0;
            break;
        }

        oldp = p;
        n++;
    }
    while (n < 250);

    float s = abs(p.x - oldp.x) * 0.4 + abs(p.y - oldp.y) * 0.2;
    glFragColor = palette(s, float(n), k);
}
