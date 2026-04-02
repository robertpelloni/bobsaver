#version 420

// original https://www.shadertoy.com/view/ttGSzR

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define LOOP_MAX 216
#define EPS 1e-4
#define HORIZONTAL_AA 1
#define saturate(x) clamp(x, 0.0, 1.0)
#define sim(x, y) (abs(x - y) < EPS)

const float PI = acos(-1.0);
const float PI2 = PI * 2.0;

vec2 uv = vec2(0.0, 0.0);
const vec3 dLight = normalize(vec3(0.2, 0.1, -0.5));
const vec3 pLight = vec3(0.0, 0.0, 0.6);

// https://thebookofshaders.com/10/?lan=jp
float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// https://qiita.com/kaneta1992/items/21149c78159bd27e0860
mat2 rot(float r) {
    float c = cos(r), s = sin(r);
    return mat2(c, s, -s, c);
}

vec2 pmod(vec2 p, float r) {
    float a =  atan(p.x, p.y) + PI/r;
    float n = PI2 / r;
    a = floor(a/n)*n;
    return p*rot(-a);
}

// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sphere( vec3 p, float s )
{
  return length(p)-s;
}

float cappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

vec3 repLim2(vec3 p, vec3 c, vec3 l)
{
    return p - c * clamp(round(p / c), -l, l);
}

float box( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float octahedron( vec3 p, float s)
{
  p = abs(p);
  return (p.x+p.y+p.z-s)*0.57735027;
}

// http://mercury.sexy/hg_sdf/
float fOpUnionRound(float a, float b, float r) {
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);
}

// The "Stairs" flavour produces n-1 steps of a staircase:
// much less stupid version by paniq
float fOpUnionStairs(float a, float b, float r, float n) {
    float s = r/n;
    float u = b-r;
    return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2.0 * s)) - s)));
}

float centerMap(vec3 p) {
    vec3 centerP = p + vec3(0.0, -0.04, -0.6);

    centerP.xz = centerP.xz * rot(time * PI * -0.4);
    centerP.xz = centerP.xz * rot(PI * 4.0 * centerP.y);
    centerP.xz = pmod(centerP.xz, 8.0) * 0.1;
    centerP.z -= 0.05 * (1.8 - abs(centerP.y) / 0.1) * 0.1;
    
    return box(centerP, vec3(0.001, 0.2, 0.001));
}

float coreMap(vec3 p) {
    vec3 coreP = p + vec3(0.0, -0.04, -0.6);
    
    coreP.xz = coreP.xz * rot(time * PI * 0.2);
    
    return octahedron(coreP, 0.05);
}

float map(vec3 p) {
    vec2 seedP = p.xz;
    seedP += vec2(EPS, 0.5);
    vec2 seed = vec2(floor(seedP.x), floor(seedP.y + EPS));
    
    vec3 sphereP = p;
    float sphereC = 0.6;
    sphereP.xz += vec2(sphereC * 0.5, -0.3);
    sphereP = repLim2(vec3(sphereP), vec3(sphereC, 0.0, 1.0), vec3(1.0, 1.0, 3.0));
    sphereP.y -= mod(time * 0.6 - random(seed) * 5.0, 3.0);
    sphereP.y += 0.5;
    
    vec3 pillarP = p;
    float pillarC = 0.8;
    pillarP.z -= 0.3;
    pillarP.x = abs(pillarP.x) - 0.7;
    pillarP.z = mod(pillarP.z + 0.5 * pillarC, pillarC) - 0.5 * pillarC - 0.2;
    
    vec3 dentP = pillarP;
    dentP.y -= 0.94;
    dentP.xz = pmod(dentP.xz, 20.0);
    dentP.z -= 0.1;

    float sphereDE = sphere(sphereP, 0.05);
    float pillarDE = cappedCylinder(pillarP, 0.1, 1.1);
    float dentDE = box(dentP, vec3(0.004, 1.1, 0.01));
    float planeDE = dot(p, vec3(0.0, 1.0, 0.0)) + 0.2;
    
    float milk = fOpUnionRound(sphereDE, planeDE, 0.07);
    float pillars = fOpUnionStairs(planeDE, max(-dentDE, pillarDE), 0.07, 5.0);
    float center = min(centerMap(p), coreMap(p));
    return min(min(milk, pillars), center);
}

vec3 norm(vec3 p) {
    return normalize(vec3(
        map(p + vec3(EPS, 0.0, 0.0)) - map(p + vec3(-EPS, 0.0, 0.0)),
        map(p + vec3(0.0, EPS, 0.0)) - map(p + vec3(0.0, -EPS, 0.0)),
        map(p + vec3(0.0, 0.0, EPS)) - map(p + vec3(0.0, 0.0, -EPS))
        ));
}

