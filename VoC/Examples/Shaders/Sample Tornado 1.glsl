#version 420

// original https://www.shadertoy.com/view/wdfyzN

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LOOP_MAX 100
#define MAX_DIST 100.
#define MIN_SURF .001

//////////////////////////////////////////////////////////////////////////
// refs. https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
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
float fbm(vec3 x) {
    float v = 0.0;
    float a = 0.5;
    vec3 shift = vec3(100);
    for (int i=0;i<4;++i) {
        v += a * noise(x);
        x = x * 2. + shift;
        a *= 0.5555;
    }
    return v;
}
/////////////////////////////////////////////////////////////////////////

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

float sdGyroid(in vec3 p, in float z) {
    return dot(sin(p*3.115*z), cos(p.zyx*3.12*z))/z*3.;
}

vec3 transform(in vec3 p) {
    p.x *= 1.4;
    p.xz *= rot(p.y*5.*sin(10.)+time);
    p.y *= .3;
    return p;
}

float map(vec3 p) {
    p = transform(p);
    float s = length(p)-1.;
    s += sdGyroid( p+vec3(0,0,time), .5)*.02;
    float w = 2.4+pow(abs(sin(time)),30.)*2.;
    s -= pow(fbm(p*w), 4.)*w;
    return s/15.;
}

struct Trace {
    float d; bool isHit; float s;
};
Trace trace(vec3 ro, vec3 rd, out vec3 cp) {
    Trace mr;
    float t = 0.;
    float s = 0.;
    bool flag;
    for(int i=0; i<LOOP_MAX; i++) {
        vec3 p = ro+rd*t;
        float d = map(p);
        if(d<MIN_SURF) {
            flag=true;
            break;
        }
        if(t>MAX_DIST) {
            break;
        }
        flag=false;
        t += d;
        s += 1./100.;
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
    vec3 ro = vec3(0,0,-3);
    vec3 lookat = vec3(0.);
    vec3 f = normalize(lookat-ro);
    vec3 r = cross(vec3(0,1,0), f);
    vec3 u = cross(f, r);
    float z = 1.2;
    vec3 c = ro+f*z;
    vec3 i = c+r*uv.x+u*uv.y;
    vec3 rd = normalize(i-ro);
    camera.ro = ro;
    camera.rd = rd;
    camera.z = z;
    return camera;
}

vec3 getNormal(vec3 p){
    float d = 0.001;
    return normalize(vec3(
        map(p + vec3(  d, 0.0, 0.0)) - map(p + vec3( -d, 0.0, 0.0)),
        map(p + vec3(0.0,   d, 0.0)) - map(p + vec3(0.0,  -d, 0.0)),
        map(p + vec3(0.0, 0.0,   d)) - map(p + vec3(0.0, 0.0,  -d))
    ));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - resolution.xy*.5)/resolution.y;
    vec3 col = vec3(1.);
    Camera c = makeCam(uv, time);
    vec3 cp;
    Trace t = trace(c.ro, c.rd, cp);
    vec3 p =  c.ro+c.rd*t.d;
    float w = mix(.01,.02, sin(time)*.5+.5)*1.;
    if(t.isHit) {
        vec3 n = getNormal(p)*.5+.5;
        n*=.3+sin(time)*.1;
        col = vec3(.2);
        col += dot(n, vec3(cos(time),sin(time), 0.))*vec3(.7,.1,.8)*1.;
        col += dot(n, vec3(0.,cos(time*.4),sin(time*.2 + 10.)))*vec3(1.,.3,.2)*1.;
        col += dot(n, vec3(0.,cos(time*2.+12.54),sin(time*3.+19.56)))*vec3(1.,.3,.65)*1.;
        col += t.s*length(p.xz)*.5;
    }
    glFragColor = vec4(col, 1.);
}
