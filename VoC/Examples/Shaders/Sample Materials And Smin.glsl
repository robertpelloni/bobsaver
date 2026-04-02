#version 420

// original https://www.shadertoy.com/view/3dKyWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sdPlane(vec3 p, vec3 n, float h) {
    return dot(p, n) + h;
}

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

// https://www.shadertoy.com/view/WdGcD1
// https://github.com/TheRealMJP/BakingLab/blob/master/BakingLab/ACES.hlsl
vec3 aces(vec3 color) {    
    mat3 x = mat3(+0.59719, +0.07600, +0.02840, +0.35458, +0.90834, +0.13383, +0.04823, +0.01566, +0.83777);
    mat3 y = mat3(+1.60475, -0.10208, -0.00327, -0.53108, +1.10813, -0.07276, -0.07367, -0.00605, +1.07602);
    vec3 v = x*color;    
    vec3 a = v*(v + 0.0245786) - 0.000090537;
    vec3 b = v*(0.983729*v + 0.4329510) + 0.238081;
    return y*(a/b);    
}

struct Material {
    vec3 color;
    float kr, kd, ks, kn;
};

Material materials[] = Material[] (
    Material(vec3(1.0, 2.0, 3.0), 0.2, 0.5, 0.0, 1.0),   // ground
    Material(vec3(0.1, 0.2, 2.0), 0.8, 1.0, 1.0, 500.0), // blue
    Material(vec3(2.0, 0.2, 0.1), 0.8, 1.0, 1.0, 500.0)  // red
);

Material mmix(Material a, Material b, float t) {
    return Material(
        mix(a.color, b.color, t),
        mix(a.kr, b.kr, t),
        mix(a.kd, b.kd, t),
        mix(a.ks, b.ks, t),
        mix(a.kn, b.kn, t)
    );
}

vec2 mmin(vec2 a, vec2 b) { return a.x < b.x ? a : b; }
vec2 mmax(vec2 a, vec2 b) { return a.x > b.x ? a : b; }
vec2 msmin(vec2 a, vec2 b, float k) {
    float h = clamp(0.5 + 0.5*(a.x - b.x)/k, 0.0, 1.0);
    return mix(a, b, h) - vec2(k*h*(1.0 - h), 0.0);
}

vec2 map(vec3 p) {
    vec2 ground = vec2(sdPlane(p, vec3(0.0, 1.0, 0.0), 1.0), 0.0);
    vec2 blob = msmin(
        vec2(sdSphere(p - vec3(1.0, 0.0, 0.0), 1.0), 1.0),
        vec2(sdSphere(p + vec3(1.0, 0.0, 0.0), 1.0), 2.0),
        1.0
    );
    return mmin(ground, blob);
}

// https://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 normal(vec3 p) {
    vec3 k = vec3(1.0, -1.0, 1e-5);
    vec3 a = k.xyy*map(p + k.z*k.xyy).x;
    vec3 b = k.yyx*map(p + k.z*k.yyx).x;
    vec3 c = k.yxy*map(p + k.z*k.yxy).x;
    vec3 d = k.xxx*map(p + k.z*k.xxx).x;
    return normalize(a + b + c + d);
}

struct Raymarcher {
    int steps;
    float eps, near, far, t;
    vec3 ro, rd, p;
    vec2 m;
};

bool raymarch(inout Raymarcher rm) {
    rm.t = rm.near;
    for (int i = 0; i < rm.steps; i++) {
        if (rm.t > rm.far) break;
        rm.p = rm.ro + rm.t*rm.rd;
        rm.m = map(rm.p);
        if (rm.m.x < rm.eps) return true;
        rm.t += rm.m.x;
    }
    return false;
}

vec3 render(vec2 uv) {
    vec3 ambient = 0.05*vec3(0.1, 0.2, 0.3);
    vec3 light = 15.0*vec3(1.0);
    vec3 fog = 2.0*ambient;
    
    vec3 camera = 5.0*vec3(cos(time), 0.5, sin(time));
    vec3 target = vec3(0.0, -0.5, 0.0);
    vec3 dir = normalize(target - camera);
    vec3 left = normalize(cross(dir, vec3(0.0, 1.0, 0.0)));
    vec3 down = normalize(cross(left, dir));
    
    Raymarcher rm;
    rm.steps = 1<<8;
    rm.near = 1e-3;
    rm.far = 1e+1;
    rm.eps = 1e-4;
    rm.ro = camera;
    rm.rd = normalize(dir + 0.4*(uv.x*left + uv.y*down));
    
    Raymarcher rml = rm;
    rml.near = 5.0*rm.near;
    
    float alpha = 1.0;
    vec3 color = vec3(0.0);
    
    for (int i = 0; i < 5 && alpha > 1e-3; i++) {
        if (raymarch(rm)) {
            // blending two materials
            Material ma = materials[int(floor(rm.m.y))];
            Material mb = materials[int(ceil(rm.m.y))];
            Material m = mmix(ma, mb, mod(rm.m.y, 1.0));
            
            vec3 n = normal(rm.p);
            vec3 lp = vec3(-1.0, 3.0, 2.0) - rm.p;
            vec3 ld = normalize(lp);
            float ll = length(lp);

            rml.far = ll;
            rml.ro = rm.p;
            rml.rd = ld;
            float la = raymarch(rml) ? 0.0 : 1.0;

            float diff = m.kd*max(0.0, dot(n, ld));
            float spec = m.ks*pow(max(0.0, dot(rm.rd, reflect(ld, n))), m.kn);
            vec3 c = ambient + la*(m.color*diff + spec)*light/(ll*ll);
            c = mix(c, fog, rm.t/rm.far);

            float a = m.kr*alpha;
            color += a*c;
            alpha -= a;
            
            rm.ro = rm.p;
            rm.rd = reflect(rm.rd, n);
        }
        else {
            color += alpha*fog;
            break;
        }
    }
    
    return color;
}

void main(void) {
    vec2 r = resolution.xy/resolution.y;
    vec2 uv = 2.0*gl_FragCoord.xy/resolution.xy - 1.0;
    vec3 rgb = render(r*uv);
    glFragColor = vec4(srgb(aces(rgb)), 1.0);
}
