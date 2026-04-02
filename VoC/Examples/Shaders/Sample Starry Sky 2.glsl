#version 420

// original https://neort.io/art/c7kditc3p9fdutchc59g

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

#define S(a, b, t) smoothstep(a, b, t)

float DistLine(vec2 p, vec2 a, vec2 b)
{
    vec2 pa = p - a; vec2 ba = b - a;
    float t = clamp(dot(pa, ba) / dot(ba, ba), 0., 1.);

    return length(pa - ba*t);
}

float rand21(vec2 p)
{
    p = fract(p * vec2(346.278, 726.781)); // 0 - 1
    p += dot(p, p + 76.59);
    return fract(p.x * p.y);
}

vec2 rand22(vec2 p)
{
    float n = rand21(p);
    return vec2(n, rand21(p + n));
}

vec2 GetPos(vec2 id, vec2 offset)
{
    id += offset;
    vec2 n = rand22(id) * time;
    return offset + sin(n) * .45;
}

float DrawLine(vec2 p, vec2 a, vec2 b)
{
    float d = DistLine(p, a, b);
    float m = S(.03, .01, d);
    m *= S(1.1, .5, length(a - b));
    return m;
}

void main()
{

    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / min(resolution.x, resolution.y);

    float m = 0.;
    uv *= 15. + 3. * (.5 + .5*sin(time/2.));
    
    vec2 gv = fract(uv) - .5;
    vec2 id = floor(uv);

    vec2 p[9];
    
    // int i = 0;
    // for(float y =  -1.; y <= 1.; y++)
    // {
    //     for(float x =  -1.; x <= 1.; x++)
    //     {
    //         p[i] = GetPos(id, vec2(x, y));
    //         i++;
    //     }
    // }
    
    p[0] = GetPos(id, vec2(-1, -1));
    p[1] = GetPos(id, vec2(-1, 0));
    p[2] = GetPos(id, vec2(-1, 1));
    p[3] = GetPos(id, vec2(0, -1));
    p[4] = GetPos(id, vec2(0, 0));
    p[5] = GetPos(id, vec2(0, 1));
    p[6] = GetPos(id, vec2(1, -1));
    p[7] = GetPos(id, vec2(1, 0));
    p[8] = GetPos(id, vec2(1, 1));

    for(int i = 0; i < 9; i++)
    {
        m += DrawLine(gv, p[4], p[i]);
        
        float size = 30. * (.75+.5*rand21(id));
        vec2 j = (p[i] - gv) * size;
        float sparkle = 1./ dot(j, j);
        sparkle *= sin(14. *(time + fract(p[i].x))) * .5 + .5;
        m += sparkle;
    }
    m += DrawLine(gv, p[1], p[3]);
    m += DrawLine(gv, p[1], p[5]);
    m += DrawLine(gv, p[7], p[3]);
    m += DrawLine(gv, p[7], p[5]);

    vec3 col = mix(vec3(.05), vec3(.03), uv.y);
    col += vec3(m);

    glFragColor = vec4(col, 1.0);
}
