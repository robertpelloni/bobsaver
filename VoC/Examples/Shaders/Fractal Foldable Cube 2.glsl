#version 420

// original https://www.shadertoy.com/view/ttdGW8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ITERS 100
#define TOL 1e-3
#define fdist 0.5
#define maxdist 10.
#define LEVELS 9
#define PI 3.1415926

float oscillate(float t_low, float t_high, float t_transition, float t_offset) {
    float t_osc = 0.5*(t_high+t_low)+t_transition;
    float h_l = 0.5*t_low/t_osc;
    float h_h = (0.5*t_low+t_transition)/t_osc;
    return smoothstep(0., 1., (clamp(abs(mod(time + t_offset, t_osc*2.)/t_osc-1.), h_l, h_h) - h_l) / (h_h - h_l));
}

vec4 map(in vec3 pos)   
{
    float t = oscillate(2., 2., 7., 0.) * PI * 0.5;
    float t2 = oscillate(7., 7., 2., 5.);
    //if (mouse*resolution.xy.w > 1.0)
    //{
    //    t = mouse*resolution.xy.y/resolution.y*PI*0.5;
    //}
    float c = cos(t);
    float s = sin(t);
    mat3 rotZ = mat3(c, -s, 0, s, c, 0, 0, 0, 1);
    mat3 rotX = mat3(1, 0, 0, 0, c, -s, 0, s, c);
    float sc = 0.5;
    float truncdist = -1e6;
    for (int i=0; i<LEVELS; i++)
    {
        pos = abs(rotX * rotZ * pos) - sc;
        truncdist = max(truncdist, (pos.x+pos.y+pos.z)/sqrt(3.)-(2.-t2)*sc);
         sc *= 0.5;
    }
    vec3 bx = max(vec3(0.), pos-sc*2.);
    float dist = max(truncdist, length(bx));
    return vec4(dist, step(pos.zxy, pos.xyz) * step(pos.yzx, pos.xyz));
}

vec3 getnormal(vec3 ro) {
    vec2 d = vec2(TOL, 0.0);
    float x1 = map(ro+d.xyy).x;
    float x2 = map(ro-d.xyy).x;
    float y1 = map(ro+d.yxy).x;
    float y2 = map(ro-d.yxy).x;
    float z1 = map(ro+d.yyx).x;
    float z2 = map(ro-d.yyx).x;
    return normalize(vec3(
        x1-x2,
        y1-y2,
        z1-z2));
}

vec4 march(in vec3 pos, in vec3 dir)
{
    float t = 0.;
    vec4 dist;
    int i=0;
    for (; i<ITERS; i++)
    {
        vec3 currpos = t*dir+pos;
        dist = map(currpos);
        t += dist.x;
        if (abs(dist.x) < TOL)
        {
            return vec4(t, dist.yzw);
        } else if (t > maxdist) {
            break;
        }
    }
    return vec4(t, vec3(-1., t/maxdist*0.8, float(i)/float(ITERS)));
}

float shadowmarch(in vec3 pos, in vec3 dir) {
    float t = 0.;
    for (int i=0; i<50; i++) {
        vec3 currpos = t*dir+pos;
        float dist = map(currpos).x;
        if (dist <= 0.) return 0.;
        t += max(0.01, dist);
        if (t > maxdist) break;
    }
    return 1.;
}

void main(void)
{
    float ang = time * 0.3;
    //if (mouse*resolution.xy.z > 1.0) {
    //    ang = mouse*resolution.xy.x/resolution.x*PI*2.;
    //}
    float c = cos(ang);
    float s = sin(ang);
    mat3 rot = mat3(c, -s, 0, s, c, 0, 0, 0, 1);
    vec2 uv = (gl_FragCoord.xy-resolution.xy*0.5)/resolution.x;
    vec3 ro = rot * vec3(1.,1.,1.) * (2.+s*0.3);
    vec3 nw = -normalize(ro);
    vec3 up = vec3(0.,0.,1.);
    vec3 nu = cross(nw, up);
    vec3 nv = cross(nu, nw);
       vec3 rd = normalize(nw*fdist + uv.x*nu + uv.y*nv);
    vec4 d = march(ro, rd);
    vec3 pos = d.x * rd + ro;
    vec3 n = getnormal(pos);
    vec3 col = vec3(0.);
    if (d.y > -0.5) {
        vec3 albedo = d.yzw + 0.75*d.wyz;
        vec3 lightdir = normalize(vec3(1., 0.5, 2.));
        float origfac = dot(n, lightdir);
        float fac = max(0., origfac);
        float shadowfac = shadowmarch(pos+lightdir*TOL, lightdir);

        float ambfac = abs(origfac);
        float occfac = clamp(map(pos + n * 0.25).x*4., 0., 1.);
        col = occfac*(fac * shadowfac + vec3(0.25) * ambfac) * albedo;
    } else {
        col = vec3(d.z, d.w, d.w);
    }
    glFragColor = vec4(pow(col, vec3(0.45)),1.0);
}
