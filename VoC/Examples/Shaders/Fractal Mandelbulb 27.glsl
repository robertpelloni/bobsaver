#version 420

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

const int   ITR_MC = 128;
const int   ITR_MD = 8;
const int   ITR_AO = 4;
const float EPS    = 0.001;
const vec3  BG     = vec3(0.5, 0.6, 0.7);

float dist(vec3 p)
{
    float POW = 4.0;
    vec3  z   = p;
    float dr  = 1.0;
    float r   = 0.0;
    
    for (int i = 0; i < ITR_MD; ++i)
    {
        r = length(z);
        if (r > 2.0) break;
        
        float theta = acos(z.z / r);
        float phi   = atan(z.y, z.x);
        dr = pow(r, POW - 1.0) * POW * dr + 1.0;
        
        float zr = pow(r, POW);
        theta = theta * POW;
        phi   = phi * POW;
        
        z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        z += p;
    }
    
    return 0.5 * log(r) * r / dr;
}

vec3 norm(vec3 p)
{
    return normalize(vec3(
        dist(p) - dist(vec3(p.x - EPS, p.y      , p.z      )),
        dist(p) - dist(vec3(p.x      , p.y - EPS, p.z      )),
        dist(p) - dist(vec3(p.x      , p.y      , p.z - EPS))
    ));
}

float shade(vec3 p, vec3 l)
{
    vec3 ray = l;
    vec3 cur = p + vec3(EPS);
    
    for (int i = 0; i < ITR_MC; ++i)
    {
        float d = dist(cur);
        
        if (d < EPS)
        {
            return 0.5;
        }
        
        cur += ray * d;
    }
    
    return 2.0;
}

float ao(vec3 p, vec3 n)
{
    float occ = 0.0;
    float sca = 1.0;
    
    for (int i = 0; i < ITR_AO; ++i)
    {
        float hr = 0.2 * float(i) / float(ITR_AO);
        vec3 aopos = n * hr + p;
        float dd = dist(aopos);
        occ += (hr - dd) * sca;
        sca *= 0.95;
    }
    
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0 );
}

mat4 rm(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rot(vec3 v, vec3 axis, float angle) {
    mat4 m = rm(axis, angle);
    return (m * vec4(v, 1.0)).xyz;
}

void main()
{
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    
    vec3 cam = rot(vec3(0.0, 0.0, 2.0), vec3(1.0), time);
    vec3 ray = normalize(rot(vec3(uv, -1.0), vec3(1.0), time));
    vec3 cur = cam;
    vec3 col = BG;
    vec3 lightDir = rot(normalize(vec3(0.0, 0.0, 1.0)), vec3(1.0), time + 1.5);
    
    for (int i = 0; i < ITR_MC; ++i)
    {
        float d = dist(cur);
        
        if (d < EPS)
        {
            vec3 n = norm(cur);
            col = vec3(clamp(ao(cur, n) * shade(cur, lightDir), 0.0, 1.0));
            break;
        }
        
        cur += ray * d;
    }
    
    glFragColor = vec4(col, 1.0);
}
