#version 420

// original https://www.shadertoy.com/view/MtV3zc

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define FAR_CLIP 10.0
#define PI 3.1415

float t = time * 0.5;

float rand1(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898, 78.233))) * 43758.5453);
}

/* Rotations */

void rX(inout vec3 p, float a) {
    vec3 q = p;
    float c = cos(a);
    float s = sin(a);
    p.y = c * q.y - s * q.z;
    p.z = s * q.y + c * q.z;
}

void rY(inout vec3 p, float a) {
    vec3 q = p;
    float c = cos(a);
    float s = sin(a);
    p.x = c * q.x + s * q.z;
    p.z = -s * q.x + c * q.z;
}

void rZ(inout vec3 p, float a) {
    vec3 q = p;
    float c = cos(a);
    float s = sin(a);
    p.x = c * q.x - s * q.y;
    p.y = s * q.x + c * q.y;
}

/* Distance functions - IQ */

float sdSphere(vec3 rp, vec3 bp, float r) {
    return length(bp - rp) - r;
}

float sdBox(vec3 rp, vec3 b) {
    vec3 d = abs(rp) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

float length2(vec2 rp) {
    return sqrt(rp.x * rp.x + rp.y * rp.y);
}

float length8(vec2 rp) {
    rp = rp * rp; 
    rp = rp * rp; 
    rp = rp * rp;
    return pow(rp.x + rp.y, 1.0 / 8.0 );
}

float sdTorus82(vec3 rp, vec2 t) {
    vec2 q = vec2(length2(rp.xz) - t.x, rp.y);
    return length8(q) - t.y;
}

float dfCutout(vec3 rp, float a) {
    float msd = 999.0;
    rY(rp, a);
    for (int i = 0; i < 3; i++) {
        rY(rp, 1.0);
        msd = min(msd, sdBox(rp, vec3(0.25, 3.0, 3.0)));   
    }
    return msd;
}

float dfRings(vec3 rp) {
    float msd = 999.0;
    int fp = 1;
    float dr = 2.5; 
    rp.y -= dr;
    for (int i = -4; i < 5; i++) {
        rp.y += dr * 0.2;
        float ring = 0.0;
        if (fp > 0) {
            ring = max(sdTorus82(rp, vec2(sqrt((dr * dr) - (float(i) * 0.5) * (float(i) * 0.5)), 0.1)), -dfCutout(rp, t * float(i) * 0.25));
        } else {
            ring = max(sdTorus82(rp, vec2(sqrt((dr * dr) - (float(i) * 0.5) * (float(i) * 0.5)), 0.1)), -dfCutout(rp, -t * float(i) * .25));
        }
        msd = min(msd, ring);
        fp *= -1;
    }       
    return msd;
}

float dfScene(vec3 rp) {
    return min(sdSphere(rp, vec3(0.0), 1.0), dfRings(rp));
}

/* Shading */

// GUIL - Fractal
//This is so awesome!!!
vec2 csqr(vec2 a) {return vec2(a.x * a.x - a.y * a.y, 2. * a.x * a.y);}
float skin(in vec3 rp) {
    float res = 0.;
    vec3 c = rp;
    for (int i = 0; i < 10; ++i) {
        rp = 0.7 * abs(rp) / dot(rp, rp) -0.7;
        rp.yz= csqr(rp.yz);
        rp = rp.zxy;
        res += exp(-19. * abs(dot(rp, c)));
    }
    return res / 2.;
}

/* Marching */

vec3 marchScene(vec3 ro, vec3 rd) {
    vec3 pc = vec3(0.0); //pixel colour
    float d = 0.0; //distance marched
    vec3 rp = vec3(0.0); //ray position
    vec3 bgcol = vec3(0.0); //background
    vec3 hc = vec3(1.0, 0.0, 0.0); //highlight colour
    vec3 sc = vec3(0.6, 0.4, 0.1); //sun colour  
    for (int i = 0; i < 16; i++) {
        vec3 rp = ro + rd * d;
        float ns = dfScene(rp); //nearest surface
        d += ns;
        if (ns < 0.01 || d > FAR_CLIP) break;
        float c = skin(rp);
        hc = hc * c + c * 0.25;
        bgcol = mix(bgcol, sc * hc * 1.2 * float(i) * 3.0, 0.5);
    }
    return pc = pc * 0.95 + bgcol * 0.2;
}

void main(void) {
    //coordinate system
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    //camera
    vec3 rd = normalize(vec3(uv, 2.));
    vec3 ro = vec3(0.0, 0.0, -6.5);
    //rotate camera
    rX(ro, t * 0.25 + 1.0);
    rX(rd, t * 0.25 + 1.0);
    rX(ro, cos(t) * 0.01);
    rX(ro, cos(t) * 0.01);
    rZ(ro, cos(t) * 0.21);
    rZ(rd, cos(t) * 0.21);
    //ray marching
    vec3 col1 = marchScene(ro, rd);
    glFragColor = vec4(col1, 1.0);
    
    //VIRGIL - though I have seen this effect on quite a few other shaders. And why not :)
    float klang1 = 1.75;
    vec2 uv2 = -0.3 + 2.0 * gl_FragCoord.xy / resolution.xy;
    glFragColor -= 0.020 * (1.0 -klang1) * rand1(uv2.xy * t);                            
    glFragColor *= 0.9 + 0.20 * (1.0 -klang1) * sin(10.0 * t + uv2.x * resolution.x);    
    glFragColor *= 0.9 + 0.20 * (1.0 -klang1) * sin(10.0 * t + uv2.y * resolution.y);
    //*/
}
