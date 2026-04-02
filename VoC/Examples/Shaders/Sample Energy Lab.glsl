#version 420

// original https://www.shadertoy.com/view/3dd3WB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 1

#define FLT_EPS  5.960464478e-8

#define MAT_FLOOR 0.
#define MAT_PIPE 1.
#define MAT_CAGE 2.
#define MAT_BALL 3.
#define MAT_LIGHT 4.

const float pi = acos(-1.0);
const float pi2 = pi * 2.0;
float time2;

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c,s,-s,c);
}

vec2 pmod(vec2 p, float r) {
    float a = pi/r - atan(p.x, p.y);
    float n = pi2/r;
    a = floor(a/n)*n;
    return p * rot(a);
}

// by http://mercury.sexy/hg_sdf/
float fOpDifferenceRound(float a, float b, float r) {
    vec2 u = max(vec2(r + a,r - b), vec2(0));
    return min(-r, max (a, -b)) + length(u);
}

float fOpPipe(float a, float b, float r) {
    return length(vec2(a, b)) - r;
}

float fOpUnionStairs(float a, float b, float r, float n) {
    float s = r/n;
    float u = b-r;
    return min(min(a,b), 0.5 * (u + a + abs ((mod (u - a + s, 2. * s)) - s)));
}

float fOpDifferenceStairs(float a, float b, float r, float n) {
    return -fOpUnionStairs(-a, b, r, n);
}

// by https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
float sphere(vec3 p, float r) {
    return length(p) - r;
}

float cylinder(vec3 p, float r, float h) {
    float d = length(p.xz) - r;
    p.y = abs(p.y) - h;
    return max(d, p.y);
}

float torus(vec3 p, float r, float s) {
    vec2 q = vec2(length(p.xz) - s, p.y);
    return length(q) - r;
}

float sdCappedTorus(in vec3 p, in vec2 sc, in float ra, in float rb)
{
    p.x = abs(p.x);
    float k = (sc.y*p.x>sc.x*p.z) ? dot(p.xz,sc) : length(p.xz);
    return sqrt( dot(p,p) + ra*ra - 2.0*ra*k ) - rb;
}

vec2 min2(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}

vec2 lightTube(vec3 p, float r) {
    p.xz *= rot(pi * 0.2);
    p.xz = pmod(p.xz, 5.0);
    //p.z -= 5.1;
    float a = pi * 0.1;
    float s1 = sdCappedTorus(p, vec2(sin(a), cos(a)), 8.05, 0.1);
    return vec2(s1, MAT_LIGHT);
}

vec2 cage(vec3 p) {
    p.y += sin(time2) * 0.1;
    p.xy *= rot(-pi*0.5);
    p.yz *= rot(time2 * 0.5);
    p.yz = pmod(p.yz, 7.0);
    p.yx = pmod(p.yx, 7.0);
    
    return vec2(torus(p, 0.025, 0.55), MAT_CAGE);
}

vec2 object(vec3 p) {
    vec2 s = vec2(sphere(p - vec3(0.0, cos(time2) * 0.1, 0.0), 0.25), MAT_BALL);
    vec2 c = cage(p);
    return min2(s, c);
}

float energyAnim(float z) {
    float et = mod(z + time2, pi2);
    float etOffset = pi * 1.5;
    return (smoothstep(etOffset - 0.2, etOffset, et) - smoothstep(etOffset + 0.2, etOffset + 0.4, et));
}

vec2 room(vec3 p) {
    p.y = -abs(p.y);
    // Floor
    vec2 tile = fract(p.xz * 8.0) * 2.0 - 1.0;
    tile = abs(tile) - 0.5;
    float dd = max(max(tile.x, tile.y), 0.0);
    
    float flor = fOpDifferenceStairs(p.y, cylinder(p, 8.0, 4.0), 4.0, 15.);
    flor = fOpUnionStairs(flor, cylinder(p - vec3(0.0, -4.0, 0.0), 1.0, 1.0), 1.0, 5.);
    
    // Pipe
    p.xz = pmod(p.xz, 5.0);
    float pipeDent = (smoothstep(0.4, 0.5, fract(p.z*10.0)) - smoothstep(0.5, 0.6, fract(p.z*10.0)));

    float energy = energyAnim(p.z);
    float pipe = fOpPipe(flor - 0.05, abs(p.x + sin(p.z*2.0) * 0.1), 0.07) + pipeDent * 0.01 - energy * 0.05;
    
    // Floor dent along the pipe
    flor = fOpDifferenceRound(flor + dd * 0.02, pipe, 0.1);
    
    return min2(vec2(flor * 0.9, MAT_FLOOR), vec2(pipe * 0.9, MAT_PIPE));
}

