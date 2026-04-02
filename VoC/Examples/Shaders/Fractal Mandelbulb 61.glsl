#version 420

// original https://www.shadertoy.com/view/stXSRB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_DIST 1e1
#define MAX_STEPS 1024
#define SURF_DIST 1e-4

float sphereSDF(vec3 p, float r) {
    return length(p) - r;
}

float cubeSDF(vec3 p, vec3 s) {
    vec3 q = abs(p) - s;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float torusSDF(vec3 p, vec2 t) {
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

float mandelbulbSDF(vec3 p, float power, out float t) {
    vec3 z = p;
    float dr = 1.0;
    float r = 0.0;
    t = 1.0;
    for(int i = 0; i < 4; i++) {
        // convert to polar coordinates
        float theta = acos(clamp(z.z/r, -1.0, 1.0));
        float phi = atan(z.y,z.x);
        dr =  pow(sqrt(r), power-1.0)*power*dr + 1.0;

        // scale and rotate the point
        float zr = pow(r, power);
        theta = theta * power;
        phi = phi * power;

        // convert back to cartesian coordinates
        z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        z += p;

        t = min(t, length(z));
        r = length(z);
        if (r > 2.0) break;
    }
    return 0.5*log(r)*sqrt(r)/dr;
}

float sceneSDF(vec3 p, out int mat, out float t) {
    float b = cubeSDF(p, vec3(1.25));
    if(b > SURF_DIST) return b; // bounding box will increase the peformance a little

    float a = mandelbulbSDF(p, 6.0+sin(time/2.0)*3.0, t);
    float d = a;
    if(d == a) mat = 0;

    return d;
}

vec3 GetNormal(vec3 p) {
    vec2 e = vec2(SURF_DIST, 0.0);
    int t;
    float tmp;

    return normalize(
        sceneSDF(p, t, tmp) - vec3(
            sceneSDF(p - e.xyy, t, tmp),
            sceneSDF(p - e.yxy, t, tmp),
            sceneSDF(p - e.yyx, t, tmp)
        )
    );
}

float RayMarch(vec3 ro, vec3 rd, out int mat, out float t) {
    float dO = 0.0;
    int id;
    for(int i = 0; i < MAX_STEPS; i++) {
        float dS = sceneSDF(ro + rd * dO, id, t);
        dO += dS;
        if(dS < SURF_DIST) {
            mat = id;
            break;
        }
        if(dO > MAX_DIST) {
            mat = -1;
            break;
        }
    }
    return dO;
}

mat3 rot(vec3 ang) {
    vec3 s = sin(ang);
    vec3 c = cos(ang);
    mat3 x = mat3(
        vec3(1, 0, 0),
        vec3(0, c.x,-s.x),
        vec3(0, s.x, c.x)
    );
    mat3 y = mat3(
        vec3(c.y, 0, s.y),
        vec3(0, 1, 0),
        vec3(-s.y, 0, c.y)
    );
    mat3 z = mat3(
        vec3(c.z, s.z, 0),
        vec3(-s.z, c.z, 0),
        vec3(0, 0, 1)
    );
    return x*y*z;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-0.5*resolution.xy)/max(resolution.x, resolution.y);
    vec3 ro = vec3(0, 0, -6);
    vec3 rd = normalize(vec3(uv, 1));
    vec2 t = (mouse*resolution.xy.xy-0.5*resolution.xy)/max(resolution.x, resolution.y);
    t *= 4.0;
    vec2 mouse_rotation = t * 3.1415;
    if(length(mouse*resolution.xy.xy) < 1e-3) mouse_rotation = vec2(0);

    vec2 yawpitch = vec2(mouse_rotation.x, -mouse_rotation.y);
    mat3 viewmat = rot(vec3(yawpitch.y, yawpitch.x, 0));

    ro *= viewmat;
    rd *= viewmat;

    int mat = -1;
    float trap;
    float d = RayMarch(ro, rd, mat, trap);
    vec3 p = ro + rd * d;

    vec3 environment = vec3(0.4, 0.7, 0.8);
    vec3 col = environment;
    vec3 albedo = vec3(0);
    vec3 spc = vec3(0);
    float hardness = 0.0;
    if(d < MAX_DIST) {
        if(mat == 0) {
            albedo = vec3(sin(trap*10.0), sin(trap*20.0), cos(trap/2.0));
            spc = vec3(0.5);
            hardness = 10.0;
        }
        vec3 lpos = normalize(vec3(3, 5, -6));
        vec3 n = GetNormal(p);
        float dif = clamp(dot(n, lpos), 0.0, 1.0);
        float spec = pow(max(0.0, dot(reflect(-lpos, n), normalize(ro))), hardness);
        spec *= max(0.0, 0.25+max(0., dot(-n, normalize(ro)-n)));
        col = albedo*(dif+environment*0.5)+(spec*spc); // simple material system that im implementing on my old raytracer
    }
    if(mat == -1) col = environment; // sometime material on infinite plane results on black line
    col = pow(col, vec3(0.5));

    glFragColor = vec4(col,1.0);
}
