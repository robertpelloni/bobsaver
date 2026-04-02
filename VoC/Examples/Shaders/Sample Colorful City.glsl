#version 420

// original https://www.shadertoy.com/view/wlfXWM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

#define MARCH_MIN 1e-3
#define MARCH_MAX 1000.
#define MARCH_ITR 512
#define MARCH_THR 1e-5

#define BILL_W 1.0
#define BILL_H 4.0

// utils function -----------------------------------------------------------------
vec3 hsv(in float h, in float s, in float v) { return ((clamp(abs(fract(h+vec3(0., 2., 1.)/3.)*6.-3.)-1., 0., 1.)-1.)*s+1.)*v; }
mat2 rotate(in float r) { float c=cos(r), s=sin(r); return mat2(c, -s, s, c); }
vec2 rotate(in vec2 p, in float r) { return rotate(r) * p; }
vec3 rotate(in vec3 p, in vec3 r) {
  vec3 q = p;
  q.xy = rotate(q.xy, r.z);
  q.yz = rotate(q.yz, r.x);
  q.zx = rotate(q.zx, r.y);
  return q;
}

float hash(in float x) { return fract(sin(x) * 43237.5324); }
float hash(in vec2 x) { return fract(sin(dot(x, vec2(12.9898, 78.233)))*43237.5324); }
float hash(in vec3 x) { return fract(sin(dot(x, vec3(12.9898, 78.233, 49.256)))*43237.5324); }
vec3 hash3(in float x) { return vec3(hash(x), hash(x+999.), hash(x+99999.)); }

// distance function ----------------------------------------------------------------------------------------------
float box(in vec3 p, in vec3 b) { vec3 d=abs(p)-b; return length(max(d, 0.))+min(max(d.x, max(d.y, d.z)), 0.); }
float plane(in vec3 p, in vec3 n, in float h) { return dot(p, n) - h; }

// operator ------------------------------------------------------------------------------------------------------
vec2 opU(in vec2 d1, in vec2 d2) { return d1.x<d2.x ? d1 : d2; }
float smin(in float a, in float b, in float k) {
    float h = max(k - abs(a-b), 0.);
    return min(a, b) - h*h/(4.0*k);
}
vec4 opRep(in vec3 p, in vec3 c) {
    vec3 id = floor(p / c) * vec3(
        c.x>0. ? 1. : 0.,
        c.y>0. ? 1. : 0.,
        c.z>0. ? 1. : 0.
    );
    return vec4(mod(p, c) - 0.5*c, hash(id));
}

// map ------------------------------------------------------------------------------------------------------------
float tile(in vec3 p, in vec3 n, in vec2 h) {
    float d = plane(p, n, h.x);
    vec3 q = p; q.xz = mod(q.xz, 2.0) - 1.0;
    d = smin(d, box(q, vec3(0.95, h.y, 0.95)), .1);
    return d;
}
float boxs(in vec3 p, in vec3 b, in float r) {
    vec3 q = p;
    q.xz = abs(q.xz);
    q.xz = q.z<q.x ? q.xz : q.zx;
    float d = box(q-vec3(r, 0., 0.), b);
    return d;
}
float bill(in vec3 p, in vec2 b) {
    float d = box(p, b.xyx);
    float s = boxs(p, vec3(b.x*0.1, b.y*0.9, b.x*0.8), b.x);
    d = max(d, -s);
    //d = s;
    return d;
}

vec2 map( in vec3 p ) {
    vec2 res = vec2(1e8, -1.);
    res = opU(res, vec2(tile(p, vec3(0., 1., 0.), vec2(0., 0.08)), 0.));
    
    vec3 q = p;
    vec4 qtmp = opRep(q, vec3(BILL_W*7., 0., BILL_W*4.0));
    float h = BILL_H - qtmp.w*3.0;
    q.y -= h;
    q = vec3(qtmp.x, q.y, qtmp.z);
    q.x -= 1.0*(qtmp.w*2.0-1.0);
    res = opU(res, vec2(bill(q, vec2(BILL_W, h)), qtmp.w));
    return res;
}

// lighting --------------------------------------------------------------------------------------------------
vec3 calcNormal(in vec3 p) {
  vec2 e = vec2(1., -1.) * 2e-5;
  return normalize(
      e.xyy * map(e.xyy+p).x +
      e.yxy * map(e.yxy+p).x +
      e.yyx * map(e.yyx+p).x +
      e.xxx * map(e.xxx+p).x
    );
}
float diffuse(in vec3 n, in vec3 l, in float s) { return pow(clamp(dot(n, l), 0., 1.), s); }
float specular(in vec3 r, in vec3 l, in float s) { return pow(clamp(dot(r, l), 0., 1.), s); }

// ray marching  --------------------------------------------------------------------------------------------------
vec2 rayMarch(in vec3 ro, in vec3 rd) {
    float d=MARCH_MIN, m=-1.;
    for(int i=0;i<MARCH_ITR;i++) {
        vec2 tmp = map(ro + rd*d);
        if(tmp.x<MARCH_THR || MARCH_MAX<tmp.x) break;
        d += tmp.x*0.3;
        m = tmp.y;
    }
    if(MARCH_MAX<d) m=-1.;
    return vec2(d, m);
}

// color  --------------------------------------------------------------------------------------------------
vec3 getSkyColor(in vec3 rd) {
    return mix(vec3(1.), vec3(0.4, 0.6, 1.0), exp(rd.y));
}

// rendering  --------------------------------------------------------------------------------------------------
vec4 render(vec3 ro, vec3 rd) {
    vec4 result = vec4(0.);

    vec2 tmp = rayMarch(ro, rd);
    if(tmp.y<0.) {
        result = vec4(getSkyColor(rd), 1.);
    } else {
        // get surface info
        vec3 surfaceP = ro + rd*tmp.x;
        vec3 surfaceN = calcNormal(surfaceP);
        vec3 surfaceR = reflect(rd, surfaceN);
        
        // vec3 lp = vec3(5.);
        vec3 lp = ro - vec3(0., 0., -15.);
        vec3 directionalLight = normalize(vec3(1.));
        vec3 pointLight = normalize(lp - surfaceP);

        result = vec4(hsv(tmp.y, 0.<tmp.y?1.:0., 1.), 1.0);
        
        float diff = //diffuse(surfaceN, directionalLight, 1.);
                        + diffuse(surfaceN, pointLight, 1.);
        float spec = specular(surfaceR, pointLight, 100.);

        result *= 0.02+0.98*diff;
        result += spec;
    }
    
    result += clamp(1.0-exp(-0.01*tmp.x), 0., 1.);
    return result;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x, resolution.y);
    vec3 color = vec3(0.);

    // set camera
    vec3 ro = vec3(0., .3, -time*15.0);
    vec3 tar = ro + vec3(1., 2.5, -6.);
    vec3 cz = normalize(tar - ro);
    float cr = time*0.;
    vec3 cx = normalize(cross(cz, vec3(sin(cr), cos(cr), 0.)));
    vec3 cy = normalize(cross(cx, cz));
    vec3 rd = normalize(mat3(cx, cy, cz) * vec3(p, 2.));

    // rendering
    vec4 col = render(ro, rd);
    color = col.rgb;

    // screen space post effect
    color = pow(color, vec3(0.4545));

    glFragColor = vec4(color,1.0);
}
