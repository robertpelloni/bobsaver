#version 420

// original https://neort.io/art/bpl4ffc3p9fbkbq83ik0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define LOOP_MAX 1000
#define MAX_DIST 10000.
#define MIN_SURF .00001
#define PI 3.141593

float random(float n) {
    return fract(sin(n*217.12312)*398.2121561);
}

float random(vec2 p) {
    return fract(
        sin(dot(p, vec2(98.108171, 49.10821)))*81.20914
    );
}

float random(vec3 p) {
    return random(random(p.xy) + p.z);
}

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}
float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

float sdGyroid(vec3 p, float r) {
    p += vec3(0.,0.,noise(vec3(time*r*2.,0.,0.)));
    float scale = 20.;
    float g = dot(sin(p*20.115), cos(p.zyx*14.12))/30.;
    float thick = mix(0.003, 0.03, r);
    return abs(g)-thick;

}

float map(vec3 p, vec3 ro) {
    float z = 2.;
    vec3 p_ = mod(p, z)- z*.5;
    vec3 id = floor(p/z);
    float r = random(id);
    float s = length(p_)-.9+r;
    float n = noise(vec3(1.,1., time*.2))*r*.4;
    s = abs(s)-.01-n;
    float g = sdGyroid(p_, r);
    
    return max(p.y, max(s, g))/1.5;
}

struct Trace {
    float d; bool isHit; float s;
};
Trace trace(vec3 ro, vec3 rd) {
    Trace mr;
    float t = 0.;
    float s = 0.;
    bool flag;
    for(int i=0; i<LOOP_MAX; i++) {
        vec3 p = ro+rd*t;
        float d = map(p, ro);
        if(d<MIN_SURF) {
            flag=true;
            break;
        }
        if(t>MAX_DIST) {
            break;
        }
        flag=false;
        t += d;
        s += 1./200.;
    }
    mr.d = t;
    mr.s = s;
    mr.isHit = flag;
    return mr;
}

struct Camera {
    vec3 ro; vec3 rd; float z;
};
Camera makeCam(in vec2 uv, float s) {
    Camera camera;
    vec3 ro = vec3(1.,2.,-2.+s);
    vec3 lookat = ro+vec3(0.,-1.,1.8);
    vec3 f = normalize(lookat-ro);
    vec3 r = cross(vec3(0,1,0), f);
    vec3 u = cross(f, r);
    float z = 1.;
    vec3 c = ro+f*z;
    vec3 i = c+r*uv.x+u*uv.y;
    vec3 rd = normalize(i-ro);
    camera.ro = ro;
    camera.rd = rd;
    camera.z = z;
    return camera;
}

void main() {
    vec3 col = vec3(0.);
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    float s = time;
    Camera c = makeCam(uv, s);
    Trace t = trace(c.ro, c.rd);
    float w = mix(.01,.02, sin(time)*.5+.5)*6.;
    col = vec3(1.,.3,.1)*vec3(pow(t.s,1.)*(1.+t.d*w*(1.-vec3(.2,.1,.2))));
    glFragColor = vec4(1.-col, 1.);
}