vec2 map(vec3 p) {
    //p.x += sin(p.x * 5.0) * 0.1;
    vec2 o = object(p - vec3(0.0, -2.0, 0.0));
    vec2 r = room(p);
    
    vec2 d = min2(r, o);
    
    d = min2(d, lightTube(p - vec3(0.0, -3.85, 0.0), 5.0));
    p.xz *= rot(time2 * 2.0);
    d = min2(d, lightTube(p - vec3(0.0, 0.0, 0.0), 6.0));
    
    return d;
}

vec2 shadowMap(vec3 p) {
    //p.x += sin(p.x * 5.0) * 0.1;
    vec2 o = cage(p - vec3(0.0, -2.0, 0.0));
    vec2 r = room(p);
    
    vec2 d = min2(r, o);
    
    return d;
}

vec3 normal(vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.00005;
    return normalize(
        e.xyy * map(p+e.xyy).x+
        e.yxy * map(p+e.yxy).x+
        e.yyx * map(p+e.yyx).x+
        e.xxx * map(p+e.xxx).x
        );
}

vec3 normal2(vec3 pos)
{
    vec3 eps = vec3(0.001,0.0,0.0);

    return normalize( vec3(
           map(pos+eps.xyy).x - map(pos-eps.xyy).x,
           map(pos+eps.yxy).x - map(pos-eps.yxy).x,
           map(pos+eps.yyx).x - map(pos-eps.yyx).x ) );
}

float shadow(vec3 p, vec3 ray, float ma) {
    float t = 0.1;
    float res = 1.0;
    for(int i = 0; i < 24; i++) {
        if (t > ma) break;
        vec3 pos = p + ray * t;
        float d = shadowMap(pos).x;
        if (d < 0.0001) return 0.0;
        t += d;
        res = min(res, 10.0 * d / t);
    }
    return res;
}

vec3 acesFilm(const vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d ) + e), 0.0, 1.0);
}

float luminance(vec3 col)
{
    return dot(vec3(0.298912, 0.586611, 0.114478), col);
}

vec3 reinhard(vec3 col, float exposure, float white) {
    col *= exposure;
    white *= exposure;
    float lum = luminance(col);
    return (col * (lum / (white * white) + 1.0) / (lum + 1.0));
}

vec3 origin;

float roughnessToExponent(float roughness)
{
    return clamp(2.0 * (1.0 / (roughness * roughness)) - 2.0, FLT_EPS, 1.0 / FLT_EPS);
}

vec3 light(vec3 p, vec3 n, vec3 v, vec3 lp, vec3 baseColor, float roughness, float reflectance, float metallic, vec3 radiance) {
    vec3 f0 = mix(vec3(reflectance), baseColor, metallic);
    vec3 kd = mix(1.0 - f0, vec3(0.0), metallic);
    
    vec3 l = lp - p;
    float len = length(l);
    l /= len;
    
    float LdotN = max(0.0, dot(l, n));
    vec3 h = normalize(l + v);
    
    vec3 diffuse = kd * baseColor / pi;
    
    float m = roughnessToExponent(roughness);
    vec3 specular = f0 * pow( max( 0.0, dot( n, h ) ), m ) * ( m + 2.0 ) / ( 2.0 * pi );
    return (diffuse + specular) * radiance * LdotN / (len*len);
}

vec3 evalLights(vec3 p, vec3 n, vec3 ray, vec3 baseColor, float roughness, float reflectance, float metallic) {
    // Object Light
    vec3 lp = vec3(0.0, -2.0 + cos(time2) * 0.1, 0.0);
    vec3 v = lp - p;
    float len = length(v);
    v /= len;
    vec3 result = light(p, n, -ray, lp, baseColor, roughness, reflectance, metallic, vec3(0.6, 0.05, 0.01) * (sin(time2) * 0.5 + 0.5) * 20.0) * shadow(p + n * 0.005, v, len);
    
    // Camera Light
    result += light(p, n, -ray, origin, baseColor, roughness, reflectance, metallic, vec3(2.0));
    return result;
}

