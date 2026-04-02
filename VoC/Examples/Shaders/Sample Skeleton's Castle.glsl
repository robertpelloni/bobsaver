#version 420

// original https://www.shadertoy.com/view/tlGfRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define MAXIT 200
#define EPSILON 0.38
#define STEP 0.1
 
#define minx4(a, b) ((a.w) < (b.w) ? (a) : (b))
#define minx2(a, b) ((a.x) < (b.x) ? (a) : (b))

#define BONE 1.
 
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
    vec3 p = (abs(r) - a) * 2.0;
    
    p = p * 0.5 + 0.5 * p * rotX(r.y / 3.);
    p = p * 0.5 + 0.5 * p * rotZ(r.y / 3.);
    p.z = clamp(p.x * (sin(p.z)-1.0) + p.x * abs(p.y - a.y) * 0.5, -a.z, a.z);
    p.y = clamp(p.y + p.z * abs(p.x - a.x) * 0.5, -a.y, a.y);
    p.y += p.x * p.z + p.y * sin(p.z * 4.);
    p.x += clamp(p.x * p.y, -a.z * 0.5, a.z * 0.5);
    
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
    float tt = t * 2.;
    float ttt = tt / 2. + sin(tt) / 2.;
    obj = rotY(ttt) * rotX(0.6 + cos(tt) * 0.2);
    vec3 rb1 = obj * r;
    rb1.x += 20. * (ttt / 2. / PI) + 10.;
    
    rb1 *= rotX(rb1.z * 0.005);
    vec3 rbp1 = mod(rb1+10., 20.) - 10.;
    
    vec2 b1 = vec2(
        box(rbp1, vec3(2., 2., 2.)), BONE
    );

    return b1;
}

vec3 matCol(vec2 o)
{
    if (o.y == BONE)
        return vec3(0.5, 0.5, 0.5);
    
    return vec3(0., 0., 0.);
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
   
    vec3 bcol = vec3(1.0, 1.0, 1.0) * 0.4;
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
            col.rgb = fog(z * 0.03, col.rgb, bcol);
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
