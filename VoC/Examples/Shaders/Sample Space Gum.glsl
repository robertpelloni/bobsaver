#version 420

// original https://www.shadertoy.com/view/tsVczD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

// https://gamedev.stackexchange.com/a/148088
vec3 srgb(vec3 c) {
    vec3 a = 1.055*pow(c, vec3(1.0/2.4)) - 0.055;
    vec3 b = 12.92*c;
    return mix(a, b, lessThan(c, vec3(0.0031308)));
}

// https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
vec3 aces(vec3 color) {    
    mat3 x = mat3(+0.59719, +0.07600, +0.02840, +0.35458, +0.90834, +0.13383, +0.04823, +0.01566, +0.83777);
    mat3 y = mat3(+1.60475, -0.10208, -0.00327, -0.53108, +1.10813, -0.07276, -0.07367, -0.00605, +1.07602);
    vec3 v = x*color;    
    vec3 a = v*(v + 0.0245786) - 0.000090537;
    vec3 b = v*(0.983729*v + 0.4329510) + 0.238081;
    return y*(a/b);    
}

float prod3(vec3 v) {
    return v.x*v.y*v.z;
}

vec3 transform(mat4 m, vec3 v) {
    return (vec4(v, 1.0) * m).xyz;
}

mat4 rotation(vec3 a) {
    vec3 s = sin(a);
    vec3 c = cos(a);    
    return mat4(
        c.y*c.z, c.y*s.z, -s.y, 0.0,
        s.x*s.y*c.z-c.x*s.z, s.x*s.y*s.z+c.x*c.z, s.x*c.y, 0.0,
        c.x*s.y*c.z+s.x*s.z, c.x*s.y*s.z-s.x*c.z, c.x*c.y, 0.0,
        0.0, 0.0, 0.0, 1.0
    );
}

mat4 translation(vec3 p) {
    return mat4(
        1.0, 0.0, 0.0, p.x,
        0.0, 1.0, 0.0, p.y,
        0.0, 0.0, 1.0, p.z,
        0.0, 0.0, 0.0, 1.0
    );
}

struct RM { vec3 p; float t; float d; };

float map(vec3 p) {
    float d = 0.0, da = 0.05, df = 10.0;
    for (int i = 0; i < 3; i++, da *= 0.5, df *= 2.0)
        d += da*prod3(sin(df*p));
    
    vec3 r = vec3(0.6);
    mat4 tr = rotation(vec3(0.3, 0.5, 0.7)*0.1*time);
    mat4 tt = translation(mod(vec3(0.0, 0.0, 0.1)*time, r));
    vec3 tp = mod(transform(tr*tt, p), r) - 0.5*r;
    return 0.9*(sdSphere(tp, 0.1) + d);
}

// https://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p) {
    const vec3 k = vec3(1.0, -1.0, 1e-5);
    return normalize(
        k.xyy*map(p + k.xyy*k.z) +
        k.yyx*map(p + k.yyx*k.z) +
        k.yxy*map(p + k.yxy*k.z) +
        k.xxx*map(p + k.xxx*k.z)
    );
}

bool raymarch(vec3 rc, vec3 ro, vec3 rd, out RM rm) {
    // rayconfig rc: threshold, near, far
    for (rm.t = rc.y; rm.t < rc.z; rm.t += rm.d)
        if (abs(rm.d = map(rm.p = ro + rm.t*rd)) < rc.x)
            return true;
    return false;
}

vec3 render(vec2 uv) {
    vec3 material = vec3(2.0, 0.2, 0.1);
    vec3 ambient = 0.15*vec3(0.1, 0.2, 0.3);
    vec3 light = 1.5*vec3(1.0);
    vec3 fog = ambient;
    
    vec3 rc = vec3(1e-3, 0.0, 10.0);
    vec3 rt = vec3(1.0*uv, 2.0);
    vec3 ro = vec3(0.0*uv, 0.0);
    vec3 rd = normalize(rt - ro);
    RM rm;

    if (!raymarch(rc, ro, rd, rm))
        return fog;
    
    //if (rm.d < 0.0)
    //    return vec3(1.0, 0.0, 0.0);
    
    vec3 n = normal(rm.p);
    vec3 lp = vec3(0.0, 0.25, 0.0) - rm.p;
    vec3 ld = normalize(lp);
    float ll = length(lp);
    
    float diffuse = 1.0*max(0.0, dot(n, ld));
    float specular = 2.0*pow(max(0.0, dot(rd, reflect(ld, n))), 200.0);
    vec3 color = ambient + (material*diffuse + specular)*light/(ll*ll);
    return mix(color, fog, rm.t/rc.z);
}

void main(void) {
    vec2 r = vec2(resolution.x/resolution.y, 1.0);
    vec2 uv = 2.0*gl_FragCoord.xy/resolution.xy - 1.0;
    glFragColor = vec4(srgb(aces(render(r*uv))), 1.0);
}
