#version 420

// original https://www.shadertoy.com/view/tsSyWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 random22(vec2 st)
{
    st = vec2(dot(st, vec2(127.1, 311.7)),
                dot(st, vec2(269.5, 183.3))
                );
    return -1.0 + 2.0 * fract(sin(st) * 43758.5453123);
}

vec3 celler2D(vec2 i,vec2 sepc)
{
    vec2 sep = i * sepc;
    vec2 fp = floor(sep);
    vec2 sp = fract(sep);
    float dist = 5.;
    vec2 mp = vec2(0.);

    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            vec2 neighbor = vec2(x, y);
            vec2 pos = vec2(random22(fp+neighbor));
            pos = sin( (pos*6. +time/2.) )* 0.5 + 0.5;
            float divs = length(neighbor + pos - sp);
            mp = (dist >divs)?pos:mp;
            dist = (dist > divs)?divs:dist;
        }
    }
    return vec3(mp,dist);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    float cell = celler2D(uv,vec2(6.5)).z;
    float celln = 0.;
    for (int y = -1; y <= 1; y++)
    {
        for (int x = -1; x <= 1; x++)
        {
            vec2 ne = vec2(x, y);
            celln +=  celler2D(uv + ne,vec2(6.5)).z;
        }
    }
    cell = smoothstep(cell,celln,2.2);
    vec3 col = vec3(1.) * sin( cell * 8. + time) ;
    glFragColor = vec4(col,1.0);
}
