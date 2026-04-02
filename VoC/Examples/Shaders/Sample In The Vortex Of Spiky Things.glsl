#version 420

// original https://www.shadertoy.com/view/wsSBzt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SPIKENUM 1.0

#define PI 3.14159265
#define MAXIT 200
#define EPSILON 0.08
 
#define minx4(a, b) ((a.w) < (b.w) ? (a) : (b))
#define minx2(a, b) ((a.x) < (b.x) ? (a) : (b))
 
mat3 rotX(float a)
{
    return mat3(
        1., 0., 0.,
        0., cos(a), -sin(a),
        0., sin(a), cos(a)
    );
}
 
mat3 rotY(float a)
{
    return mat3(
        cos(a), 0.0, -sin(a),
        0., 1., 0.,
        sin(a), 0.0, cos(a)
    );
}
 
mat3 rotZ(float a)
{
    return mat3(
        cos(a), -sin(a), 0.,
        sin(a), cos(a), 0.,
        0., 0., 1.
    );
}
 
float t;
 
float sphere(vec3 r, float a)
{
    return length(r) - a;
}
 
float torus(vec3 r, vec2 a)
{
    vec2 p = vec2(length(r.xz) - a.x, r.y);
    return length(p) - a.y;
}
 
float plane(vec3 r, vec3 o, vec3 n) {
    return dot(r - o, n);
}

float cylinder(vec3 r, vec2 a)
{
    vec2 p = abs(vec2(length(r.xz), r.y)) - a;
    
    return min(max(p.x, p.y), 0.0) + length(max(p, 0.));
}

float hash(vec2 r) {
    return fract(sin(dot(r, vec2(15.5921, 96.654654))) * 23626.3663);
}

float box(vec3 r, vec3 a, vec2 s)
{
    r = rotY(r.y * sin(t * 2.)) * r;
    r = rotZ(atan(r.x, r.y) * (sin(t) * 1. + 1.) * SPIKENUM) * r;
    r = rotX(atan(r.y, r.z) * (sin(t) * 1. + 1.) * SPIKENUM) * r;
    
    vec3 p = (abs(r) - a);
    
    return length(max(p, 0.));
}
 
float shade(vec3 n, vec3 rd)
{
    return clamp(max(dot(n, -rd), 0.) + 1., 0., 1.);
}
 
vec3 fog(float z, vec3 col, vec3 fogCol)
{
    return mix(fogCol, col, exp(-z));
}

mat3 obj;

vec2 map(vec3 r)
{    
    obj = mat3(1.);
    r.z += t * 15.;
    
    vec3 tr = rotZ(-2.*t) * vec3(3., 3., 0.);
    r.x += tr.x;
    r.y += tr.y - 10.;
    
    vec3 rb1 = obj * r;
    rb1 = rotZ(r.z*0.1) * r;
    
    vec2 b1 = vec2(
        box(rotX(2. * t) * rotY(2. * t) * (mod(rb1 + 5., 10.) - 5.), vec3(1.5, 2., 1.) * 1.2, r.xy),
        (rotX(2. * t) * rotY(2. * t) * (mod(rb1 + 5., 10.) - 5.)).z
    );

    
    return b1;
}
 
vec3 matCol(vec2 o)
{
    if (o.y == 1.)
        return normalize(vec3(0.7, 0.05, .1));
    
    return normalize(vec3(0.7, 0.05, sin(o.y) * 0.2));
}
 
void main(void)
{
    t = -time * 0.4;
   
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
   
    mat3 cam = rotY(-PI) * rotX(0.3);
       
    vec3 ro = vec3(0., 10.0, -20.0);
    vec3 rd = cam * normalize(vec3(uv * 2., -1.));
    vec3 r = ro;
   
    vec3 bcol = vec3(0.0, 1.0, 1.0);
    vec4 col = vec4(0.);
    col.rgb = bcol;
   
    float sh = 1.;
   
    float glow = 0.;
   
    int ch = 1;
   
    for (int i = 0; i < MAXIT; ++i) {
        vec2 d = map(r);
        float z = length(r - ro);
       
        glow += exp(-d.x);
    
        if (d.x < EPSILON) {
            col.rgb = mix(col.rgb, 
                matCol(d), 
                shade(normalize(r), rd));
            col.rgb = fog(z * 0.0311, col.rgb, bcol);
            break;
        }
       
        d.x *= 0.7 - 0.01 * hash(uv);
        r += rd * d.x * 0.3;
       
        sh = (float(i) / float(MAXIT));
    }
   
    if (sh < 0.5)
        col.rgb *= exp(-sh * 1.3 + 1.);
   
    glFragColor = vec4(col.rgb, 1.);
}
