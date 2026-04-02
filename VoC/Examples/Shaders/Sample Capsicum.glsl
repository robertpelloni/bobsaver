#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;
const float pi = 3.14159265358979323;

// EDIT: Added two "abs()" calls.  Some systems can't handle pow() of negative numbers.

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sdPlane(in vec3 p) {
    return p.y;
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r ) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float sdStem( vec3 p, vec3 a, vec3 b, float r ) {
    p.z += 0.1 * cos(p.y * pi) + 0.05;
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r * cos(h - abs(p.y * 0.2));
}

float sdStemJoint(in vec3 p, in float r) {
    vec3 q = p;
    q.y *= 5.0 - length(p.xz);
    float theta = atan(q.z, q.x) / pi * 0.5 + 0.5;
    float k = sin(theta * 2.0 * pi * 3.5 + pi / 2.0);
    float d_xz = 0.01 * pow(abs(k), 0.6);
    return length(q) - r * 0.5 - d_xz;
}

float sdSweetPepper(in vec3 p, in float r) {
    vec3 q = p;
    q.y *= 0.95 - length(p.xz);
    float theta = atan(q.z, q.x) / pi * 0.5 + 0.5;
    float k = sin(theta * 2.0 * pi * 3.5);
    float d_xz = 0.02 * mix(k, pow(abs(k), 0.5), (p.y * 0.5 + 0.5) * 0.5) * k + p.y * 0.25;
    return length(q) - r - d_xz;
}

float sdSphere(in vec3 p, in float r) {
    return length(p) - r;
}

vec4 opU( vec4 d1, vec4 d2 ) {
    return (d1.w < d2.w) ? d1 : d2;
}

vec4 map(in vec3 p) {
    float d0 = sdPlane(p);
    float t = time * 0.3;
    float c = cos(t);
    float s = sin(t);
    mat3 m = mat3(
        c, 0.0, s,
        0.0, 1.0, 0.0,
        -s, 0.0, c
    );
    p = m * p;
    float d1 = sdSweetPepper(p - vec3(0.0, 0.25, 0.0), 0.25);
    float d2 = sdStemJoint(p - vec3(0.0, 0.65, 0.0), 0.08);
    float d3 = sdStem(p, vec3(0.0, 0.5, 0.0), vec3(0.0, 0.75, 0.0), 0.05);
    float d4 = smin(d2, d3, 0.1);
    vec4 res = opU(vec4(0.2, 0.2, 0.2, d0), vec4(1.0, 0.9, 0.0, d1));
    res = opU(res, vec4(0.2, 0.8, 0.0, d4));
    return res;
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(-1.0, 1.0) * 0.001;
    vec3 nor = vec3(
        e.xyy * map(p + e.xyy).w +
        e.yxy * map(p + e.yxy).w +
        e.yyx * map(p + e.yyx).w +
        e.xxx * map(p + e.xxx).w
    );
    return normalize(nor);
}

vec4 castRay(in vec3 ro, in vec3 rd, in float maxt) {
    float precis = 0.001;
    float h = precis * 2.0;
    float t = 0.0;
    vec4 hit = vec4(1.0);
    for(int i = 0; i < 60; i++) {
        if(abs(h) < precis || t > maxt) continue;
        hit = map(ro + rd * t);
    h = hit.w;
        t += h;
    }
    return vec4(hit.rgb, t);
}

float softshadow(in vec3 ro, in vec3 rd, in float mint, in float maxt, in float k) {
    float sh = 1.0;
    float t = mint;
    float h = 0.0;
    for(int i = 0; i < 15; i++) {
        if(t > maxt) continue;
        h = map(ro + rd * t).w;
        sh = min(sh, k * h / t);
        t += h;
    }
    return sh;
}

vec3 render(in vec3 ro, in vec3 rd) {
    vec3 col = vec3(1.0);
    vec4 hit = castRay(ro, rd, 20.0); 
    float t = hit.w;
    vec3 pos = ro + rd * t;
    vec3 nor = calcNormal(pos);
    vec3 lig = normalize(vec3(-0.4, 0.7, 0.5));
    float dif = clamp(dot(lig, nor), 0.0, 1.0);
    float back = pow(clamp(1.0 + dot(rd, nor), 0.0, 1.0), 2.0);  
    float spec = pow(clamp(dot(reflect(rd, nor), lig), 0.0, 1.0), 16.0);
    float sh = softshadow(pos, lig, 0.02, 2.0, 14.0);
    vec3 mcol = hit.rgb * (dif + spec) + clamp(1.25 * vec3(1.0, 0.5, 0.45) * back, 0.0, 1.0);
    col = mcol;// * (sh * 0.8 + 0.2);
    return col;
}

void main() {
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = uv * 2.0 - 1.0;
    p.x *= resolution.x / resolution.y;
    vec3 ro = vec3(mouse.x, 1.0 + mouse.y, 2.0);
    vec3 ta = vec3(0.0, 0.25, 0.0);
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(0.0, 1.0, 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    vec3 rd = normalize(p.x * cu + p.y * cv + 2.5 * cw);
    vec3 col = render(ro, rd);
    
    glFragColor = vec4(col, 1.0);
}
