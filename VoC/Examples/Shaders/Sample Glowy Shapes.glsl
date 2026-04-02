#version 420

// original https://www.shadertoy.com/view/Wtsfzn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define u_resolution resolution
#define u_time time*.2

// Antialiasing: number of samples in x and y dimensions
#define AA 3

#define PI 3.141592653589793
#define TAU 6.283185307179586
#define PHI (sqrt(5.)*0.5 + 0.5)

float sdOctahedron(in vec3 p, in float s) {
    p = abs(p);
    float m = p.x + p.y + p.z - s;
    vec3 q;
    if(3.0 * p.x < m) q = p.xyz;
    else if(3.0 * p.y < m) q = p.yzx;
        else if(3.0 * p.z < m) q = p.zxy;
            else return m * 0.57735027;

            float k = clamp(0.5 * (q.z - q.y + s), 0.0, s); 
        return length(vec3(q.x, q.y - s + k, q.z - k)); 
}
float sdTorus(vec3 p, vec2 t){
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0))
        + min(max(d.x, max(d.y, d.z)), 0.0); // remove this line for an only partially signed sdf 
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

float opUnion(float d1, float d2) {
    return min(d1, d2);
}

// subtract d1 from d2
float opSubtraction(float d1, float d2) {
    return max(-d1, d2);
}

float opIntersection(float d1, float d2) {
    return max(d1, d2);
}

// from https://www.alanzucconi.com/2016/07/01/signed-distance-functions/#part4
float opBlend(float sdf1, float sdf2, float amount) {
    return amount * sdf1 + (1. - amount) * sdf2;
}

float linearstep(float begin, float end, float t) {
    return clamp((t - begin) / (end - begin), 0.0, 1.0);
}

vec3 GDFVectors[19];
void initGDFVectors() {
    GDFVectors[0] = normalize(vec3(1, 0, 0));
    GDFVectors[1] = normalize(vec3(0, 1, 0));
    GDFVectors[2] = normalize(vec3(0, 0, 1));

    GDFVectors[3] = normalize(vec3(1, 1, 1 ));
    GDFVectors[4] = normalize(vec3(-1, 1, 1));
    GDFVectors[5] = normalize(vec3(1, -1, 1));
    GDFVectors[6] = normalize(vec3(1, 1, -1));

    GDFVectors[7] = normalize(vec3(0., 1., PHI+1.));
    GDFVectors[8] = normalize(vec3(0., -1., PHI+1.));
    GDFVectors[9] = normalize(vec3(PHI+1., 0., 1.));
    GDFVectors[10] = normalize(vec3(-PHI-1., 0., 1.));
    GDFVectors[11] = normalize(vec3(1., PHI+1., 0.));
    GDFVectors[12] = normalize(vec3(-1., PHI+1., 0.));

    GDFVectors[13] = normalize(vec3(0., PHI, 1.));
    GDFVectors[14] = normalize(vec3(0., -PHI, 1.));
    GDFVectors[15] = normalize(vec3(1., 0., PHI));
    GDFVectors[16] = normalize(vec3(-1., 0., PHI));
    GDFVectors[17] = normalize(vec3(PHI, 1., 0.));
    GDFVectors[18] = normalize(vec3(-PHI, 1., 0.));
}

float fDodecahedron(vec3 p, float r) {
    float d = 0.;
    for (int i = 13; i <= 18; ++i) d = max(d, abs(dot(p, GDFVectors[i])));
    return d - r;
}

float glow = 0.;
vec2 sceneSDF(vec3 p) {
    p *= rotate3D((u_time + .3) * TAU, vec3(-1., 1.5, .2));

    initGDFVectors();

    float t = mod(u_time * 3., 3.);
    float a = sdOctahedron(p, 1.5);
    float b = sdTorus(p * rotate3D(PI/4., vec3(1, 1, 0)), vec2(1.1, .4));
    float c = fDodecahedron(p * rotate3D(PI/2., vec3(1, 0 , 0)), 1.);
    float d = opBlend(
        opBlend(
            opBlend(
                a, 
                b, 
                linearstep(2., 2.3, t)
            ), 
            c, 
            linearstep(1., 1.3, t)
        ), 
        a, 
        linearstep(0., .3, t)
    );

    float d2 = 999.;
    for(float i = -1.; i <= 1.; i+= .1) {
        d2 = opUnion(d2, sdBox(p + vec3(0., (i - fract(t) * .2) * 3., 0.), vec3(2., .01, 2.)));
    }

    float d3 = d + .02;

    d2 = opSubtraction(d - .1, opIntersection(d, d2));
    glow += (0.005 / (0.004 + d2 * d2 * 50.)) * 1.5; 

    return vec2(d2, 1.);
}

mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw,cp));
    vec3 cv = normalize(cross(cu,cw));
    return mat3(cu, cv, cw);
}

vec2 castRay(in vec3 ro, in vec3 rd) {
    float tmin = 1.0;
    float tmax = 20.0;

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
    return calcNormal(pos);
}

// https://iquilezles.org/www/articles/palettes/palettes.htm
vec3 palette(float t){ 
    return vec3(0.50,0.50,0.50) + vec3(0.50,0.50,0.50) * cos(2. * 3.141592653589793 * (vec3(1.00,1.00,1.00) * t + vec3(0.00,0.33,0.67)));
}

vec3 render(in vec3 ro, in vec3 rd) { 
    // cast ray to nearest object
    vec2 res = castRay(ro, rd);
    float distance = res.x; // distance
    float materialID = res.y; // material ID

    vec3 col = vec3(0.6 - length((gl_FragCoord.xy - u_resolution.xy / 2.) / u_resolution.x));;
        if(materialID > 0.0) {
            vec3 pos = ro + distance * rd;
            col = computeColor(ro, rd, pos, distance, materialID);
        }
    // col += glow * vec3(0.9, 0.9, 0.1);
    col += glow * palette(u_time);
    return vec3(clamp(col, 0.0, 1.0));
}

void main(void) {
    // Ray Origin)\t
    vec3 ro = vec3(0., 0., 3.6);
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

    glFragColor = vec4(color, 1.0);
}
