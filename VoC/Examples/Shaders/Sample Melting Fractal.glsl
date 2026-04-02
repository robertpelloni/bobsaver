#version 420

// original https://www.shadertoy.com/view/wscBWH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 1

#define MIN_DIST 0.001
#define MAX_DIST 50.

#define PI 3.141592653589793
#define TAU 6.283185307179586

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0))
        + min(max(d.x, max(d.y, d.z)), 0.0); // remove this line for an only partially signed sdf 
}

float sdRoundCone(in vec3 p, in float r1, float r2, float h) {
    vec2 q = vec2(length(p.xz), p.y);

    float b = (r1 - r2) / h;
    float a = sqrt(1.0 - b * b);
    float k = dot(q, vec2(-b, a));

    if(k < 0.0) return length(q) - r1;
    if(k > a * h) return length(q - vec2(0.0, h)) - r2;

    return dot(q, vec2(a, b)) - r1;
}

float opUnion(float d1, float d2) {
    return min(d1, d2);
}

vec2 opUnion(vec2 d1, vec2 d2) {
    return d1.x < d2.x ? d1 : d2;
}

vec3 opSymXYZ(vec3 p) {
    p = abs(p);
    return p;
}

float easeInOutQuad(float t) {
    if ((t *= 2.0) < 1.0) {
        return 0.5 * t * t;
    } else {
        return -0.5 * ((t - 1.0) * (t - 3.0) - 1.0);
    }
}

// from https://github.com/doxas/twigl
mat3 rotate3D(float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
}

void mengerFold(inout vec3 z) {
    float a = min(z.x - z.y, 0.0);
    z.x -= a;
    z.y += a;
    a = min(z.x - z.z, 0.0);
    z.x -= a;
    z.z += a;
    a = min(z.y - z.z, 0.0);
    z.y -= a;
    z.z += a;
}

void boxFold(inout vec3 z, vec3 r) {
    z.xyz = clamp(z.xyz, -r, r) * 2.0 - z.xyz;
}

float glow = 0.;
vec2 sceneSDF(vec3 p) {
    float t = time * .1;
    t = easeInOutQuad(mod(t, 1.));
    vec2 d = vec2(10e5, 0);

    for(int i = 0; i < 5; i++) {
        p = opSymXYZ(p);
        mengerFold(p);
        boxFold(p, vec3(.5));
        p.x -= .2;
        p *= rotate3D(t * TAU, vec3(1, 1, 0));
        p *= .95;
        p *= rotate3D(-t * TAU, vec3(0, 1, 1));

        float dd = sdRoundCone(p, 1.6, .1, 1.6);
        if(i == 3) glow += 0.006 / (0.01 + dd * dd * 5.) / (float(AA * AA) * 10.);
    }
    d = opUnion(d, vec2(sdBox(p, vec3(.8, .1, .1)), 2.));

    return d;
}

// Compute camera-to-world transformation.
mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw,cp));
    vec3 cv = normalize(cross(cu,cw));
    return mat3(cu, cv, cw);
}

// Cast a ray from origin ro in direction rd until it hits an object.
// Return (t,m) where t is distance traveled along the ray, and m
// is the material of the object hit.
vec2 castRay(in vec3 ro, in vec3 rd) {
    float tmin = MIN_DIST;
    float tmax = MAX_DIST;

    #if 0
    // bounding volume
    float tp1 = (0.0 - ro.y) / rd.y; 
    if(tp1 > 0.0) tmax = min(tmax, tp1);
    float tp2 = (1.6 - ro.y) / rd.y; 
    if(tp2 > 0.0) { 
        if(ro.y > 1.6) tmin = max(tmin, tp2);
        else tmax = min(tmax, tp2 );
    }
    #endif

    float t = tmin;
    float m = -1.0;
    for(int i = 0; i < 100; i++) {
        float precis = 0.0005 * t;
        vec2 res = sceneSDF(ro + rd * t);
        if(res.x < precis || t > tmax) break;
        t += res.x;
        m = res.y;
    }

    if(t > tmax) m =- 1.0;
    return vec2(t, m);
}

// Cast a shadow ray from origin ro (an object surface) in direction rd
// to compute soft shadow in that direction. Returns a lower value
// (darker shadow) when there is more stuff nearby as we step along the shadow ray.
float softshadow(in vec3 ro, in vec3 rd, in float mint, in float tmax) {
    float res = 1.0;
    float t = mint;
    for(int i = 0; i < 16; i++) {
        float h = sceneSDF(ro + rd * t).x;
        res = min(res, 8.0 * h / t);
        t += clamp(h, 0.02, 0.10);
        if(h < 0.001 || t > tmax) break;
    }
    return clamp(res, 0.0, 1.0);
}

