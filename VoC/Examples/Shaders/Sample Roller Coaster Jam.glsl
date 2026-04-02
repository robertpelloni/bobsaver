#version 420

// original https://www.shadertoy.com/view/fllfWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_STEPS 300
#define MAX_DIST 300.
#define SURF_DIST .1

#define PI 3.1415926535
#define M1 1597334677U  
#define M2 3812015801U

#define time time * 1.5

const uvec2 UM = uvec2(M1, M2);
float rand(vec2 q) {
    uvec2 uq = uvec2(q);
    uq *= UM;
    uint n = (uq.x ^ uq.y) * M1;
    return float(n) * (1.0/float(0xffffffffU));
}

float noise(vec2 p) {
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res * res;
}

vec3 shape(float t) {
    float x = t * 0.1;
    vec2 n2 = vec2(
        noise(x * vec2(0.1, 0.175)) * 5., 
        noise(x * vec2(0.1111, 0.1666))* 6.
        )* 5.;
    return vec3(n2,
    t);    
}

float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

vec2 rot(vec2 p, in float an ) {
    float cc = cos(an);
    float ss = sin(an);
    return mat2(cc,-ss,ss,cc)*p;
}

vec3 rot(vec3 P, float a, vec3 A) {
    vec3 O = dot(P, A) * A;
    return O + (P-O) * cos(a) -  cross(A,P) * sin(a);
}

vec2 dist(vec3 p) {
    vec3 lp = p;
    vec2 s = shape(lp.z).xy;
    lp.x *= 0.44;
    lp.xy -= 5.;
    lp.x -= s.x;
    lp.x += sin(lp.z * 0.05) * 2.;
    lp.y -= s.y * 1.5;
    lp.y -= cos(lp.z * 0.05) * 3.;
    lp.xy = rot(lp.xy, pow(abs(cos(lp.z * 0.005)), 10.) * 2. * PI);
    lp.x = abs(lp.x) - 1.;

    float l = length(lp.xy) - .15;
    float c = length(lp.xy + vec2(pow(fract(lp.z), 1.), 0.)) - .1;
    float r = smin(l, c, 0.2);
    float b = smin(p.y + 5., p.x + 35., 10.);
    float mat = b < r ? 1. : 0.;

    return vec2(min(b, r), mat);
}

vec2 march(vec3 ro, vec3 rd) {
    float dO=0.;
    float matId = -1.;
    
    for(int i=0; i<MAX_STEPS; i++) {
        vec3 p = ro + rd*dO;
        vec2 res = dist(p);
        float dS = res.x;
        dO += dS;
        matId = res.y;
        
        if(dO>MAX_DIST || dS<SURF_DIST) break;
    }
    
    return vec2(dO, matId);
}

vec3 normal(vec3 p) {
    float d = dist(p).x;
    vec2 e = vec2(.1, 0);
    
    vec3 n = d - vec3(
        dist(p-e.xyy).x,
        dist(p-e.yxy).x,
        dist(p-e.yyx).x);
    
    return normalize(n);
}

float diffuse(vec3 p, vec3 n, vec3 lp) {
    vec3 l = normalize(lp-p);
    float dif = clamp(dot(n, l), 0., 1.);

    return dif;
}

// Inspired by https://www.shadertoy.com/view/XtVGzw
vec3 camera(vec2 uv, vec3 d, float aspect, float f){ 
    vec3 up = vec3(0., 1., 0.);
    vec3 r = normalize(cross(d, up));
    vec3 u = cross(r, d);
    vec2 ab = f / 360. * uv * PI;
    
    d = rot(d, -ab.x, u);
    r = normalize(cross(d, u));
    d = rot(d, -ab.y, r);
    
    return d;
}

float shadow( in vec3 ro, in vec3 rd, float mint, float maxt) {
    for( float t=mint; t<maxt;) {
        float h = dist(ro + rd * t).x;
        if(h <  SURF_DIST) {
            return 0.0;
            }
        t += h;
    }
    return 1.0;
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    float aspect = resolution.x/resolution.y;
    vec3 pa = shape(time * 10.);

    vec3 ro = abs(pa) * vec3(5., 2., 5.);
    ro.x += 70.;
    vec3 rd = normalize(vec3(-PI + pa.y * 0.1 , 0.5 - pa.y * 0.05, pa.y * 0.1));
    rd = camera(uv, rd, aspect, 120. + pa.y - pa.x * 2.);
    vec2 d = march(ro, rd);
    vec3 p = ro + rd * d.x;
    vec3 n = normal(p); 
    vec3 lp = vec3(20, 20., ro.z + 20.);
    float dif = diffuse(p, n, lp);
    
    vec3 col = vec3(0.);
    if (d.y == 0.) {
        col = n;
    } else if (d.y == 1.) {
        vec3 fp = fract(p * vec3(0.08)) - 0.5;
        float g = max(fp.y, max(fp.x, fp.z));
        col = vec3(dif) * max(smoothstep(0.5, 0.46, g), 0.9);
    } 
    
    float s = max(shadow(p, normalize(vec3(1., 3., 0.)), 5., 60.), 0.75);
    col = col * s;
    col = mix(vec3(0.1), col, smoothstep(MAX_DIST , MAX_DIST - MAX_DIST * 0.25, d.x)); 

    glFragColor = vec4(col, 1.0);
}
