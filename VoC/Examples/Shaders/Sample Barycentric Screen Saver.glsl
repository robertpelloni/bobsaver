#version 420

// original https://www.shadertoy.com/view/lsSSDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// A "screen-saver" based on barycentric coordinates
// written 26.11.2014 by Jakob Thomsen
// (jakobthomsen@gmx.de)

// mirror/bounce inside -1,+1
vec2 mirror(vec2 pos)
{
    return (2.0 * abs(2.0 * fract(pos) - 1.0) - 1.0);
}

float light(vec2 pos, float size, vec2 uv)
{
    return exp(-pow(distance(uv, pos) / size, 2.0));
}

vec3 barycentric(vec2 a, vec2 b, vec2 c, vec2 p)
{
    float d = (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y);
    float alpha = ((b.y - c.y) * (p.x - c.x)+(c.x - b.x) * (p.y - c.y)) / d;
    float beta = ((c.y - a.y) * (p.x - c.x) + (a.x - c.x) * (p.y - c.y)) / d;
    float gamma = 1.0 - alpha - beta;
    return vec3(alpha, beta, gamma);
}

vec3 inRange3(vec3 p)
{
    return step(p, vec3(1.0)) * step(vec3(0.0), p);
}

float inRangeAll(vec3 p)
{
    vec3 r = inRange3(p);
    
    return r.x * r.y * r.z;
}

void main(void)
{
    vec2 speed0 = vec2(0.0432, 0.0123);
    vec2 speed1 = vec2(0.0257, 0.0332);
    vec2 speed2 = vec2(0.0835, 0.0674);
    float size = 0.1;
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.0) / min(resolution.x, resolution.y);
    //vec2 uv = (gl_FragCoord.xy - iResolution.xy / 2.0) / iResolution.xy;
    uv *= 2.0;
    float val = 0.0;
    vec2 pos0 = mirror(time * speed0);
    vec2 pos1 = mirror(time * speed1);
    vec2 pos2 = mirror(time * speed2);
    vec3 bc = barycentric(pos0, pos1, pos2, uv);
    val = inRangeAll(bc);
    val = mix(val, light(vec2(0.0), 1.0, uv), max(step(1.0, abs(uv.x)),step(1.0, abs(uv.y))));
    vec3 c = bc * val;
    c = c + vec3(1.0, 0.0, 0.0) * light(pos0, size, uv);
    c = c + vec3(0.0, 1.0, 0.0) * light(pos1, size, uv);
    c = c + vec3(0.0, 0.0, 1.0) * light(pos2, size, uv);

    glFragColor = vec4(c, 1.0);
}