// Compute normal vector to surface at pos, using central differences method?
vec3 calcNormal(in vec3 pos) {
    // epsilon = a small number
    vec2 e = vec2(1.0, -1.0) * 0.5773 * 0.0005;

    return normalize(
        e.xyy * sceneSDF(pos + e.xyy).x + 
        e.yyx * sceneSDF(pos + e.yyx).x + 
        e.yxy * sceneSDF(pos + e.yxy).x + 
        e.xxx * sceneSDF(pos + e.xxx).x
    );
}

// compute ambient occlusion value at given position/normal
float calcAO(in vec3 pos, in vec3 nor) {
    float occ = 0.0;
    float sca = 1.0;
    for(int i = 0; i < 5; i++) {
        float hr = 0.01 + 0.12 * float(i) / 4.0;
        vec3 aopos = nor * hr + pos;
        float dd = sceneSDF(aopos).x;
        occ += -(dd - hr) * sca;
        sca *= 0.95;
    }
    return clamp(1.0 - 3.0 * occ, 0.0, 1.0);
}

vec3 computeColor(vec3 ro, vec3 rd, vec3 pos, float d, float m) {
    vec3 nor = calcNormal(pos);
    vec3 ref = reflect(rd, nor); // reflected ray

    // material
    vec3 col = vec3(202, 82, 68)/255.;

    // lighting        
    float occ = calcAO(pos, nor); // ambient occlusion
    vec3 lig = normalize(vec3(-0.4, 0.7, -0.6)); // sunlight
    float amb = clamp(0.5 + 0.5 * nor.y, 0.0, 1.0); // ambient light
    float dif = clamp(dot(nor, lig), 0.0, 1.0); // diffuse reflection from sunlight
    // backlight
    float bac = clamp(dot(nor, normalize(vec3(-lig.x, 0.0, -lig.z))), 0.0, 1.0) * clamp(1.0 - pos.y, 0.0, 1.0);
    float dom = smoothstep(-0.1, 0.1, ref.y); // dome light
    float fre = pow(clamp(1.0 + dot(nor, rd), 0.0, 1.0), 2.0); // fresnel
    float spe = pow(clamp(dot(ref, lig), 0.0, 1.0), 16.0); // specular reflection

    dif *= softshadow(pos, lig, 0.02, 2.5);
    dom *= softshadow(pos, ref, 0.02, 2.5);

    vec3 lin = vec3(0.0);
    lin += 1.30 * dif * vec3(1.00, 0.80, 0.55);
    lin += 2.00 * spe * vec3(1.00, 0.90, 0.70) * dif;
    lin += 0.40 * amb * vec3(0.40, 0.60, 1.00) * occ;
    lin += 0.50 * dom * vec3(0.40, 0.60, 1.00) * occ;
    lin += 0.50 * bac * vec3(0.25, 0.25, 0.25) * occ;
    lin += 0.25 * fre * vec3(1.00, 1.00, 1.00) * occ;
    col = col * lin;

    return col;
}

// Figure out color value when casting ray from origin ro in direction rd.
vec3 render(in vec3 ro, in vec3 rd) { 
    // cast ray to nearest object
    vec2 res = castRay(ro, rd);
    float distance = res.x; // distance
    float materialID = res.y; // material ID

    vec3 col = vec3(0.6 - length((gl_FragCoord.xy - resolution.xy / 2.) / resolution.x));;
        if(materialID > 0.0) {
            vec3 pos = ro + distance * rd;
            col = computeColor(ro, rd, pos, distance, materialID);
        }
    return vec3(clamp(col, 0.0, 1.0));
}
void init() {}

vec3 effect(vec3 c) {
    c += glow * vec3(242, 223, 126)/255.;
    return c;
}

void main(void) {
    // Ray Origin)\t
    vec3 ro = vec3(-5, 2.5, -6) * 2.2 * rotate3D(time * .05 * TAU, vec3(0, 1, 0));
    vec3 ta = vec3(0.0);
    // camera-to-world transformation
    mat3 ca = setCamera(ro, ta, 0.0);

    vec3 color = vec3(0.0);

    #if AA>1
    for(int m = 0; m < AA; m++)
        for(int n = 0; n < AA; n++) {
            // pixel coordinates
            vec2 o = vec2(float(m), float(n)) / float(AA) - 0.5;
            vec2 p = (-resolution.xy + 2.0 * (gl_FragCoord.xy + o)) / resolution.y;
            #else
            vec2 p = (-resolution.xy + 2.0 * gl_FragCoord.xy) / resolution.y;
            #endif

            // ray direction
            vec3 rd = ca * normalize(vec3(p.xy, 2.0));

            // render\t
            vec3 col = render(ro, rd);

            color += col;
            #if AA>1
        }
    color /= float(AA*AA);
    #endif

    color = effect(color);

    glFragColor = vec4(color, 1.0);
}
