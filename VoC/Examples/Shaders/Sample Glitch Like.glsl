#version 420

// original https://www.shadertoy.com/view/3dVXzh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define IS_GLITCH (noise(time*12.)<0.6)

#define tt (time*.1)
#define ft (fract(tt))
#define it (floor(tt))

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;

mat2 rotate(in float r) { float c=cos(r), s=sin(r); return mat2(c,-s,s,c); }
vec2 rotate(in vec2 p, in float r) { return rotate(r)*p; }
vec3 rotate(in vec3 p, in vec3 r) {
    p.xy = rotate(p.xy, r.z);
    p.yz = rotate(p.yz, r.x);
    p.zx = rotate(p.zx, r.y);
    return p;
}

float hash(in float v) { return fract(sin(v)*43758.5453); }
float hash(in vec2 v) { return fract(sin(dot(v, vec2(12.9898, 78.233)))*43758.5453); }
float noise(in float v) { float f=fract(v),i=floor(v),u=f*f*(3.-2.*f); return mix(hash(i), hash(i+1.), u); }
float noise(in vec2 v) {
    vec2 f=fract(v),i=floor(v),u=f*f*(3.-2.*f);
    return mix(
        mix(hash(i+vec2(0.,0.)), hash(i+vec2(1.,0.)), u.x),
        mix(hash(i+vec2(0.,1.)), hash(i+vec2(1.,1.)), u.x),
        u.y
    );
}
float noise(in vec3 v) {
    vec3 f=fract(v),i=floor(v),u=f*f*(3.-2.*f);
    float n = i.x + i.y*53. + i.z*117.;
    return mix(
        mix(mix(hash(n+  0.), hash(n+  1.), u.x), mix(hash(n+ 53.), hash(n+ 54.), u.x), u.y),
        mix(mix(hash(n+117.), hash(n+118.), u.x), mix(hash(n+170.), hash(n+171.), u.x), u.y),
        u.z
    );
}
// https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
vec3 random3(vec3 c) {
    float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
    vec3 r;
    r.z = fract(512.0*j);
    j *= .125;
    r.x = fract(512.0*j);
    j *= .125;
    r.y = fract(512.0*j);
    return r-0.5;
}

vec3 glitch(in vec3 p, in float seed) {
    float hs = hash(seed);
    vec3 q = p;
    for(int i=0;i<4;i++) {
        float fi = float(i)+1.;
        q = p*2.*fi;
        vec3 iq = floor(q);
        vec3 fq = fract(q);
        float n = noise(rotate(iq, vec3(hs)));
        vec3 offset = 3.*random3(vec3(n)*vec3(10.486, 78.233, 65.912));
        if(hash(n)<0.1) {
            p = p + offset;
            break;
        }
    }
    return p;
}
vec3 glitch(in vec3 p) { return glitch(p, 43768.5453); }

float grid(in vec2 uv, in float n, in float w) {
    uv = fract(uv*n);
    uv = abs(uv-0.5);
    return 1.-smoothstep(-0.5*w, 0.5*w, min(uv.x, uv.y));
}

float box(in vec3 p, in vec3 b) { vec3 d = abs(p)-b; return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.); }
float box(in vec3 p, in float b) { return box(p, vec3(b)); }

vec2 minD(in vec2 d1, in vec2 d2) { return d1.x<d2.x ? d1 : d2; }

vec3 transform(in vec3 p) {
    p = rotate(p, vec3(0.25*PI, 0.25*PI, 0.));
    return p;
}

#define repeat(p,c) mod(p,c)-0.5*c

vec2 map(in vec3 p) {
    vec2 d = vec2(1e4, -1.);

    vec3 q1 = transform(p);
    float tn = 10. * hash(floor(time*2.)/2.);
    float qs = floor(time*tn)/tn;
    vec3 q2 = glitch(q1.xyz, qs);

    float r = .5;
    vec2 b = IS_GLITCH ?
        vec2(box(q2, r), 2.) : vec2(box(q1, r), 1.);
    d = minD(d, b);
   
    return d;
}

vec2 trace(in vec3 ro, in vec3 rd, in vec2 tmm) {
    float t = tmm.x;
    float m = -1.;
    for(int i=0;i<200;i++) {
        vec2 d = map(ro + rd*t);
        if(d.x<1e-4 || tmm.y<t) break;
        t += d.x * 0.5;
        m = d.y;
    }
    if(tmm.y<t) m = -1.;
    return vec2(t, m);
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1., -1.) * 1e-4;
    return normalize(
            e.xyy * map(p + e.xyy).x +
            e.yxy * map(p + e.yxy).x +
            e.yyx * map(p + e.yyx).x +
            e.xxx * map(p + e.xxx).x
        );
}

vec3 render(in vec3 ro, in vec3 rd, in vec2 uv) {
    vec3 col = vec3(0.);
    vec2 cmm = vec2(0., 30.);
    vec2 res = trace(ro, rd, cmm);
    float t = res.x, m = res.y;
    if(m < 0.) {
        col = vec3(0.);
    } else {
        vec3 pos = ro + rd*t;
        vec3 nor = calcNormal(pos);
        vec3 ref = reflect(rd, nor);
        vec3 opos = transform(pos);

        float w = 0.2;
        float n = 5.;
        col = vec3(grid(opos.xy+0.5, n, w) + grid(opos.yz+0.5, n, w));
        col = clamp(pow(col*2., vec3(1.4)), 0., 1.);
        if(IS_GLITCH) {
            col *= vec3(3.*noise(floor(glitch(opos))), 0., 0.);
        }
    }
    return col;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec2 p = (gl_FragCoord.xy*2.-resolution.xy) / min(resolution.x, resolution.y);
    vec3 col = vec3(0.);

    vec3 ro = vec3(0., -0.2*ft, 4.-2.*ft);
    if(hash(fract(it*432.543))<0.5) {
        ro.x += hash(it * 12.9898) *2. - 1.;
        ro.y += hash(it * 78.233)  *2. - 1.;
    }
    vec3 ta = vec3(0., 0., 0.);
    
    float cr = 0.;
    vec3 cz = normalize(ta - ro);
    vec3 cx = normalize(cross(cz, vec3(sin(cr), cos(cr), 0.)));
    vec3 cy = normalize(cross(cx, cz));
    vec3 rd = normalize(mat3(cx, cy, cz) * vec3(p, 2.));

    col = render(ro, rd, rd.xy);
    col *= smoothstep(0., 0.2, 1.-abs(ft*2.-1.));

    glFragColor = vec4(col, 1.);
}
