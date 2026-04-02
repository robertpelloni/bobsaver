#version 420

// original https://www.shadertoy.com/view/3sffRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://www.iquilezles.org/www/articles/intersectors/intersectors.htm
float sphIntersect(vec3 ro, vec3 rd, float ra)
{
    vec3 oc = ro;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - ra*ra;
    float h = b * b - c;
    if(h < 0.0) return -1.0;
    h = sqrt(h);
    return -b-h;
}

mat2 rot(float a)
{
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

float hash31(vec3 p)
{
    return fract(sin(dot(p, vec3(127.1, 311.7, 215.6))) * 43758.5453123);
}

float noise(vec3 p)
{
    vec3 id = floor(p);
    p = smoothstep(0.0, 1.0, fract(p));
    float h000 = hash31(id);
    float h100 = hash31(id + vec3(1.0,0.0,0.0));
    float h010 = hash31(id + vec3(0.0,1.0,0.0));
    float h110 = hash31(id + vec3(1.0,1.0,0.0));
    float h001 = hash31(id + vec3(0.0,0.0,1.0));
    float h101 = hash31(id + vec3(1.0,0.0,1.0));
    float h011 = hash31(id + vec3(0.0,1.0,1.0));
    float h111 = hash31(id + vec3(1.0,1.0,1.0));
    return mix(mix(mix(h000, h100, p.x), mix(h010, h110, p.x), p.y), mix(mix(h001, h101, p.x), mix(h011, h111, p.x), p.y), p.z);
}

float fbm(vec3 p)
{
    float r = 0.0, z = 2.0;
    for(int i = 0; i < 7; i++)
    {
        r += noise(p) / z;
        z *= 1.5;
        p *= 2.0;
    }
    return r;
}

void main(void)
{
    vec3 rd = normalize(vec3((gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.x, 1.0));
    vec3 ro = vec3(0,0,-2);
    vec2 mouse = 3.0 * vec2((mouse.x*resolution.xy.x - 0.5 * resolution.x) / resolution.x, (mouse.y*resolution.xy.y - 0.5 * resolution.y) / resolution.y);
    vec3 col, p, rp;

    float isphere = sphIntersect(ro, rd, 0.5);
    float hm = 0.0;

    if (isphere != -1.0)
    {
        p = ro + rd * isphere, rp = p;
        for(int i = 0; i < 4; i++)
        {
            p = ro + rd * isphere * (1.0 - hm * 0.05 * float(i + 1));
            p.yz = p.yz * rot(mouse.y);
            p.xz = p.xz * rot(mouse.x);
            hm = fbm((p + 3.0 * float(i)) * 5.0);
        }
        hm *= pow(-rp.z, 3.0) * 10.0;
    }
    
    col += vec3(hm * hm * hm, hm * hm, hm) * 2.0;

    glFragColor = vec4(col, 1);
}
