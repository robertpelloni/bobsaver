#version 420

// original https://www.shadertoy.com/view/WsjyRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define MAXIT 128
#define EPSILON 0.001
 
#define minx4(a, b) ((a.w) < (b.w) ? (a) : (b))
#define minx2(a, b) ((a.x) < (b.x) ? (a) : (b))
 
#define MAT0 0.0
#define MAT1 1.0
 
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
    a.y += sin(length(r.xy + t) * 7.) * 0.09;
    vec2 p = vec2(length(r.xz) - a.x, r.y);
    return length(p) - a.y;
}
 
float plane(vec3 r, vec3 o, vec3 n) {
    return dot(r - o, n);
}
 
float box(vec3 r, vec3 a)
{
    vec3 p = abs(r) - a;
    return length(max(p - p.x * 0.4 - p.y * 0.4, 0.)) + min(max(p.x - p.y * 0.5, max(p.y, p.z) - p.x * 0.3), 0.);
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
    obj = rotZ((-t + r.z * 0.2) * 0.3) * rotY(1. * t);
   
    vec2 b1 = vec2(
        box(obj * obj * (r) + vec3(0., sin(2. * t) * 1., 0.), vec3(.75, .5, .5)),
        MAT0
    );
   
    vec2 t1 = vec2(
        torus(- obj *r, vec2(2.0, 0.1)),
        MAT1
    );
   
    return minx2(b1, t1);
}
 
float hash(vec2 r) {
    return fract(sin(dot(r, vec2(15.5921, 96.654654))) * 23626.3663);
}
 
vec3 matCol(vec2 o)
{
    if (o.y == MAT0)
        return normalize(vec3(1., 0.5, .0));
   
    if (o.y == MAT1)
        return normalize(vec3(0., 1.7, 0.0));
   
    return vec3(0.);
}
 
void main(void)
{
    t = time;
   
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
   
    mat3 cam = rotY(t * 0. - PI);
       
    vec3 ro = vec3(0., 0., -3.0);
    vec3 rd = cam * normalize(vec3(uv * 2., -1.));
    vec3 r = ro;
   
    vec3 bcol = normalize((vec3(1., 0., 1.0) + 0.5) * (uv.y + 0.3) * (sin(t) + 1.) * 1.5 + vec3(0., 0.5, 1.0)) * 1.5 + 0.4;
    vec4 col = vec4(0.);
    col.rgb = bcol;
   
    vec2 c = vec2(10000., MAT0);
   
    float sh = 1.;
   
    float glow = 0.;
   
    vec3 gcol = bcol;
   
    for (int i = 0; i < MAXIT; ++i) {
        vec2 d = map(r);
        float z = length(r - ro);
       
        glow += exp(-d.x * 5.);
        gcol += matCol(d) * exp(-d.x * 1.);
       
        if (d.x < EPSILON) {
            col.rgb = mix(col.rgb, matCol(d), shade(normalize(r), rd));
            col.rgb = fog(z * 0.1, col.rgb, bcol);
            break;
        }
       
        d.x *= 0.7 - 0.1 * hash(uv);
        r += rd * clamp(d.x, -0.5, 0.5) * 0.7;
       
        sh = (float(i) / float(MAXIT));
    }
   
    col.rgb *= exp(-sh * .9);
    col.rgb = mix(col.rgb, gcol, glow * 0.005);
   
    glFragColor = vec4(col.rgb, 1.);
}
