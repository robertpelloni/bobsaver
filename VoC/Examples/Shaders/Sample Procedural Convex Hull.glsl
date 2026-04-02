#version 420

// original https://www.shadertoy.com/view/Xd2BzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define numFaces 18
#define epsilon .001
#define time .5 * time
#define numSteps 100
#define far 20.0

float hash12(vec2 p)//Dave_Hoskins https://www.shadertoy.com/view/4djSRW
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash32(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+19.19);
    return fract((p3.xxy+p3.yzz)*p3.zyx);
}

vec3 generateNorm(float x){
    vec3 n1 = hash32(vec2(x, floor(time)));
    vec3 n2 = hash32(vec2(x, ceil(time)));
    return normalize(2.0 * mix(n1, n2, fract(time)) - 1.0);
}

vec3 generatePos(float x, vec3 n){
    float p1 = 1.0 + hash12(vec2(x, floor(time)));
    float p2 = 1.0 + hash12(vec2(x, ceil(time)));
    return n * mix(p1, p2, fract(time));
}

float sdPlane(vec3 p, vec3 o, vec3 n){return dot(n, p - o);}

float sdf(vec3 p){
    vec3 norm1 = generateNorm(0.0);
    vec3 norm2 = generateNorm(1.0);
    vec3 pos1 = generatePos(0.0, norm1);
    vec3 pos2 = generatePos(1.0, norm2);
    float d1 = sdPlane(p, pos1, norm1);
    float d2 = sdPlane(p, pos2, norm2);
    float d = max(d1, d2);
    for(int i = 2; i < numFaces; i++){
        float fi = float(i);
        vec3 n = generateNorm(fi);
        vec3 o = generatePos(fi, n);
        float d0 = sdPlane(p, o, n);
        d = max(d, d0);
    }
    return d;
}

vec3 getNormal(vec3 p){
    vec2 e = vec2(1.0, 0.0);
    return normalize(vec3(
        sdf(p + epsilon * e.xyy),
        sdf(p + epsilon * e.yxy),
        sdf(p + epsilon * e.yyx))
        - sdf(p));
}

vec4 render(vec3 rd, vec3 ro){
    float d = 0.0;
    for(int n = 0; n < numSteps; n++){
        vec3 p = d * rd + ro;
        float sd = sdf(p);
        if(sd < epsilon){
            vec3 normal = getNormal(p);
            return vec4(.5 + .5 * normal, 1.0);
        }
        d += sd;
        if(d > far) break;
    }
    return vec4(vec3(0), 1);
}

vec3 r(vec3 v, vec2 r){//rodolphito's rotation
    vec4 t = sin(vec4(r, r + 1.5707963268));
    float g = dot(v.yz, t.yw);
    return vec3(v.x * t.z - g * t.x,
                v.y * t.w - v.z * t.y,
                v.x * t.x + g * t.z);
}

void main(void)
{
    vec2 xy = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    vec3 rd = normalize(vec3(xy, 2.0));
    vec3 ro = vec3(0, 0, -10);
    vec2 m = (2.0 * mouse*resolution.xy.xy - resolution.xy) / resolution.y;
    rd = r(rd, m);
    ro = r(ro, m);
    glFragColor = render(rd, ro);
}
