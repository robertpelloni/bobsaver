#version 420

// original https://www.shadertoy.com/view/3tK3Dw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Robert Śmietana (Logos) - 17.01.2020, Bielsko-Biała, Poland.

// AO based on https://www.shadertoy.com/view/XlXyD4

// code not cleaned yet...

const int marchIter = 70;
const float marchDist = 30.0;
const float epsilon = 0.0001;

const int aoIter = 12;
const float aoDist = 0.207;
const float aoPower = 2.0;

const vec3 aoDir[12] = vec3[12]
(
    vec3(0.357407, 0.357407, 0.862856),
    vec3(0.357407, 0.862856, 0.357407),
    vec3(0.862856, 0.357407, 0.357407),
    vec3(-0.357407, 0.357407, 0.862856),
    vec3(-0.357407, 0.862856, 0.357407),
    vec3(-0.862856, 0.357407, 0.357407),
    vec3(0.357407, -0.357407, 0.862856),
    vec3(0.357407, -0.862856, 0.357407),
    vec3(0.862856, -0.357407, 0.357407),
    vec3(-0.357407, -0.357407, 0.862856),
    vec3(-0.357407, -0.862856, 0.357407),
    vec3(-0.862856, -0.357407, 0.357407)
);

float sdeHexagonField(vec2 P, vec2 C, float Z, float f)
{
    P -= C;
    P *= Z;
    P.x *= 0.8660254037844386;

    vec2 P0 = mod(P, vec2(3.0, 2.0));
    vec2 P1 = abs(P0 - vec2(1.5, 1.0));
    vec2 P2 = abs(P1 - vec2(1.5, 1.0));
    
    float d1 = max(P1.x + 0.5 * P1.y, P1.y);
    float d2 = max(P2.x + 0.5 * P2.y, P2.y);

    return (min(d1, d2) - f) / Z;
}

vec3 InvCenter = vec3(0.0, 1.0, 0.0);
float InvRadius = 2.0;

float iDE(vec3 z)
{
    vec2 e = z.xz;

    float d = sdeHexagonField(e, vec2(0.0), 12.0 + 7.0*sin(0.541*time), 0.95);
    d = max(d, abs(z.y) - 0.1);
    return d;
}

vec3 rotate_x(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +1.0, +.0, +.0,
        +.0, +ca, -sa,
        +.0, +sa, +ca);
}

vec3 rotate_y(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +ca, +.0, -sa,
        +.0,+1.0, +.0,
        +sa, +.0, +ca);
}

vec3 rotate_z(vec3 v, float angle)
{
    float ca = cos(angle); float sa = sin(angle);
    return v*mat3(
        +ca, -sa, +.0,
        +sa, +ca, +.0,
        +.0, +.0, +1.0);
}

float scene(vec3 p)
{
    p = p.xzy;
    vec3 ori = p;
    
    p = rotate_x(p, sin(time));
    p = rotate_z(p, sin(0.66*time));
    
    p -= vec3(0.0, 1.0, 0.0);
    float r = length(p);
    float r2 = r * r;
    p = (InvRadius / r2) * p + InvCenter;
    float d = iDE(p);
    d = r2 * d / (InvRadius + r * d);
        
    return min(ori.y + 1.0, 0.8 * max(-d, length(ori) - 1.0));
}

vec3 getColor(vec3 p)
{
    p = p.xzy;
    
    if (p.y < -0.99)
    {
        p.z -= 3.1415926535*0.25*sin(time);
        p.x += 3.1415926535*0.25*sin(0.66*time);

        float d = sdeHexagonField(p.xz, vec2(0.0), 1.0, 0.8);
        if (d < 0.1) return vec3(1.0);
        return vec3(0.8);
    }
    
    return vec3(0.8 + 0.2*sin(0.5647*time), 1.0, 0.9);
}

float march(vec3 eye, vec3 dir) {
    float depth = 0.0;
    for (int i = 0; i < marchIter; ++i) {
        float dist = scene(eye + depth * dir);
        depth += dist;
        if (dist < epsilon || depth >= marchDist)
            break;
    }
    return depth;
}

float ao(vec3 p, vec3 n) {
    float dist = aoDist;
    float occ = 1.0;
    for (int i = 0; i < aoIter; ++i) {
        occ = min(occ, scene(p + dist * n) / dist);
        dist *= aoPower;
    }
    occ = max(occ, 0.0);
    return occ;
}

vec3 normal(vec3 p) {
    return normalize(vec3(
        scene(vec3(p.x + epsilon, p.y, p.z)) - scene(vec3(p.x - epsilon, p.y, p.z)),
        scene(vec3(p.x, p.y + epsilon, p.z)) - scene(vec3(p.x, p.y - epsilon, p.z)),
        scene(vec3(p.x, p.y, p.z + epsilon)) - scene(vec3(p.x, p.y, p.z - epsilon))
    ));
}

vec3 ray(float fieldOfView, vec2 size, vec2 gl_FragCoord, vec2 of) {
    vec2 xy = gl_FragCoord.xy + of - size / 2.0;
    float z = fieldOfView * size.y;
    return normalize(vec3(xy, -z));
}

mat3 viewMatrix(vec3 dir, vec3 up) {
    vec3 f = normalize(dir);
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat3(s, u, -f);
}

mat3 alignMatrix(vec3 dir) {
    vec3 f = normalize(dir);
    vec3 s = normalize(cross(f, vec3(0.48, 0.6, 0.64)));
    vec3 u = cross(s, f);
    return mat3(u, s, f);
}

//--- set this carefully ---//

#define SAMPLE_COUNT 10

//--- auxiliary functions ---//

float hash(float seed) { return fract(sin(seed)*43758.5453); }

void main(void)
{
    vec3 final_color = vec3(0.0);
    
    for (int i = 0; i < SAMPLE_COUNT; i++)
    {
        float sa = hash( dot( gl_FragCoord.xy, vec2(12.9898, 78.233) ) + 3213.1*float(i) );
        vec2 of = -0.5 + vec2( hash(sa+13.271), hash(sa+63.216) );
        
        vec3 dir = ray(2.5, resolution.xy, gl_FragCoord.xy, of);

        vec3 eye = vec3(6.5*cos(0.1*time), 6.5*sin(0.1*time), 2.34 + 0.5 * sin(0.45*time));
        vec3 center = vec3(0.0, 0.0, 0.0);

        mat3 mat = viewMatrix(center - eye, vec3(0.0, 0.0, 1.0));
        dir = mat * dir;

        float depth = march(eye, dir);
        if (depth >= marchDist - epsilon) { glFragColor = vec4(1.0); return; }

        vec3 p = eye + depth * dir;
        vec3 n = normal(p);

        mat = alignMatrix(n);
        float col = 0.0;
        for (int i = 0; i < aoIter; ++i)
        {
            vec3 m = mat * aoDir[i];
            col += ao(p, m) * (0.5 + 0.5 * dot(m, vec3(0.0, 0.0, 1.0)));
        }

        vec3 color = getColor(p);
        final_color += color * vec3(pow(0.26 * col, 0.7)); 
    }

    glFragColor = vec4(final_color / float(SAMPLE_COUNT), 1.0);
}
