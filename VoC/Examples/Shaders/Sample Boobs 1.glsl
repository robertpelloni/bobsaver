#version 420

// original https://www.shadertoy.com/view/4dd3zH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R resolution
#define T time

vec3 ro;
vec3 rd;
vec3 light;
vec3 dir;

struct RAY
{
    vec3 p;
    float l;
    float d;
};

float plane(in vec3 p, vec4 n)
{
    return dot(p, n.xyz) + n.w;
}

float sphere(in vec3 p, vec4 s)
{
    return length(p - s.xyz) - s.w;
}

float blob(float a, float b, float coef)
{
    return dot(a, b) / coef;
}

float cut(float a, float b)
{
    return max(a, b);
}

float sub(float a, float b)
{
    return max(-a, b);
}

mat3 md()
{
    return mat3(1.,0.,0.,0.,1.,0.,0.,0.,1.);
}

mat3 rotx(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat3(1.,0.,0.,0.,c,-s,0.,s,c);
}

mat3 roty(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat3(c,0.,s,0.,1.,0.,-s,0.,c);
}

mat3 rotz(float a)
{
    float c = cos(a);
    float s = sin(a);
    return mat3(c,-s,0.,s,c,0.,0.,0.,1.);
}

vec3 rot(in vec3 p, vec3 a, vec3 c)
{
    p -= c;
    return c + p * md() * rotx(a.x) * roty(a.y) * rotz(a.z); 
}

float scene(in vec3 p)
{       
    float s1 = sin(T);
    float s2 = .2 + sin(T - .2);
    
    vec3 nipPosL = vec3(-1.9,s1,0);
    vec3 titPosL = vec3(-1.5,.1 + s2,-2.15);
    vec3 mlPos = vec3(-1.6,s2,-1.5);
    vec3 nipPosR = vec3(1.9,s1,0);
    vec3 titPosR = vec3(1.5,.1 + s2,-2.15);
    vec3 mrPos = vec3(1.6,s2,-1.5);
    vec3 a = vec3(radians((-50. + R.y / 2.) / 16.), 0.,0);
    
    titPosL = rot(titPosL, a, nipPosL);
    mlPos = rot(mlPos, a,nipPosL);
    titPosR = rot(titPosR, a, nipPosR);
    mrPos = rot(mrPos, a, nipPosR);
    
    float nipL = sphere(p, vec4(nipPosL,2));
    float nipR = sphere(p, vec4(nipPosR,2));
    float titL = sphere(p, vec4(titPosL,.02));
    float titR = sphere(p, vec4(titPosR,.02));
    float mL = sphere(p, vec4(mlPos,.6));
    float mR = sphere(p, vec4(mrPos,.6));
    return min(blob(nipL, blob(mL, titL, 1.), 2.), blob(nipR, blob(mR, titR, 1.), 2.));
}

RAY trace(float maxd)
{
    RAY r = RAY(ro, 2., .001);
    for (int i = 0; i < 128; ++i)
    {
        if (abs(r.d) < .001 || r.l > maxd)
            break;
        r.l += r.d;
        r.p = ro + rd * r.l;
        r.d = scene(r.p);
    }
    return r;
}

void init(in vec2 uv)
{
    ro = vec3(0,.6,-4);
    rd = normalize(vec3(uv, 1));
    light = vec3(0,4,-8);
    dir = normalize(vec3(0,0,-1));
}

void main(void)
{
    glFragColor.rgb = vec3(0);
    vec2 uv = 2. * gl_FragCoord.xy / R.xy - 1.;
    uv.x *= R.x / R.y;
    init(uv);
    RAY r = trace(100.);
    if (r.l < 100.)
    {
        vec3 c = mix(vec3(1.,.83,.73), vec3(.98,.7,.6), vec3(-r.p.z));
        vec3 e = vec3(.00001, 0, 0);
        vec3 n = vec3(r.d) - vec3(scene(r.p - e.xyy), scene(r.p - e.yxy), scene(r.p - e.yyx));
        float b = dot(normalize(n), normalize(light - r.p));
        glFragColor.rgb = (b * c + 0.02 * pow(b, 42.)) * (1. - r.l * .01);
    }
}
