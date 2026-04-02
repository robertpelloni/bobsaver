#version 420

// original https://www.shadertoy.com/view/tsfcWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265
#define MAXIT 50
#define EPSILON 0.01

#define minx(a, b) ((a.w) < (b.w) ? (a) : (b))

float sphere(vec3 r, float a)
{
    return length(r) - a;
}

float pointy(vec3 r, float a)
{
    float d = (abs(r.x*3.) + 1./a) * (abs(r.y) + 1./a) * (abs(r.z) + 1./a);
    return length(r) - 1./ d;
}

float plane(vec3 r, vec3 o, vec3 n) {
    return dot(r - o, n);
}

float box(vec3 r, vec3 a)
{
    vec3 p = abs(r) - a;
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
float t;

vec4 map(vec3 r)
{
    vec4 s0 = vec4(
        vec3(1.0, 0.2, 0.) * 1.2,
        pointy(obj * (mod(r + 1.0, 4.) - 1.0), 1.0)
    );
    vec4 s1 = vec4(
        vec3(0., 1., 1.) * 1.2,
        sphere(mod(r + 3.0 + vec3(
            cos(t*10.) * 0.2, 
            sin(t*10.) * 0.2, 
            sin(t)*1.5 + 2.), 4.) - 1.0, 0.05)
    );
    vec4 b0 = vec4(
        vec3(0., 0.4, 1.0) * 1.2,
        box(mod(r + 3.0, 4.) - 1.0, vec3(4., 0.05, 0.05))
    );
    vec4 b1 = vec4(
        vec3(0., 0.4, 1.0) * 1.2,
        box(mod(r + 3.0, 4.) - 1.0, vec3(0.05, 4., 0.05))
    );
    vec4 b2 = vec4(
        vec3(0., 0.4, 1.0) * 1.2,
        box(mod(r + 3.0, 4.) - 1.0, vec3(0.05, 0.05, 4.))
    );
    
    return minx(s0, minx(s1, minx(b0, minx(b1, b2))));
}

void main(void)
{
    t = time;
    
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv -= 0.5;
    uv.x *= resolution.x / resolution.y;
    
    mat3 cam = mat3(
        cos(t * 0.2), 0., sin(t * 0.2),
        0., 1., 0.,
        -sin(t * 0.2), 0., cos(t * 0.2)
    ) * mat3(
        cos(t * 0.2), -sin(t * 0.2), 0., 
        sin(t * 0.2), cos(t * 0.2), 0.,
        0., 0., 1.
    );
    
    obj = mat3(
        cos(t * 2.), 0., sin(t * 2.),
        0., 1., 0.,
        -sin(t * 2.), 0., cos(t * 2.)
    ) * mat3(
        cos(t * 1.5), -sin(t * 1.5), 0., 
        sin(t * 1.5), cos(t * 1.5), 0.,
        0., 0., 1.
    );
    
    vec3 ro = vec3(t, 0., .75 * sin(t * 0.785) - 2.);
    vec3 rd = cam * normalize(vec3(uv, 1.));
    vec3 r = ro;
    
    vec4 col = vec4(1.);
    vec3 bcol = vec3(1., 0.5, 0.0) + 0.2;
    
    vec4 c = vec4(bcol, 1.);
    
    float sh = 1.;
    
    for (int i = 0; i < MAXIT; ++i) {
        vec4 d = map(r);
        float z = length(r - ro);
        
        vec4 nc = minx(c, d);
        c.rgb = mix(nc.rgb, c.rgb, nc.w / c.w);
        c.w = nc.w;
        
        if (d.w < EPSILON) {            
            col.rgb = d.rgb * shade(normalize(r), rd);
            col.rgb = fog(z * 0.1, col.rgb, bcol);
            break;
        }
        
        r += rd * (clamp(d.w, -1., 1.)) * 0.8;
        sh += (float(i) / float(MAXIT)) / max(z, 1.);
    }
    
    col.rgb *= exp(-sh * sh * 0.03);
    
    if (c.w > EPSILON) {
        col.rgb = fog(c.w * 2., c.rgb, bcol);
    }
    
    glFragColor = vec4(col.rgb, 1.);
}
