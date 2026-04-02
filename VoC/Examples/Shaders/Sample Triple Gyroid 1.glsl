#version 420

// original https://neort.io/art/c415n5c3p9ffolj045v0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

const vec3 lightDir = normalize(vec3(-1, 2, 4));
const float lightPower = 20.0;
const vec3 lightColor = vec3(1, 1, 1) * lightPower;
const vec3 ambColor = vec3(1, 1, 1) * 0.2;
const float fogDensity = 0.05;
const float metal = 0.8;
const float f0 = 0.8;
const float fov = 80.;

const float PI = acos(-1.0);
const float PI2 = acos(-1.0) * 2.0;

mat3 rotate3D(float angle, vec3 axis){
    vec3 a = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float r = 1.0 - c;
    return mat3(
        a.x * a.x * r + c,
        a.y * a.x * r + a.z * s,
        a.z * a.x * r - a.y * s,
        a.x * a.y * r - a.z * s,
        a.y * a.y * r + c,
        a.z * a.y * r + a.x * s,
        a.x * a.z * r + a.y * s,
        a.y * a.z * r - a.x * s,
        a.z * a.z * r + c
    );
}

float sdGyroid(vec3 p) {
    return dot(sin(p), cos(p.yzx)) + 1.3;
}

float map(vec3 p) {
    float d = sdGyroid(p);
    d = min(d, sdGyroid(p + vec3(PI, 0, 0)));
    d = min(d, sdGyroid(p + vec3(PI, PI, 0)));
    return d;
}

vec3 calcNormal(vec3 p) {
    vec2 e = vec2(0.001, 0);
    return normalize(vec3(map(p+e.xyy)-map(p-e.xyy),
                          map(p+e.yxy)-map(p-e.yxy),
                          map(p+e.yyx)-map(p-e.yyx)
                          ));
}

float calcAO(vec3 rPos, vec3 ray) {
    float totao = 0.;
    float sca = 1.;
    for(int i=0; i<10; i++) {
        float hr = 0.01 + 0.02 * float(i*i);
        vec3 aoPos = rPos + ray * hr;
        float dd = map(aoPos);
        float ao = clamp(hr - dd, 0., 1.);
        totao += ao * sca;
        sca *= 0.75;
    }
    const float aoCoef = 0.5;
    return 1. - clamp(aoCoef * totao, 0., 1.);
}

float calcShadow(vec3 rPos, vec3 ray) {
    float h = 0.;
    float c = 0.001;
    float r = 1.;
    float shadowCoef = 0.5;
    for(int t = 0; t<10; t++) {
        h = map(rPos + ray * c);
        if(h < 0.001) {
            return shadowCoef;
        }
        r = min(r, h*16.0/c);
        c += h;
    }
    return 1.0 - shadowCoef + r * shadowCoef;
}

vec3 objColor(vec3 p) {
    vec3 col = vec3(0);
    float th = 0.5;
    if(sdGyroid(p) < th) {
        col = vec3(1.0, 0.1, 0.1);
    } else if(sdGyroid(p + vec3(PI, 0, 0)) < th) {
        col = vec3(0.1, 1.0, 0.1);
    } else if(sdGyroid(p + vec3(PI, PI, 0)) < th) {
        col = vec3(0.1, 0.1, 1.0);
    }
    return col;
}

float fresnelSchlick(float f0, float cosTheta) {
    return f0 + (1. - f0) * pow(1. - cosTheta, 5.);
}

float exp2InvFog(float dist, float density) {
    float s = dist * density;
    return exp(-s*s);
}

vec3 acesFilm(vec3 x) {
    const float a = 2.51;
    const float b = 0.03;
    const float c = 2.43;
    const float d = 0.59;
    const float e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0., 1.);
}

vec3 raymarching(inout vec3 rPos, inout vec3 ray, in int itr, inout bool hit, inout vec3 refAtt) {
    vec3 col = vec3(0);
    hit = false;
    float d = 0.;
    
    vec3 rPos0 = rPos;
    for(int i=0; i<100; i++) {
        if(i >= itr) break;
        d = map(rPos);
        if(abs(d) < 1e-4) {
            hit = true;
            break;
        }
        rPos += ray * d;
    }
    
    vec3 albedo = objColor(rPos);
    vec3 normal = calcNormal(rPos);
    vec3 ref = reflect(ray, normal);
    float diff = max(dot(normal, lightDir), 0.);
    float spec = pow(max(dot(reflect(lightDir, normal), ray), 0.), 10.);
    float ao = calcAO(rPos, normal);
    float shadow = calcShadow(rPos + normal * 0.005, lightDir); // memo: No shadow.

    col += albedo * diff * shadow * (1. - metal) * lightColor;
    col += albedo * spec * shadow * metal * lightColor;
    col += albedo * ao * ambColor;

    float invFog = exp2InvFog(distance(rPos0, rPos), fogDensity);
    col = mix(vec3(1), col, invFog);

    refAtt *= albedo * fresnelSchlick(f0, dot(ref, normal)) * invFog;
    rPos += 0.01 * normal;
    ray = ref;
    
    return col;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy * 2. - resolution) / min(resolution.x, resolution.y);
    vec3 col = vec3(0);
    
    vec3 cPos = vec3(0, 0, -fract(time/PI2)*PI2);
    vec3 cDir = normalize(vec3(0, 0, -1));
    vec3 cSide = normalize(cross(cDir, vec3(0, 1, 0)));
    vec3 cUp = normalize(cross(cSide, cDir));
    
    vec3 ray = normalize(uv.x*cSide + uv.y*cUp + cDir/tan(fov / 360. * PI));
    ray *= rotate3D(time * 0.07 * PI, vec3(5,3,1));
    
    vec3 rPos = cPos;
    bool hit = false;
    vec3 refAtt = vec3(1);
    
    col += raymarching(rPos, ray, 100, hit, refAtt);
    
    for(int i=0; i<2; i++) {
        //if(!hit) break;
        col += refAtt * raymarching(rPos, ray, 50, hit, refAtt);
    }
    
    col = acesFilm(col * 0.8);
    col = pow(col, vec3(1./2.2));
    
    glFragColor = vec4(col, 1.0);
}
