#version 420

// original https://neort.io/art/c7nquhs3p9fbll0nrhq0

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

#define EPS 1e-4
#define STEPS 500
#define SPEED 0.4

float torusSDF(vec3 p, float lr, float sr)
{
    vec2 d = vec2(length(p.xz) - lr, p.y);
    return length( d ) - sr;
}

float sphereSDF(vec3 p, float r)
{
    return length(p) - r;
}

float sUnion(float a, float b, float k)
{
    float res = exp(-k*a) + exp(-k*b);
    return -log(max(EPS,res)) / k;
}

void main()
{
    vec2 uv = (gl_FragCoord.xy - .5 * resolution.xy) / resolution.y;

    float t = time * SPEED;
    
    float c = cos(t);
    float s = sin(t);
    uv *= mat2(c, -s, s, c);

    vec3 ro = vec3(0, 0, -.8);
    vec3 side1 = vec3(1, 0, 1);
    vec3 side2 = vec3(-1, 0, 1);
    vec3 lookat = mix(side1, side2, sin(t*1.92)*.5 + .5);
    float zoom = .5; // mix(.6, .8, sin(t*2.63)*.5 + .5);

    vec3 f = normalize(lookat - ro);
    vec3 right = normalize(cross(vec3(0, 1, 0), f));
    vec3 up = cross(f, right);

    vec3 cen = ro + f * zoom;
    vec3 i = cen + uv.x * right + uv.y * up;
    vec3 rd = normalize(i - ro);

    float dS, dO;
    vec3 p;
    float r1 = 1.;
    float r2 = mix(.75, 1.05, cos(t*.83)*.5 + .5);

    for(int i = 0; i < STEPS; i++)
    {
        p = ro + rd * dO;
        float dS1 = -torusSDF(p, r1, r2);
        float dS2 = sphereSDF(p, .31);
        
        dS = sUnion(dS1, dS2, 12.);
        
        // dS = -torusSDF(p, r1, r2);
        
        if(dS < EPS) break;
        dO += dS;
    }

    vec3 col = vec3(0.0);

    if(dS < EPS)
    {
        float x = atan(p.x, p.z) + t * .2;
        float y = atan(length(p.xz) - r1, p.y);

        float b = sin(y * 9. + x * 27.);
        float r = sin(6. * (x * 14. - y * 24.))* .5 + .5;
        float w = sin(x * 6. - y * 15. + t * 20.);

        float b1 = smoothstep(-.2, .2, b);
        float b2 = smoothstep(-.1, .1, b - .5);

        float m = b1 * (1. - b2);
        m = max(m, r * b2 * max(0., w));
        m += max(0., w * b2 * .3);

        col += m;
    }

    vec4 color = vec4(col, 1.0);

    glFragColor = color;
}