void getSurfaceParams(vec3 p, vec2 mat, out vec3 outBaseColor, out vec3 outEmission, out float outRoughness, out float outReflectance, out float outMetallic) {
    outBaseColor = vec3(0.0);
    outEmission = vec3(0.0);
    outRoughness = 1.0;
    outMetallic = 0.0;
    outReflectance = 0.04;
    if (mat.y == MAT_FLOOR) {
        outBaseColor = vec3(0.5);
        outRoughness = 0.05;
    } else if (mat.y == MAT_PIPE) {
        outBaseColor = vec3(0.7);
        outRoughness = 0.2;
        outMetallic = 1.0;
        p.xz = pmod(p.xz, 5.0);
        float pipeDent = (smoothstep(0.4, 0.5, fract(p.z*10.0)) - smoothstep(0.5, 0.6, fract(p.z*10.0)));
        float energy = energyAnim(p.z);
        outEmission = mix(vec3(0.6, 0.05, 0.01), vec3(0.01, 0.05, 0.6), clamp(p.z * 0.2, 0.0, 1.0)) * 4.0 * energy * (1.0 - pipeDent);
    } else if (mat.y == MAT_CAGE) {
        outBaseColor = vec3(0.8, 0.6, 0.2);
        outRoughness = 0.15;
        outMetallic = 1.0;
    } else if (mat.y == MAT_BALL) {
        outBaseColor = vec3(0.6);
        outEmission = vec3(0.6, 0.05, 0.01) * 4.0 * (sin(time2) * 0.5 + 0.5);
        outRoughness = 0.2;
        outReflectance = 0.0;
    } else if (mat.y == MAT_LIGHT) {
        outBaseColor = vec3(0.6);
        outEmission = vec3(4.0);
        outRoughness = 0.2;
        outReflectance = 0.0;
    }
}

void trace(vec3 p, vec3 ray, float tmax, int ite, out vec3 outPos, out vec2 outMat, out float depth) {
    float t = 0.1;
    vec3 result = vec3(0.0), pos;
    vec2 mat;
    for(int i = 0; i < ite; i++) {
        if (t > tmax) break;
        pos = ray * t + p;
        mat = map(pos);
        if (mat.x < 0.0001) break;
        t += mat.x;
    }
    depth = t;
    outPos = pos;
    outMat = mat;
}

vec3 shade(vec3 p, vec3 ray, vec2 mat) {
    vec3 baseColor, emission;
    float roughness, metallic, reflectance;
    
    getSurfaceParams(p, mat, baseColor, emission, roughness, reflectance, metallic);
    vec3 n = normal(p);
    
    vec3 result = evalLights(p, n, ray, baseColor, roughness, reflectance, metallic) + emission;
    vec3 f0 = vec3(1.0);
    for(int i=0; i<1; i++) {
        f0 *= mix(vec3(reflectance), baseColor, metallic);
        vec3 secondPos;
        vec2 secondMat;
        float depth;
        ray = reflect(ray, n);
        trace(p + n * 0.001, ray, 100.0, 24, secondPos, secondMat, depth);
        getSurfaceParams(p, secondMat, baseColor, emission, roughness, reflectance, metallic);
        n = normal(secondPos);
        p = secondPos;
        result += (evalLights(secondPos, n, ray, baseColor, roughness, reflectance, metallic) + emission) * f0;
    }
    
    return result;
}

void main(void)
{
    vec2 p = (gl_FragCoord.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);

    vec3 col = vec3(0.0);
    int aa = AA;
    float tt = 0.0;
    float depth;
    for(int y=0; y<aa; y++) {
        vec2 fc;
        fc.y = gl_FragCoord.y + float(y)/float(aa);
        for(int x=0; x<aa; x++) {
            fc.x = gl_FragCoord.x + float(x)/float(aa);
            p = (fc.xy * 2.0 - resolution.xy) / min(resolution.x, resolution.y);
            time2 = time + tt;
            origin = vec3(sin(time2 * 0.1)*1.0 + cos(time2 * 0.5)*0.5, sin(time2 * 0.3) * 1.0 + cos(time2 * 1.0)*0.25 + sin(time2 * 3.0)*0.1 - 1.0, 5.0);
            vec3 target = vec3(0.0, -2., 0.);
            vec3 fo = normalize(target - origin);
            vec3 si = normalize(cross(vec3(0.0, 1.0, 0.0), fo));
            vec3 up = normalize(cross(fo, si));
            vec3 ray = normalize(fo * (2.5 + (sin(time2 * 0.5)*0.5 + 0.5)*2.0 + (1.0 - dot(p, p)) * 0.05) + si * p.x + up * p.y);

            tt += 0.04 / float(aa*aa);
            vec3 surfacePos;
            vec2 surfaceMat;
            trace(origin, ray, 100.0, 99, surfacePos, surfaceMat, depth);
            col += acesFilm(shade(surfacePos, ray, surfaceMat) * 2.0);
        }
    }
    col /= float(aa*aa);

    col = pow(col, vec3(1.0/2.2));
    
    p = gl_FragCoord.xy / resolution.xy;
    p *=  1.0 - p.yx;
    float vig = p.x*p.y * 30.0;
    vig = pow(vig, 0.1);

    glFragColor = vec4(col * vig,1.0);
}
