#version 420

// original https://www.shadertoy.com/view/7sX3W4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define MAXIT 150
#define EPSILON 0.3
#define STEP 0.3
 
#define minx4(a, b) ((a.w) < (b.w) ? (a) : (b))
#define minx2(a, b) ((a.x) < (b.x) ? (a) : (b))

#define SA 1.
#define SB 2.
 
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

float box(vec3 r, vec3 a)
{    
    r.xz += vec2(cos(sin(r.y / a.x * PI) * 0.5 + t * 5. + 2. * cos(t)) * 0.8, sin(sin(r.y / a.x * PI) + t * 3.) * 0.8);
    r *= rotY(r.y / a.y * PI);
    a.x *= (sin(r.y / a.y * PI)) * 1. + 1.0;
    r.x += abs(sin(r.y / a.y * 0.5)) * 5. + 4. - 2. * sin(t * 0.5);
    a.xz *= clamp(sin(r.y / a.y * PI * 20.) * 1.1, 0.5 + 0.2 * sin(t * 0.03) + 0.1 * cos(5. * t), 2.);
    
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
    float tt = t * 0.3;
    obj *= rotY(t);
    r.z -= 42. + sin(tt) * 38.;
    
    vec3 rb1 = obj * r;
    
    float rs = 43. + sin(tt) * 30.;
    rb1.y += t * rs;
    vec3 rbp1 = mod(rb1+rs, rs*2.)-rs;
    vec3 rbp2 = mod(rotY(PI + t * PI / 2.) * rbp1 + vec3(0., t * rs / 2., 0.) + rs, rs*2.)-rs;
    
    vec2 b1 = vec2(
        box(rbp1, vec3(2., rs, 2.)), SA
    );
    vec2 b2 = vec2(
        box(rbp2, vec3(1., rs, 1.)), floor(mod(rbp2.y, 4.) + 2.)
    );

    return minx2(b1, b2);
}

vec3 matCol(vec2 o)
{
    if (o.y == SA)
        return normalize(vec3(0.0, 1.0, 1.0));
    if (o.y == SB)
        return normalize(vec3(1.0, 0.5, 0.0));
    
    return normalize(vec3(1., 0.2, 0.));
}
 
void main(void)
{
    t = time;
   
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
   
    mat3 cam = rotY(-PI) * rotX(0.3);
       
    vec3 ro = vec3(0., 2.0, -10.0);
    vec3 rd = cam * normalize(vec3(uv * 2., -1.));
    vec3 r = ro;
   
    vec3 bcol = vec3(1.0, 0.5, 0.2);
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
            col.rgb = fog(z * 0.02, col.rgb, bcol);
            break;
        }
       
        d.x *= 0.8 - 0.2 * hash(uv);
    r += rd * d.x * STEP;
       
        sh = (float(i) / float(MAXIT));
    }
   
    if (sh < 0.5)
    col.rgb *= exp(-sh * 2.0 + 1.0);
   
    glFragColor = vec4(col.rgb, 1.);
}
