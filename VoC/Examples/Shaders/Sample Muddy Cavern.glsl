#version 420

// original https://www.shadertoy.com/view/4sKSzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float hash(float n) {
    return fract(sin(n)*43578.4545);
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
    
    f += 0.500*noise(p); p *= 2.01;
    f += 0.250*noise(p); p *= 2.04;
    f += 0.125*noise(p);
    
    f /= 0.875;
    return f;
}

vec2 path(float z) {
    return vec2(sin(0.5*z), 2.0*cos(0.12*z));
}

vec3 camPath() {
    vec3 ro = vec3(0, 0, 2.0*time);
    ro.xy = path(ro.z);
    
    return ro;
}

vec3 lookat(vec3 ro) {
    vec3 la = ro + vec3(0, 0, 1);
    la.xy = path(la.z);
    
    return la;
}

vec3 lightPath(vec3 la) {
    vec3 lp = la;
    lp.xy += 0.2*vec2(sin(time), cos(time));
    
    
    return lp;
}

float map(vec3 p) {
    float r = 0.6*smoothstep(0.3, 1.0, noise(1.5*p));
    float f = 0.1*smoothstep(0.0, 1.0, fbm(6.0*p + 3.0*vec3(0, time, 0)));
    
    float l = length(p - lightPath(lookat(camPath()))) - 0.01;
    vec2 tun = abs(p.xy - path(p.z))*vec2(.6, 3);
    float t = 1.0 - max(tun.x, tun.y);
    return min(l, t - (r + f));
}

float march(vec3 ro, vec3 rd) {
    float t = 0.0;
    
    for(int i = 0; i < 150; i++) {
        float h = map(ro + rd*t);
        if(abs(h) < 0.0001 || t >= 30.0) break;
        t += h*0.5;
    }
    
    return t;
}

vec3 normal(vec3 p) {
    vec2 h = vec2(0.01, 0.0);
    
    vec3 n = vec3(
        map(p + h.xyy) - map(p - h.xyy),
        map(p + h.yxy) - map(p - h.yxy),
        map(p + h.yyx) - map(p - h.yyx)
    );
    
    return normalize(n);
}

mat3 camera(vec3 e, vec3 l) {
    vec3 f = normalize(l - e);
    vec3 r = normalize(cross(vec3(0, 1, 0), f));
    vec3 u = normalize(cross(f, r));
    
    return mat3(r, u, f);
}

void main(void)
{
    vec2 uv = (-1.0 + 2.0*(gl_FragCoord.xy/resolution.xy))*vec2(resolution.x/resolution.y, 1.0);
    
    vec3 ro = camPath();
    
    vec3 la = lookat(ro);
    
    vec3 rd = camera(ro, la)*normalize(vec3(uv, 1.97));
    
    vec3 col = vec3(0);
    
    float i = march(ro, rd);
    
    if(i < 30.0) {
        vec3 pos = ro + rd*i;
        vec3 nor = normal(pos);
        
        vec3 rig = lightPath(la);
        vec3 lig = normalize(rig - pos);
        vec3 ref = reflect(rd, nor);
        
        float dis = max(length(pos - rig), 0.001);
        if(dis <= 0.015) {
            col = vec3(1);
        } else {
            float att = 1.0/(1.0 + 10.0*dis + 10.0*dis*dis);
            
            float dif = clamp(dot(lig, nor), 0.0, 1.0);
            float spe = pow(clamp(dot(lig, ref), 0.0, 1.0), 32.0);
            
            col =  0.7*dif*vec3(1);
            col *= vec3(0.8, 0.6, 0.2);
            col += spe*vec3(1)*dif;
            
            col *= att;
        }
    }
    
    col = pow(col, vec3(.4545));
    
    glFragColor = vec4(col, 1);
}