float fog(float depth) {
    float density = 0.6;
    return 1.0 - saturate(1.0 / exp(pow(density * depth, 2.0)));
}

float ao(vec3 p, vec3 n, float amp, float len) {
    float amt = 0.0;
    for(int i = 0; i < 4; i++) {
        p = p + len * n;
        amt += amp * saturate(map(p) / len);
        amp *= 0.5;
        len += 0.02;
    }
    return amt;
}

// https://www.shadertoy.com/view/lsKcDD
float softShadow(vec3 p, vec3 light) {
    float minDist = 1e-6;
    float maxDist = 10.0;
    
    float sharpness = 35.0;
    
    float s = 1.0;
    float ph = 1e20;
    float dist = minDist;
    for(int i = 0; i < 32; i++) {
        float st = centerMap(p + light * dist);
        
        float y = (i == 0) ? 0.0 : st * st / (2.0 * ph);
        float d = sqrt(st * st - y * y);
        s = min(s, sharpness * d / max(0.0, dist - y));
        
        ph = st;
        dist += st;
        
        if(s < 1e-6 || maxDist < dist) {
            break;
        }
    }
    
    return 1.0 - max(s, 0.0);
}

vec3 objMat(vec3 rp) {
    vec3 no = norm(rp);
    vec3 dpl = normalize(pLight - rp);
    float ipl = distance(pLight, rp);
    
    vec3 albedo = vec3(0.4);
    float pDiff = saturate(dot(dpl, no)) * (1.0 / (ipl * 1.5));
    float shadow = softShadow(rp, dpl);
    float a = ao(rp, no, 0.5, 0.01) * 0.7 + 0.5;
    return (albedo + pDiff * 0.2) * a * (mix(0.6, 0.5, shadow) * (1.0 / (ipl * 3.0)));
}

vec3 centerMat(vec3 rp) {
    vec3 no = norm(rp);
    vec3 invDLight = dLight * -1.0;
    vec3 dpl = normalize(pLight - rp);
    float ipl = distance(pLight, rp);
    
    vec3 albedo = vec3(0.15);
    float dif = saturate(dot(invDLight, no));
    float pDiff = saturate(dot(dpl, no)) * (1.0 / ipl);
    float a = ao(rp, no, 1.8, 0.07) * 0.8 + 0.5;
    return (albedo + dif * pDiff * 2.0) * (1.0 - a);
}

vec3 coreMat(vec3 rp) {
    vec3 no = norm(rp);
    vec3 invDLight = dLight * -1.0;
    
    vec3 albedo = vec3(1.3);
    float dif = saturate(dot(invDLight, no));
    return albedo + dif;
}

vec3 skyMat() {
    return mix(vec3(0.13), vec3(0.0), uv.y * 0.5);
}

vec3 march(vec3 ro, vec3 rd, out vec3 rp, out float depth) {
    vec3 col = vec3(0.0);
    depth = 1.0;
    
    for(int i = 0; i < LOOP_MAX; i++) {
        rp = ro + rd * depth;
        float dist = map(rp);
        
        if(abs(dist) < EPS) {
            if(sim(dist, centerMap(rp))) {
                col = centerMat(rp);
            }
            else if(sim(dist, coreMap(rp))) {
                col = coreMat(rp);
            }
            else {
                col = objMat(rp);
            }
            break;
        }
        else {
            col = skyMat();
        }
        
        depth += dist;
    }
    return col;
}

vec3 render(vec2 p) {
    float fov = 80.0 * 0.5 * PI / 180.0;
    vec3 cp = vec3(0.0, 0.01, -0.7);
    vec3 cd = normalize(vec3(0.0) - cp);
    vec3 cs = normalize(cross(cd, vec3(0.0, 1.0, 0.0)));
    vec3 cu = normalize(cross(cs, cd));
    float td = 1.0 / tan(fov / 2.0);
    
    vec3 ro = cp;
    vec3 rd = normalize(cs * p.x + cu * p.y + cd * td);
    vec3 rp = vec3(0.0);
    
    vec3 col = vec3(0.0);
    float depth = 1.0;
    col += march(ro, rd, rp, depth);
    
    return mix(col, skyMat(), fog(depth));
}

void main(void)
{
    uv = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
    
    vec3 col = vec3(0.0);
    for(int x = 0; x < HORIZONTAL_AA; x++)
    {
        vec2 delta = vec2(float(x - HORIZONTAL_AA / 2), 0.0) * 1e-3;
        col += render(uv + delta);
    }

    glFragColor = vec4(col / float(HORIZONTAL_AA), 1.0);
}
