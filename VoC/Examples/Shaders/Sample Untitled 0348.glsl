#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159

float hash(float n) {
    return fract(sin(n)*43578.5453);
}

vec2 hash(vec2 n) {
    vec2 x = vec2(
        dot(n, vec2(171.0, 311.0)),
        dot(n, vec2(269.0, 382.0)));
    return fract(sin(x)*43578.5453);
}

float noise(vec3 x) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    
    f = f*f*(3.0 - 2.0*f);
    float n = p.x + p.y*57.0 + p.z*113.0;
    
    return mix(
        mix(
            mix(hash(n + 000.0), hash(n + 001.0), f.x),
            mix(hash(n + 057.0), hash(n + 058.0), f.x),
            f.y),
        mix(
            mix(hash(n + 113.0), hash(n + 114.0), f.x),
            mix(hash(n + 170.0), hash(n + 171.0), f.x),
            f.y),
        f.z);
}

float fbm(vec3 p) {
    float f = 0.0;
    
    f += 0.5000*noise(p); p *= 2.08;
    f += 0.2500*noise(p); p *= 2.03;
    f += 0.1250*noise(p); p *= 2.07;
    f += 0.0625*noise(p); p *= 2.01;
    f /= 0.9375;
    
    return f;
}

vec2 path(float z) {
    return vec2(2.0*cos(z*0.2), 0.0);
}

float volume(vec3 p) {
    p = p + noise(p);
    float n = dot(cos(p), sin(p.yzx));
    float d = -(.45 - .33*n);
    
    d = clamp(d + 0.1*fbm(2.0*p + time), 0.0, 1.0);
    return d;
}

vec4 volumetric(vec3 ro, vec3 rd, float md, vec2 p) {
    float s = 0.05, t = 0.0;
    t += 0.05*hash(p).x;
    
    vec4 sum = vec4(0);
    
    for(int i = 0; i < 200; i++) {
        if(sum.a > 0.99) break;
        if(t > md) break;
        
        vec3 pos = ro + rd*t;
        float d = volume(pos);
        
        vec3 ocol = mix(vec3(1, .3, .3), vec3(.3, .3, 1), 2.0*smoothstep(0.3, 1.0, fbm(3.0*pos)));
        vec4 col = vec4(mix(ocol, ocol - 0.5, d), d);
        col.a *= 10.0;
        col.rgb *= col.a;
        sum += col*(1.0 - sum.a);
        
        t += s;
    }
    
    return clamp(sum, 0.0, 1.0);
}

vec2 map(vec3 p) {
    vec2 t = abs(p.xy - path(p.z))*vec2(.56);
    p = p + noise(p);
    float n = dot(cos(p), sin(p.yzx));
    
    vec2 d1 = vec2(.45 - n*.33, 1.0);
    vec2 d2 = vec2(1.0 - max(t.x, t.y));
    
    return d1.x < d2.x ? d1 : d2;
}

vec2 march(vec3 ro, vec3 rd) {
    float t = 0.0;
    float m = 0.0;
    
    for(int i = 0; i < 350; i++) {
        vec2 h = map(ro + rd*t);
        if(abs(h.x) < 0.001 || t >= 50.0) break;
        t += h.x*0.55;
        m = h.y;
    }
    
    return vec2(t, m);
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

float ao(vec3 p, vec3 n) {
    float s = 0.006, t = s;
    float o = 0.0, w = 1.0;
    
    for(int i = 0; i < 15; i++) {
        float h = map(p + n*t).x;
        o += (t - h)*w;
        w *= 0.95;
        t += s;
    }
    
    return 1.0 - clamp(o, 0.0, 1.0);
}

mat3 camera(vec3 eye, vec3 lat) {
    vec3 ww = normalize(lat - eye);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
    vec3 vv = normalize(cross(ww, uu));
    
    return mat3(uu, vv, ww);
}

void main( void ) {
    vec2 uv = -1.0 + 2.0*(gl_FragCoord.xy/resolution);
    uv.x *= resolution.x/resolution.y;
    
    vec3 col = vec3(0);
    
    vec3 ro = vec3(0,-0.8, 2.0*time);
    ro.xy += path(ro.z);
    vec3 la = ro + vec3(0, 0, 5);
    la.xy += path(la.z);
    vec3 rd = normalize(camera(ro, la)*vec3(uv, 1.97));
    
    vec2 i = march(ro, rd);
    if(i.x < 50.0) {
        vec3 pos = ro + rd*i.x;
        vec3 nor = normal(pos);
        vec3 ref = reflect(rd, nor);

        vec3 rig = ro;
        vec3 lig = normalize(rig - pos);
        
        float dif = clamp(dot(nor, lig), 0.0, 1.0);
        
        col  = 0.3*vec3(1);
        col += 0.8*dif;
        
        if(i.y <= 0.5) {
            vec3 q = pos;

            if(abs(nor.y) >= 0.001) {
                q.xy -= path(q.z);
                col *= vec3(1)*mod(floor(q.x) + floor(q.z), 2.0);
            } else {
                q.xy += path(q.z);
                col *= vec3(1)*mod(floor(q.x) + floor(q.y), 2.0);
            }
        } else {
            col = mix(vec3(1, .3, .3), vec3(.3, .3, 1), 2.0*smoothstep(0.3, 1.0, fbm(3.0*pos)));
        }
        
        col += 0.2*pow(clamp(dot(ref, lig), 0.0, 1.0), 16.0)*dif;
        col += 0.2*pow(clamp(1.0 + dot(rd, nor), 0.0, 1.0), 2.0);
        
        col *= ao(pos, nor);
    }
    
    vec4 vol = volumetric(ro, rd, i.x, uv);
    col = mix(col, vol.rgb, vol.a);
    col = pow(col, vec3(.454545));
    
    glFragColor = vec4(col, 1);
}
