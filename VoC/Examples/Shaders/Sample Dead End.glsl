#version 420

// original https://www.shadertoy.com/view/tdfcWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    PCD@Tokyo #dailycodingchallenge
    author: ankd
    theme : Dead-end (行き止まり)
*/

// constant
#define PI 3.14159265359
#define INF (1./0.)

// time
#define TT (time)
#define FT fract(TT)
#define IT floor(TT)

// u_circular function
#define usin(v) (sin(v)*0.5-0.5)
#define ucos(v) (cos(v)*0.5-0.5)

// rotation
mat2 rotate(in float r) { float c=cos(r), s=sin(r); return mat2(c,-s,s,c); }
vec2 rotate(in vec2 p, in float r) { return rotate(r)*p; }
vec3 rotate(in vec3 p, in vec3 r) {
    p.xy = rotate(p.xy, r.z);
    p.yz = rotate(p.yz, r.x);
    p.zx = rotate(p.zx, r.y);
    return p;
}

// random and noise
// reference and please add if you need from:
// - https://github.com/hughsk/glsl-noise
// - https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
float hash(in float v) { return fract(sin(v)*43758.5453); }
vec3 hash3(in float v) { return vec3(hash(v-999.), hash(v), hash(v+999.)); }
float hash(in vec2 v) { return fract(sin(dot(v, vec2(12.9898, 78.233)))*43758.5453); }
vec3 hash3(in vec2 v) { return vec3(hash(v-999.9), hash(v), hash(v+999.9)); }
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
const mat2 m2 = mat2(0.8,-0.6,0.6,0.8);
float fbm(in vec2 p){
    float f = 0.0;
    f += 0.5000*noise( p ); p = m2*p*2.02;
    f += 0.2500*noise( p ); p = m2*p*2.03;
    f += 0.1250*noise( p ); p = m2*p*2.01;
    f += 0.0625*noise( p );
    return f/0.9375;
}
float fbm(in vec3 p) {
    float f = 0.;
    f += 0.5000*noise( p ); p = rotate(p*2.02, vec3(0.3, 0.4, 0.5));
    f += 0.2500*noise( p ); p = rotate(p*2.03, vec3(0.3, 0.4, 0.5));
    f += 0.1250*noise( p ); p = rotate(p*2.01, vec3(0.3, 0.4, 0.5));
    f += 0.0625*noise( p );
    return f/0.9375;
}

// color filter
vec3 hsv(in float h, in float s, in float v) { return ((clamp(abs(fract(h+vec3(0.,2.,1.)/3.)*6.-3.)-1., 0., 1.)-1.)*s+1.)*v;  }
vec3 hsv(in vec3 c) { return hsv(c.x, c.y, c.z); }
float grayScale(in vec3 rgb) { return dot(rgb, vec3(0.298912, 0.586611, 0.114478)); }
vec3 invert(in vec3 rgb) { return 1.-rgb; }
vec3 gamma(in vec3 rgb) { return pow(rgb, vec3(0.4545)); }

// easing
float easeIn(in float v, in float e) { return pow(v, e); }
float easeOut(in float v, in float e) { return 1.-pow(1.-v, e); }
float easeInOut(in float v, in float e) { return v<0.5 ? 0.5*easeIn(v,e) : 0.5+0.5*easeOut(v,e); }
float easeOutIn(in float v, in float e) { return v<0.5 ? 0.5*easeOut(v,e) : 0.5+0.5*easeIn(v,e); }

/*
    ray marching function
*/
// 2d sdf
float circle(in vec2 p, in float r) { return length(p) - r; }
float rect(in vec2 p, in vec2 b) { vec2 d = abs(p)-b; return length(max(d,0.)) + min(max(d.x, d.y), 0.); }
float rect(in vec2 p, in float b) { return rect(p, vec2(b)); }

// 3d sdf
float sphere(in vec3 p, in float r) { return length(p) - r; }
float box(in vec3 p, in vec3 b) { vec3 d = abs(p)-b; return length(max(d, 0.)) + min(max(d.x, max(d.y, d.z)), 0.); }
float box(in vec3 p, in float b) { return box(p, vec3(b)); }
float plane(in vec3 p, in vec3 n, in float h) { return dot(p, n) - h; }

// operation
vec2 opU(in vec2 d1, in vec2 d2) { return d1.x<d2.x  ? d1 : d2; }// d1 or d2
vec2 opS(in vec2 d1, in vec2 d2) { return d1.x>-d2.x ? d1 : d2; }// d1 - d2
vec2 opI(in vec2 d1, in vec2 d2) { return d1.x>d2.x  ? d1 : d2; }// d1 and d2
vec2 opSU(in vec2 d1, in vec2 d2, in float k) {
    float h = clamp(0.5+0.5*(d2.x-d1.x)/k, 0., 1.);
    return vec2(mix(d2.x, d1.x, h) - k*h*(1.-h), d1.y);
}
vec2 opSS(in vec2 d1, in vec2 d2, in float k) {
    float h = clamp(0.5-0.5*(d2.x+d1.x)/k, 0., 1.);
    return vec2(mix(d2.x, -d1.x, h) + k*h*(1.-h), d1.y);
}
vec2 opSI(in vec2 d1, in vec2 d2, in float k) {
    float h = clamp(0.5-0.5*(d2.x-d1.x)/k, 0., 1.);
    return vec2(mix(d2.x, d1.x, h) + k*h*(1.-h), d1.y);
}

