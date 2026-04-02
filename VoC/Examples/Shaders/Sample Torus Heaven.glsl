#version 420

// original https://www.shadertoy.com/view/ct2GDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_STEP = 80;
const float SURFACE_DIST = 0.02;
const float PI = radians(180.);

const vec2 torusr = vec2(0.85, 0.15)*0.5;

mat2 rot2d(float r)
{
float s = sin(r), c = cos(r);
return mat2(c,-s,s,c);
}
float random(vec2 s)
{
return fract(sin(dot(s, vec2(362.485, 123.445))*764.346)*2647.9752);
}

float plane(vec3 p)
{
return abs(p.y);
}
float sphere(vec3 p, float r)
{
return length(p)-r;
}
float torus(vec3 p, float a, float b)
{
return length(vec2(length(p.xz)-a, p.y))-b;
}
float cube(vec3 p, float r)
{
p = abs(p);
return length(max(p-r, 0.));
}

float map(vec3 p)
{
float angle = atan(1., 1.);
p.xz *= rot2d(angle);
//p.y += time*pow(-1., floor(p.z));
p = fract(p);
p -= 0.5;
float t0 = torus(p, torusr.x, torusr.y);
p.xy *= rot2d(PI*0.5);
p.z -= 0.5;
float t1 = torus(p, torusr.x, torusr.y);
p.z += 1.;
float t2 = torus(p, torusr.x, torusr.y);
return min(min(t0, t1), t2);
}

vec3 get_normal(vec3 p)
{
vec2 e = vec2(0.05, 0.);
float d = map(p);
return -normalize(vec3(
d-map(p+e.xyy),
d-map(p+e.yxy),
d-map(p+e.yyx)
));
}

float raymarch(vec3 vo, vec3 dir)
{
    float d = 0.;
    for (int i = 0; i < MAX_STEP; i++)
    {
    float cd = map(vo + dir*d);
    if (cd < SURFACE_DIST)
    break;
    d += cd;
    }
    return d;
}

void main(void) {
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy) / resolution.y;

    vec3 r0 = vec3(0.,1.,0.);
    vec3 dir = normalize(vec3(uv.xy, 1.));
    r0.z += time;
    //dir.xz *= rot2d(time);
    float d = raymarch(r0, dir);
    vec3 p = r0 + dir*d;

    glFragColor = vec4(0.3, 0., 1., 1.) / max(0.5, d);
}
