#version 420

// original https://www.shadertoy.com/view/ftKcDc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int TRACE_MAX_STEPS = 255;
const float TRACE_MAX_DIST = 10.;
const float TRACE_EPSILON = .001;
const float NORMAL_EPSILON = .001;
const vec3 eye = vec3(0., 0., 5.);
//const vec3 light = vec3(0.0, 1.0, 3.0);

mat3 rotateX(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

mat3 rotateY(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 rotateZ(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

float length8(in vec2 p)
{
    return pow(pow(abs(p.x), 8.)+pow(abs(p.y), 8.), 1./8.);
}

float lengthInf(in vec2 p)
{
    return max(abs(p.x), abs(p.y));
}

float intersectSDF(float d1, float d2)
{
    return max(d1, d2);
}

float unionSDF(float d1, float d2)
{
    return min(d1, d2);
}

float differenceSDF(float d1, float d2) {
    return max(d1, -d2);
}

float sphereSDF(in vec3 p, in vec3 c, in float r)
{
    return length(p-c)-r;
}

float boxSDF(in vec3 p, in vec3 size)
{
    vec3 pt = abs(p)-size;

    return length(max(pt, .0)) + min(max(pt.x, max(pt.y, pt.z)), .0);
}

float torusSDF( in vec3 pos, in vec2 t )
{
    vec3 pt = pos;
    vec2 q  = vec2(length8(pt.xz)-t.x, pt.y);
    return length8(q) - t.y;
}

float sceneSDF(in vec3 p, in mat3 m)
{
    vec3 q = p*m;
    float s = .25*sin(time);
    float scene = 1.;
    mat3 rot = rotateX(-.785)*rotateY(.25*time)*rotateZ(s);
    mat3 rot_i = mat3(1);
    for (float i = 0.; i < 11.; i++)
    {
        if (mod(i, 2.) == 0.)
            rot_i *= rotateX(.5*time); 
        else 
            rot_i *= rotateZ(.5*time);
        scene = unionSDF(scene, torusSDF(q*rot*rot_i, vec2(1.-.1*i, .05)));
    }
    return scene;
}

vec3 traceSDF(in vec3 from, in vec3 dir, out bool hit, in mat3 m)
{
    vec3 p = from;
    float totalDist = 0.;
    hit = false;
    for (int steps = 0; steps < TRACE_MAX_STEPS; steps++)
    {
        float dist = sceneSDF(p, m);
        if (dist < TRACE_EPSILON)
        {
            hit = true;
            break;
        }
        totalDist += dist;
        if (totalDist > TRACE_MAX_DIST)
            break;
        p += .8*dir*dist;
    }
    return p;
}

vec3 calcNormal(vec3 p, float d, in mat3 m)
{
    float e = max(d*.5, NORMAL_EPSILON);
    return normalize(vec3(
        sceneSDF(p+vec3(e, 0, 0), m)-sceneSDF(p-vec3(e, 0, 0), m),
        sceneSDF(p+vec3(0, e, 0), m)-sceneSDF(p-vec3(0, e, 0), m),
        sceneSDF(p+vec3(0, 0, e), m)-sceneSDF(p-vec3(0, 0, e), m)
    ));
}

float ambientOcclusion(in vec3 pos, in vec3 normal, mat3 m)
{
    float occ = .0;
    float sca = 1.;
    for (int i = 0; i < 5; i++)
    {
        float h = .01+.12*float(i)/4.;
        float d = sceneSDF(pos+h*normal, m);
        occ += (h-d)*sca;
        sca *= .95;
        if (occ > .35) 
            break;
    }
    return clamp(1.-3.*occ, 0., 1.)*(.5+.5*normal.y);
}

void main(void)
{
    //vec3 mouse = vec3(mouse*resolution.xy.x/resolution.xy - 0.5, mouse*resolution.xy.z);
    //mat3 m = rotateX(6.0 * mouse.y) * rotateY(6.0 * mouse.x);
    mat3 m = mat3(1);
    vec2 uv = 5.*(gl_FragCoord.xy-.5*resolution.xy)/max(resolution.x, resolution.y);
    vec3 dir = normalize(vec3(uv, 0)-eye);
    bool hit;
    vec3 p = traceSDF(eye, dir, hit, m);
    vec4 color = vec4(.1, .1, .1, 1);
    vec3 light = vec3(2.*sin(0.5*time), 2.*cos(0.5*time), 1)*rotateX(-.785);
    if (hit)
    {
        vec3 l = normalize(light - p);
        vec3 n = calcNormal(p, .001, m);
        float nl = max(.0, dot(n, l));
        
        vec3 v = normalize(eye - p);
        vec3 h = normalize(l + v);
        float hn = max(.0, dot(h, n));
        float sp = pow(hn, 100.);
        
        vec4 colorDiffuse = vec4(1, .5, 0, 1);
        vec4 colorPhong = vec4(1);
        vec4 colorAbmient = vec4(1, .5, 0, 1);
        color = colorDiffuse*vec4(nl)
            + colorPhong*sp
            + .25*colorAbmient*ambientOcclusion(p, n, m);
    }
    glFragColor = color;
}
