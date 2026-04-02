#version 420

// original https://www.shadertoy.com/view/wslcWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define MAXIT 128
#define EPSILON 0.001

#define minx(a, b) ((a.w) < (b.w) ? (a) : (b))
#define maxx(a, b) ((a.w) > (b.w) ? (a) : (b))

float t;

float sphere(vec3 r, float a)
{
    return length(r) - a;
}

float bat(vec3 r, float a)
{
    r *= mat3(
        cos((r.x * sin(t * 20.) * 0.5) * 1.), -sin((r.x * sin(t * 20.) * 0.5) * 1.), 0., 
        sin((r.x * sin(t * 20.) * 0.5) * 1.), cos((r.x * sin(t * 20.) * 0.5) * 1.), 0.,
        0., 0., 1.
    );
    float d = (abs(r.x*r.y)*3. + 1./a) * (abs(sqrt(r.y+0.1) * r.y) + sin(r.y) + 1./a) * (abs(r.z) + 1./a);
    return length(r) - 1./ d;
}

float plane(vec3 r, vec3 o, vec3 n) {
    return dot(r - o, n);
}

float box(vec3 r, vec3 a)
{
    r.x += sin(r.y * PI) * 0.1;
    vec3 p = abs(r) - a * (sin(length(abs(abs(r)*4. - 2.) * 8.)) + 2.);
    return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.);
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

vec4 map(vec3 r)
{
    obj = mat3(
        cos(sin(-t + r.z * 0.2) * 0.31), -sin(sin(-t+r.z * 0.2) * 0.51), 0., 
        sin(sin(-t + r.z * 0.2) * 0.41), cos(sin(-t+r.z * 0.2) * 0.51), 0.,
        0., 0., 1.
    );
    
    float z = r.z;
    
    vec4 s0 = vec4(
        vec3(0.0, 0.8, 0.) * 0.8,
        bat(mat3(3.) * (obj * mod(r + 1. - vec3(cos(t*2. * 0.785 + z) * 0.5+ 0.5, sin(t*2. * 0.785 + z) * 0.25, t) + 0.45, 4.) - 1.), 1.3)
    );
    vec4 b1 = vec4(
        vec3(0.3, 0.1, 2.3) * 0.12,
        box((mod(r + 3.0, 4.) - 1.0), vec3(0.1, 4., 0.1))
    );
    
    return minx(s0, b1);
}

float hash(vec2 r) {
    return fract(sin(dot(r, vec2(12.9898, 78.233))) * 43758.5453);
}

void main(void)
{
    t = time;
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    
    mat3 cam = mat3(
        cos(sin(t) * 0.1), -sin(sin(t) * 0.1), 0., 
        sin(sin(t) * 0.1), cos(sin(t) * 0.1), 0.,
        0., 0., 1.
    ) * mat3(
        1., 0., 0.,
        0., cos(0.15), -sin(0.15), 
        0., sin(0.15), cos(0.15)
    );
        
    vec3 ro = vec3(0., - 0.5, - 1.0 + t);
    vec3 rd = cam * normalize(vec3(uv, -1.));
    vec3 r = ro;
    
    vec4 col = vec4(1.);
    vec3 bcol = vec3(1., 0.0, 0.2) + 0.0;
    
    vec4 c = vec4(bcol, 1.);
    
    float sh = 1.;
    
    float rs = 0.;
    
    for (int i = 0; i < MAXIT; ++i) {
        vec4 d = map(r);
        float z = length(r - ro);
        
        vec4 nc = minx(c, d);
        c.rgb = mix(nc.rgb, c.rgb, nc.w / c.w);
        c.w = nc.w;
        
        if (d.w < EPSILON) {
            col.rgb = d.rgb * shade(normalize(r), rd);
            col.rgb = d.rgb;
            col.rgb = fog(z * 0.1, col.rgb, bcol);
            break;
        }
        
        d.w *= 0.7 - 0.1 * hash(uv);
        r += rd * clamp(d.w, -0.5, 0.5) * 0.7;
        
        sh += (float(i) / float(MAXIT));
    }
    
    col.rgb *= exp(-sh * sh * 0.02);
    
    if (c.w > EPSILON) {
        col.rgb = fog(c.w, c.rgb, bcol * 0.1) * 0.2;
    }
    
    glFragColor = vec4(col.rgb, 1.);
}
