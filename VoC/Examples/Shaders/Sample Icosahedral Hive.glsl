#version 420

// original https://www.shadertoy.com/view/wsGXzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 100.
#define MAX_DIST 2.8
#define DIFF_EPS 0.001
#define SHAD_EPS 0.004
#define vdouble(p, v) min(length(p - v), length(p + v))

#define M_PI   3.1415926
#define M_2_PI 6.2831853
#define M_PI_2 1.5707963
#define PHI 1.6180339
#define INV_PHI 0.61803398

/* SDF functions */

float opUnion(float d1, float d2, float k) {
    float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
    return mix(d2, d1, h ) - k*h*(1.0-h);
}

float opSubstr(float d2, float d1, float k) {
    float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0);
    return mix(d2, -d1, h ) + k*h*(1.0-h);
}

/* quaternions */

vec4 qmult(vec4 p, vec4 q) {
    vec3 pv = p.xyz, qv = q.xyz;
    return vec4(p.w * qv + q.w * pv + cross(pv, qv), p.w * q.w - dot(pv, qv));
}

vec4 qrotor(vec3 axis, float phi) {
    phi *= 0.5;
    return vec4(sin(phi) * normalize(axis), cos(phi));
}

vec3 rotate(vec3 point, vec4 rotor) {
    vec3 rotv = rotor.xyz;
    return qmult(rotor, vec4(point * rotor.w - cross(point, rotv), dot(point, rotv))).xyz;
}

float vicosahedron(vec3 p, float r0, float h) {
    float hPhi = h * PHI;
    float d = vdouble(p, vec3( h, hPhi, 0.));
    d = min(d, vdouble(p, vec3(-h, hPhi, 0.)));
    d = min(d, vdouble(p, vec3(hPhi, 0., h)));
    d = min(d, vdouble(p, vec3(hPhi, 0.,-h)));
    d = min(d, vdouble(p, vec3(0., h, hPhi)));
    d = min(d, vdouble(p, vec3(0.,-h, hPhi)));
    return d - r0;
}

float map(vec3 p) {    
    float r = length(p);
    float phi = atan(p.y / p.x);
    float tetha = acos(p.z / r);
    float displace = 0.01 * cos(20. * (phi + tetha)) * sin(tetha);
    float d = r - 0.9 + displace;
    d = opSubstr(d, vicosahedron(p, 0.4, 0.45), 0.1);
    d = min(d, vicosahedron(p, 0.4, 0.3));
    d = opSubstr(d, vicosahedron(p, 0.2, 0.41), 0.03);
    return min(d, r - .65 - 0.005 * sin(2.*time));
}

vec3 normal(vec3 pos) {
    vec2 e = vec2(DIFF_EPS, 0.);
    vec3 N = vec3(    map(pos + e.xyy) - map(pos - e.xyy),
                    map(pos + e.yxy) - map(pos - e.yxy),
                    map(pos + e.yyx) - map(pos - e.yyx));
       return normalize(N);
}

vec2 rayCast(vec3 camera, vec3 dir) {
    vec3 pos;
    float t = 0., dt = MAX_DIST, I;
    for(float i = 0.; i < MAX_STEPS; i++) {
        if(dt < DIFF_EPS || t > MAX_DIST) break;
        pos = camera + t * dir;
        dt = map(pos);
        t += dt;
        I = i;
    }
    return vec2(mix(t, -1., step(MAX_DIST, t)), I / MAX_STEPS);
}

void main(void) {
    
    vec2 uv = (2. * gl_FragCoord.xy - resolution.xy) / resolution.y;    
    vec3 camera = vec3(0., 0., -2.5);
    vec3 dir = normalize(vec3(uv, 2.));
    vec3 sun_dir = normalize(vec3(-2., 2., -2.));
    vec3 sky_dir = normalize(vec3(0.,1.,-0.2));
    
    vec2 mouse = mix(vec2(0.5-.1*sin(M_PI+.4*time), 0.5+.1*cos(.4*time)), mouse*resolution.xy.xy / resolution.xy, step(0.0027, mouse*resolution.xy.y));
    vec4 rotor = qrotor(vec3(0., 1., 0.), M_2_PI * mouse.x);
    rotor = qmult(rotor, qrotor(vec3(1., 0., 0.), M_PI_2 - M_PI*mouse.y));
    camera = rotate(camera, rotor);
    dir = rotate(dir, rotor);
    sun_dir = rotate(sun_dir, rotor);
    sky_dir = rotate(sky_dir, rotor);
    
    vec2 result = rayCast(camera, dir);
    float t = result.x;
       vec3 pos = camera + t * dir;
    vec3 N = normal(pos);
    vec3 R = reflect(dir, N);
    
    float sun_dif = clamp(.2+.8* dot(N, sun_dir), 0., 1. );
    float sun_sha = step(rayCast(pos + N * SHAD_EPS, sun_dir).x, 0.);
    float sky_dif = clamp(.5 + .5 * dot(N, sky_dir), 0., 1.);
    vec3 bg = vec3(.4, .1, .2) + 0.7 * exp(0.5 - length(uv)) ;

    vec3 col = vec3(.1, .3, .4) * sun_dif * sun_sha;
    col += vec3(.6, .2, .2) * sky_dif;
    col -= vec3(.3, .1, .1) * smoothstep(.0, .3, result.y);
    col -= .1 * smoothstep(0.0, .4, rayCast(pos + R * 0.01, R)).x;
    col.r = smoothstep(0.0, .8, col.r);
    col = mix(bg, col, step(0., t));
    
    glFragColor = vec4(sqrt(col), 1.0);
}