#define repeat(p,c) (mod(p,c)-0.5*c)
#define repeatid(p,c) (floor(p/c))

// camera
// ex)
// vec3 rd = camera(ro, vec3(0.), 60., 0., gl_FragCoord.xy, resolution.xy);
mat3 lookat(in vec3 eye, in vec3 target, in float cr) {
    vec3 cz = normalize(target - eye);
    vec3 cx = normalize(cross(cz, vec3(sin(cr), cos(cr), 0.)));
    vec3 cy = normalize(cross(cx, cz));
    return mat3(cx, cy, cz);
}
vec3 camera(
    in vec3 eye,
    in vec3 target,
    in float fov,// [deg]
    in float cr,// [deg]
    in vec2 coord,// = gl_FragCoord.xy
    in vec2 res// = resolution.xy
) {
    vec2 p = (coord*2.-res) / min(res.x, res.y);
    float fovRad = fov / 180. * PI;
    float aspect = res.x / res.y;
    vec3 dir = normalize(vec3(p, aspect/tan(0.5*fovRad)));
    return lookat(eye, target, cr) * dir;
}

vec3 ro, rd;

float tunnel(in vec3 p) { 
    float t = circle(p.xy, 1.2);
    float f = .3*fbm(rotate(p, vec3(0., 0., 0.3*noise(p.z*1.4)))*4.);
    return abs(t+f);
}

float door(in vec3 p) {
    float curt = length((p-ro) / rd);

    p.z = repeat(p.z, 10.);

    float b = box(p, vec3(1., 1., 0.1)) + 0.1*fbm(p.xy*10.);
    float b2 = sphere(p, mix(4., 0., clamp(curt*0.15, 0., 1.))) + 1.5*fbm(rotate(p.xy*8., p.z));

    return opSS(vec2(b2), vec2(b), 0.5).x;
}

vec2 particle(in vec3 p) {
    vec3 c = vec3(1.2);
    float r = 0.02;
    p = p - 0.5*c;
    vec3 id = repeatid(p,c);
    p = repeat(p, c);
    vec3 offset = (hash3(id.x + id.y + id.z)-0.5) * (0.9*c - r);
    
    float d = sphere(p-offset, r);
    return vec2(d, 2.);
}

vec2 map(in vec3 p) {
    vec2 m = vec2(tunnel(p), 0.);
    m = opSU(m, vec2(door(p), 1.), 0.5);
    m = opU(m, particle(p));
    return m;
}

vec2 castRay(in vec3 ro, in vec3 rd, in vec2 tmm) {
    float t = tmm.x;
    float c = -1.;
    for(int i=0;i<256;i++) {
        vec2 m = abs(map(ro + rd*t));
        if (m.x < 5e-4 || tmm.y<t) {
            break;
        }
        t += m.x*0.4;
        c = m.y;
    }
    if (tmm.y<t) {
        t = -1.;
        c = -1.;
    }
    return vec2(t, c);
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1., -1.)*5e-4;
    return normalize(
        e.xyy * map(p + e.xyy).x +
        e.yxy * map(p + e.yxy).x +
        e.yyx * map(p + e.yyx).x +
        e.xxx * map(p + e.xxx).x
    );
}

#define FOG_ITR 64
vec3 addFog(in vec3 ro, in vec3 rd, in vec2 tmm) {
    float t = tmm.x;
    float s = (tmm.y - tmm.x) / float(FOG_ITR);
    float v = 0.;
    for(int i = 0;i<FOG_ITR;i++) {
        vec3 p = ro + rd*t;
        p *= 1.2;
        v += pow(clamp(fbm(p)*0.8, 0., 1.), 8.);
        if (.8<v) break;
        t += s;
    }
    return vec3(v);
}

void main(void)
{
    float z = time;
    z *= 5.;
    ro = vec3(0.1, -0.8, -z);
    vec3 ta = ro + 2.*normalize(vec3(-.1, .2, -1.));
    rd = camera(
        ro,
        ta,
        60.,
        0.01*(noise(time*20.5)*2.-1.),
        gl_FragCoord.xy,
        resolution.xy
    );

    vec2 frustum = vec2(0., 100.);
    vec2 m = castRay(ro, rd, frustum);
    float t = m.x, c = m.y;
    vec3 pos = ro + rd*t;
    vec3 nor = calcNormal(pos);
    vec3 ref = reflect(rd, nor);

    // material
    vec3 col = vec3(1.);
    col *= exp(-0.1*t);
    
    // lighting
    vec3 lp = ta;
    vec3 ld = normalize(lp - pos);
    float ll = length(lp - pos);
    
    col *= clamp(dot(nor, ld), 0., 1.) * exp(-0.1*ll);// diffuse
    
    // add fog
    vec3 fog = addFog(ro, rd, vec2(0., t));

    // Output to screen
    vec2 st = (gl_FragCoord.xy*2.-resolution.xy) / min(resolution.x, resolution.y);
    col = pow(col, vec3(3.));
    col = mix(vec3(0.02, 0.05, 0.06), vec3(0.6, 0.7, 0.8), grayScale(col));
    col += fog;
    col *= clamp(2.-0.5*dot(st, st), 0., 1.);

    if (c<0.) col = vec3(0., 0., 1.);

    glFragColor = vec4(col,1.0);
}
