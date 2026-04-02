#version 420

// original https://neort.io/art/c061k3c3p9f30ks59ho0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

float pi = acos(-1.0);
float twoPi = pi * 2.0;
#define ITER 2

float at = 0.0;

mat2 rotate(float angle){
    float c = cos(angle);
    float s = sin(angle);
    return mat2(c, -s, s, c);
}

float random(vec3 v) { 
    return fract(sin(dot(v, vec3(12.9898, 78.233, 19.8321))) * 43758.5453);
}

float valueNoise(vec3 v) {
    vec3 i = floor(v);
    vec3 f = smoothstep(0.0, 1.0, fract(v));
    return  mix(
        mix(
            mix(random(i), random(i + vec3(1.0, 0.0, 0.0)), f.x),
            mix(random(i + vec3(0.0, 1.0, 0.0)), random(i + vec3(1.0, 1.0, 0.0)), f.x),
            f.y
        ),
        mix(
            mix(random(i + vec3(0.0, 0.0, 1.0)), random(i + vec3(1.0, 0.0, 1.0)), f.x),
            mix(random(i + vec3(0.0, 1.0, 1.0)), random(i + vec3(1.0, 1.0, 1.0)), f.x),
            f.y
        ),
        f.z
    );
}

float fbm(vec3 v) {
    float n = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        n += a * valueNoise(v);
        v *= 2.0;
        a *= 0.5;
    }
    return n;
}

vec3 repeat(vec3 p, float repCoef){
    return (fract(p/repCoef - 0.5) - 0.5) * repCoef;
}

vec2 repeat(vec2 p, float repCoef){
    return (fract(p/repCoef - 0.5) - 0.5) * repCoef;
}

float repeat(float z, float repCoef){
    return (fract(z/repCoef - 0.5) - 0.5) * repCoef;
}

vec3 kifs(vec3 p, float t){
    for(int i = 0; i < ITER; i++){
        float t1 = t + float(i);
        p.yz *= rotate(t1 * p.z * 0.01);
        p = abs(p);
        p -= vec3(1.5, 0.3, 0.1);
    }

    return p;
}

vec2 polarMod(vec2 p, float r) {
    float a =  atan(p.x, p.y) + pi/r;
    float n = twoPi / r;
    a = floor(a/n)*n;
    return p*rotate(-a);
}

float sdPlane(vec3 p, vec3 v){
    return dot(p, normalize(v));
}

float sdBox(vec3 p, vec3 s){
    vec3 q = abs(p) - s;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdSphere(vec3 p, float r){
    return length(p) - r;
}

float distanceFunction(vec3 p){
    vec3 p1 = p;
    p1.xy *= rotate(p1.z * 0.422);
    p1.z = repeat(p1.z, 2.0);
    p1 = abs(p1) - vec3(3.9, 2.8, 0.3);
    p1.yz = polarMod(p1.zy, 6.0);
    p1 = kifs(p1, 2.222 * fbm(p.zzz));
    float d = sdBox(p1, vec3(0.2, 0.4, 1.8) * fbm(vec3(p1.yzx + time*0.5)) * 2.2);

    vec3 p2 = p;
    p2.z = repeat(p2.z, 2.0);
    float plane = sdPlane(p2, vec3(0.0, 0.0, 1.0));

    float dist = max(d, -plane);
    at += 0.022/(0.1+abs(dist));

    return dist;
}

vec3 getNormal(vec3 p){
    vec2 error = vec2(0.01, 0.0);
    return normalize(vec3(distanceFunction(p + error.xyy) - distanceFunction(p - error.xyy),
                          distanceFunction(p + error.yxy) - distanceFunction(p - error.yxy),
                          distanceFunction(p + error.yyx) - distanceFunction(p - error.yyx)));
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);
    vec3 camPos = vec3(0.0, 0.0, -8.0 + time * 8.0);
    vec3 lookPos = vec3(0.0, 0.0, 3.0 + time * 8.0);
    vec3 forward = normalize(lookPos - camPos);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = normalize(cross(forward, right));
    float fov = 1.0;
    vec3 rayDir = normalize(uv.x * right + uv.y * up + forward * fov);

    vec3 lightPos = vec3(10.0 * cos(time * 0.8), 10.0 * sin(time * 0.3), -10.0 * sin(time * 0.8));

    float d = 0.0;
    float df = 0.0;
    vec3 p = vec3(0.0);
    for(int i = 0; i < 64; i++){
        p = camPos + rayDir * d * 0.8;
        df = distanceFunction(p);
        if(df <= 0.001){
            break;
        }
        if(df > 100.0){
            color = vec3(0.0);
            break;
        }
        d += df * 0.7;
        color += pow(at * 0.12, 2.0) * vec3(0.451, 0.7765, 0.4235);
    }
    float fog = (1.0 - clamp(length(camPos - p)/32.0, 0.0, 1.0));
    color *= pow(fog, 4.0);

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution)/min(resolution.x, resolution.y);
    vec3 color = renderingFunc(uv);
    glFragColor = vec4(color, 1.0);
}
