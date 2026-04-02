#version 420

// original https://www.shadertoy.com/view/ldtSRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = 3.14159265359;

float dBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

//http://mercury.sexy/hg_sdf/
float repPolar(inout vec2 p, float rep) {
    float angle = 2.0*PI/rep;
    float a = atan(p.y, p.x) + angle/2.;
    float r = length(p);
    float c = floor(a/angle);
    a = mod(a, angle) - angle/2.;
    
    p = vec2(cos(a), sin(a))*r;
    return c;
}

void mirrorPolar(inout vec2 p, float an) {
    float a = atan(p.y, p.x);
    float r = length(p);
    a = abs(a) - an;
    
    p = vec2(cos(a), sin(a))*r;
}

void rotate(inout vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);
    
    p = mat2(c, s, -s, c)*p;
}

vec3 scene(vec3 p) {
    float c = repPolar(p.yz, 19.0);
    
    for(int i = 0; i < 5; i++)
        mirrorPolar(p.yx, 0.2);
    
    p.y -= 2.0;
    repPolar(p.xz, 6.0);
    vec3 b1 = vec3(
        dBox(p, vec3(.15, .5 + 0.2*sin(c + 5.0*time), .15)), 1.0 + abs(c), 0.1);
    
    return b1;
}

vec3 map(vec3 p) {
    vec3 w = vec3(length(p) - 2.0, 0.0, 0.05);
    
    vec3 s = scene(p);
    
    return w.x < s.x ? w : s;
}

vec3 spheretrace(vec3 ro, vec3 rd) {
    float td = 0.0;
    float mid = -1.0;
    float rc = 0.0;
    
    for(int i = 0; i < 128; i++) {
        vec3 s = map(ro + rd*td);
        if(abs(s.x) < 0.0001 || td > 10.0) break;
        td += s.x*0.5;
        mid = s.y;
        rc = s.z;
    }
    
    if(td > 10.0) { mid = -1.0; rc = 0.0; }
    return vec3(td, mid, rc);
}

vec3 normal(vec3 p) {
    vec2 h = vec2(0.001, 0.0);
    vec3 n = vec3(
        map(p + h.xyy).x - map(p - h.xyy).x,
        map(p + h.yxy).x - map(p - h.yxy).x,
        map(p + h.yyx).x - map(p - h.yyx).x
    );
    
    return normalize(n);
}

float shadow(vec3 p, vec3 l) {
    float res = 1.0;
    float td = 0.002;
    
    for(int i = 0; i < 64; i++) {
        float h = map(p + l*td).x;
        td += h;
        res = min(res, 8.0*h/td);
        if(h < 0.001 || td > 9.0) break;
    }
    
    return clamp(res, 0.0, 1.0);
}

vec3 lighting(vec3 p, vec3 lp, vec3 rd) {
    vec3 lig = normalize(lp);
    vec3 n = normal(p);
    vec3 ref = reflect(n, rd);
    
    float amb = clamp(0.7, 0.0, 1.0);
    float dif = clamp(dot(n, lig), 0.0, 1.0);
    float spe = pow(clamp(dot(ref, lig), 0.0, 1.0), 16.0);
        
    vec3 lin = vec3(0);
    
    lin += 0.4*amb*vec3(1);
    lin += dif*vec3(1, .97, .85);
    lin += spe*vec3(1)*dif;
    
    return lin;
}

vec2 reflectMarch(vec3 p, vec3 rd) {
    float td = 0.002;
    float mid = -1.0;
    
    for(int i = 0; i < 128; i++) {
        vec2 s = map(p + rd*td).xy;
        if(abs(s.x) < 0.0001 || td > 15.0) break;
        td += s.x*0.5;
        mid = s.y;
    }
    
    if(td > 15.0) mid = -1.0;
    return vec2(td, mid);
}

vec3 material(float mid, vec3 p) {
    vec3 col = vec3(.75);
    if(mid == 0.0) {
        col = abs(sin(p));
    }
    if(mid >= 1.0) {
        col = abs(vec3(sin(mid + p.x), tan(mid), cos(mid + p.z)));
    }
    
    return col;
}

vec3 render(vec3 ro, vec3 rd, vec3 lp) {
    vec3 i = spheretrace(ro, rd);
    vec3 p = ro + rd*i.x;
    
    if(i.y == -1.0) return material(i.y, p);
    
    vec3 m = material(i.y, p);
    m *= lighting(p, lp, rd);
    
    vec3 n = normal(p);
    
    vec3 ref = reflect(rd, n);
    vec2 r = reflectMarch(p, ref);
    vec3 q = p + ref*r.x;
    m = mix(m, material(r.y, q)*lighting(q, lp, rd), i.z);
    
    
    return m;
}

mat3 camera(vec3 e, vec3 l) {
    vec3 roll = vec3(0, 1, 0);
    vec3 f = normalize(l - e);
    vec3 r = normalize(cross(roll, f));
    vec3 u = normalize(cross(f, r));
    
    return mat3(r, u, f);
}

void main(void)
{
    vec2 uv = -1.0 + 2.0*(gl_FragCoord.xy / resolution.xy);
    uv.x *= resolution.x/resolution.y;
    
    float s = time*0.5;
    vec3 ro =  5.0*vec3(cos(s), 0.0, -sin(s));
    vec3 rd = camera(ro, vec3(0))*normalize(vec3(uv, 2.0));
    
    vec3 lp = vec3(-5.0, 8.0, 0.0);
    
    glFragColor = vec4(render(ro, rd, lp), 1.0);
}
