#version 420

// original https://www.shadertoy.com/view/3sy3Dy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//2D Vector field visualizer by nmz (twitter: @stormoid)
//Added moving charges and equipotential lines (@allexev)
#define u_time time
#define pi 3.1415926535897932384626433832795

const float arrow_density = 1.7;
const float arrow_length = 0.5;

//---------------Field to visualize defined here-----------------
vec2 field(in vec2 p)
{
    return vec2(sin(p.x+sin(p.y)+u_time), sin(p.x+cos(p.y)));
}

vec3 fieldGrav(vec2 p) {
    float time_coeff = 2.;
    vec3 s = vec3(0.);
    float r = 3.5+sin(u_time/10.*time_coeff);
    float phi = -3.5+u_time/20.*time_coeff;
    float mk = 1.4;
    const int n_iter = 7;
    for (int i = 0; i < n_iter; i++) {
        float fi = float(i) / float(n_iter) * 2. * pi;
        vec2 pos = vec2(r*cos(fi+phi+sin(u_time/10.*time_coeff)), r*sin(fi+phi));
        float d = distance(pos, p);
        float m = mk * sin(fi + pi / 10.);
        vec2 a = m * (pos - p) / pow(d, 3.);
        s += vec3(a, sign(m) * length(a));
    }
    return s;
}
//---------------------------------------------------------------

float segm(in vec2 p, in vec2 a, in vec2 b) //from iq
{
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0., 1.);
    return length(pa - ba*h)*30.;
}

float fieldviz(in vec2 p, vec2 t)
{
    vec2 ip = floor(p*arrow_density) / arrow_density + .5/arrow_density;   
    float m = pow(length(t), .5) * (arrow_length/arrow_density);
    vec2 b = normalize(t)*min(m, .3);
    float rz = segm(p, ip, ip+b);
    vec2 prp = (vec2(-b.y, b.x));
    rz = min(rz,segm(p, ip+b, ip + b*.65 + prp*.3));
    return clamp(min(rz,segm(p, ip+b, ip + b*.65 - prp*.3)), 0., 1.);
}

float equipotentialLines(float fld)
{
    float a = 0.;
    const int n_lines = 29;
    for (int i = 0; i < n_lines; i++) {
        float f = float(i) - float(n_lines + 1) / 2.;
        f *= 0.1;
        float range = 111./(abs(f) + .4) - 11.;
        a = max(a, 1. - clamp(abs(fld - f) * range, 0., 1.));
    }
    return a;
}

void main(void)
{
    vec2 p = gl_FragCoord.xy / resolution.xy - 0.5;
    p.x *= resolution.x / resolution.y;
    p *= 10.;
    vec3 fld = fieldGrav(p);
    vec3 col = vec3(0.);
    float fviz = fieldviz(p, fld.xy);
    col = max(col, 1. - fviz*vec3(1.));
    col = max(col , equipotentialLines(fld.z));
    col.rb = max(col.rb, vec2(-fld.z, fld.z));
    glFragColor = vec4(col,1.0);
}
