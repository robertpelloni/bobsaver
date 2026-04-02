#version 420

// original https://www.shadertoy.com/view/wllXDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERS 100
#define TOL 1e-3
#define fdist 0.5
#define maxdist 100.
#define LEVELS 7
#define PI 3.1415926

float noise(in vec2 uv)
{
    return fract(sin(dot(vec2(148191., -1891589.), uv))*9991415.);   
}

float map(in vec3 pos)   
{
    float t = (clamp(abs(mod(time*0.25, 6.0) - 3.0), 1.0, 2.0)-1.0) * PI * 0.5;
    float c = cos(t);
    float s = sin(t);
    mat3 rotZ = mat3(c, -s, 0, s, c, 0, 0, 0, 1);
    mat3 rotX = mat3(1, 0, 0, 0, c, -s, 0, s, c);
    float sc = 0.5;
    for (int i=0; i<LEVELS; i++)
    {
        pos = abs(rotX * rotZ * pos) - sc;
         sc *= 0.5;
    }
    
    return max(pos.x, max(pos.y, pos.z))-sc*2.;
}

vec2 march(in vec3 pos, in vec3 dir)
{
    float t = 0.;
    for (int i=0; i<ITERS; i++)
    {
        vec3 currpos = t*dir+pos;
        float dist = map(currpos);
        t += dist * (1.+(noise(currpos.xy+dir.zx)-0.5)*0.5);
        if (abs(dist) < TOL)
        {
            return vec2(t, i);
        } else if (dist > maxdist) {
            return vec2(t, i);
        }
    }
    return vec2(t, ITERS);
}

void main(void)
{
    float c = cos(time);
    float s = sin(time);
    mat3 rot = mat3(c, -s, 0, s, c, 0, 0, 0, 1);
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.x;
    vec3 ro = rot * vec3(1.,1.,1.) * (2.+s*0.3);
    vec3 nw = -normalize(ro);
    vec3 up = vec3(0.,0.,1.);
    vec3 nu = cross(nw, up);
    vec3 nv = cross(nu, nw);
       vec3 rd = normalize(nw*fdist + uv.x*nu + uv.y*nv);
    vec2 d = march(ro, rd);
    glFragColor = vec4(vec3(d.y)/float(ITERS)*2.,1.0);
}
