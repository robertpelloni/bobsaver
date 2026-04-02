#version 420

// original https://www.shadertoy.com/view/ltGyW3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 Q(vec3 v)
{
    float a = length(v) + 1e-3;
    return vec4(v / a * sin(a * .5), cos(a * .5));
}

vec3 R(vec4 q, vec3 v)
{
    vec3 t = 2. * cross(q.xyz, v);
    return v + q.w * t + cross(q.xyz, t);
}

vec3 view(vec3 v)
{
    v = R(Q(vec3(sin(time * 1.) * .5, 0, 0)), v);
    v = R(Q(vec3(0, time * .1, 0)), v);
    return v;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy - resolution.xy / 2.) / resolution.y;
    
    vec3 p = view(vec3(0, 0, -3));
    vec3 v = view(normalize(vec3(uv, 1)));

    for (int i=0 ; i<60 ; i++)
        p += v * length(p) - v;
    p = normalize(p);
    
    vec3 col = vec3(0);
    p = cos(p * 3.14e1);
    col = vec3(p.x*p.y*p.z*.5+.5);

    glFragColor = vec4(col, 1);
}
