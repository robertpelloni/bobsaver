#version 420

// original https://www.shadertoy.com/view/ldcSR8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float length8(vec2 p) {
    float d2 = pow(abs(p.x), 8.0) + pow(abs(p.y), 8.0);
    return pow(d2, 1./8.);
}
float dTorus(vec3 p, vec2 t) {
    vec2 d = vec2(length8(p.xz) - t.x, p.y);
    return length8(d) - t.y;
}

float dBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

void rotate(inout vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);
    
    p = mat2(c, s, -s, c)*p;
}

struct MarchResult {
    float d;
    float mid;
    
    bool reflection;
    float reflect_amount;
    
    bool refraction;
    float refract_eps;
    float refract_dist;
    float refract_amount;
};

MarchResult opU(MarchResult a, MarchResult b) {
    if(a.d < b.d) return a;
    return b;
}

MarchResult map(vec3 p) {
    MarchResult pl = MarchResult(p.y + 1.0, 1.0, false, 0.0, false, 0.0, 0.0, 0.0);
    MarchResult s = MarchResult(length(p) - 1.0, 2.0, false, 0.0, true, 0.98, 1.7, .5);
    p.x -= 2.0;
    MarchResult b = MarchResult(dBox(p, vec3(.5, 1, .5)), 3.0, false, 0.0, true, 1.0, 3.0, .5);
    p.xy += vec2(1.0, -1.5);
    rotate(p.xz, time);
    p.x -= 1.0;
    MarchResult t = MarchResult(dTorus(p, vec2(1, .3)), 4.0, false, 0.0, true, 0.99,  1.8, .5);
    p.x -= 1.7;
    p.y += 1.5;
    MarchResult s2 = MarchResult(length(p) - 0.7, 5.0, true, 1.0, false, 0.0, 0.0, 0.0);
    
    return opU(pl, opU(s, opU(b, opU(t, s2))));
}

MarchResult spheretrace(vec3 ro, vec3 rd, float tmin, float tmax) {
    float td = tmin;
    MarchResult res = MarchResult(0., 0., false, 0.0, false, 0.0, 0.0, 0.0);
    
    for(int i = 0; i < 128; i++) {
        MarchResult s = map(ro + rd*td);
        if(abs(s.d) < 0.00002 || td > tmax) break;
        
        td += s.d*0.5;
        res = s;
    }
    
    res.d = td;
    if(td >= tmax) { res.mid = -1.0; res.reflection = false; res.refraction = false; }
    return res;
}

vec3 normal(vec3 p) {
    vec2 h = vec2(0.01, 0.0);
    vec3 n = vec3(
        map(p + h.xyy).d - map(p - h.xyy).d,
        map(p + h.yxy).d - map(p - h.yxy).d,
        map(p + h.yyx).d - map(p - h.yyx).d
    );
    
    return normalize(n);
}

float shadow(vec3 p, vec3 l) {
    float res = 1.0;
    float td = 0.002;
    
    for(int i = 0; i < 64; i++) {
        float h = map(p + l*td).d;
        if(abs(h) < 0.001 || td > 5.0) break;
        td += h*0.5;
        res = min(res, 8.0*h/td);
    }
    
    return clamp(res, 0.0, 1.0);
}

vec3 lighting(vec3 p, vec3 lp, vec3 rd) {
    vec3 l = normalize(lp);
    vec3 n = normal(p);
    vec3 r = reflect(l, n);
    
    float amb = clamp(0.8 + 0.1*n.y, 0.0, 1.0);
    float dif = clamp(dot(n, l), 0.0, 1.0);
    float spe = pow(clamp(dot(rd, r), 0.0, 1.0), 16.0);
    
    dif *= shadow(p, l);
    
    vec3 lin = vec3(0);
    
    lin += 0.5*amb*vec3(1);
    lin += dif*vec3(.97, .97, 1);
    lin += spe*vec3(1)*dif;
    
    return lin;
}

vec3 material(float mid, vec3 p) {
    vec3 col = vec3(1);
    
    if(mid == 1.0) {
        col = vec3(1)*mod(floor(p.x) + floor(p.z), 2.0);
    }
    if(mid == 2.0) col = vec3(.1, 1, .1);
    if(mid == 3.0) col = vec3(.3, .3, 1);
    if(mid == 4.0) col = vec3(1, .3, .3);
    
    return col;
}

struct RenderResult {
    MarchResult march;
    vec3 p;
    vec3 d;
    
    vec3 m;
};

RenderResult renderRefract(MarchResult i, vec3 p, vec3 rd, vec3 lp) {
    vec3 r = refract(rd, normal(p), i.refract_eps);
    MarchResult refr = spheretrace(p, r, i.refract_dist, 20.0);
    vec3 q = p + r*refr.d;
    vec3 m = material(refr.mid, q)*lighting(p, lp, rd);
    
    return RenderResult(refr, q, r, m);
}

RenderResult renderReflect(MarchResult i, vec3 p, vec3 rd, vec3 lp) {
    vec3 r = reflect(rd, normal(p));
    MarchResult ref = spheretrace(p, r, 0.0001, 60.0);
    vec3 q = p + r*ref.d;
    vec3 m = material(ref.mid, q)*lighting(p, lp, rd);
    
    return RenderResult(ref, q, r, m);
}

vec3 render(vec3 ro, vec3 rd, vec3 lp) {
    MarchResult i = spheretrace(ro, rd, 0.0, 20.0);
    vec3 p = ro + rd*i.d;
    vec3 m = material(i.mid, p)*lighting(p, lp, rd);
    RenderResult r = RenderResult(i, p, rd, m);
    
    for(int i = 0; i < 3; i++) {
        if(!r.march.refraction && !r.march.reflection) break;
        if(r.march.refraction) {
            RenderResult r2 = renderRefract(r.march, r.p, r.d, lp);
            m = mix(m, r2.m, r.march.refract_amount);
            r = r2;
        } else if(r.march.reflection) {
            RenderResult r2 = renderReflect(r.march, r.p, r.d, lp);
            m = mix(m, r2.m, r.march.reflect_amount);
            r = r2;
        }
    }
    
    return m;
    
}

mat3 camera(vec3 e, vec3 l) {
    vec3 rl = vec3(0, 1, 0);
    vec3 f = normalize(l - e);
    vec3 r = cross(rl, f);
    vec3 u = cross(f, r);
    
    return mat3(r, u, f);
}

void main(void)
{
    vec2 uv = -1.0+2.0*(gl_FragCoord.xy / resolution.xy);
    uv.x *= resolution.x/resolution.y;
    vec2 mo = vec2(0.0,0.0);//mouse*resolution.xy.xy/resolution.xy;
    
    vec3 ro = 4.0*vec3(cos(2.0*3.14*mo.x), 0.7 + 0.8*mo.y, -sin(2.0*3.14*mo.x));
    vec3 rd = camera(ro, vec3(.5, 0, 0))*normalize(vec3(uv, 2.0));
    
    vec3 lp = vec3(-1, 2, 0);
    
    vec3 rend = render(ro, rd, lp);
    
    glFragColor = vec4(rend, 1.0);
}
