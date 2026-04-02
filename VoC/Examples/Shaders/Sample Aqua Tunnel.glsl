#version 420

// original https://neort.io/art/c01vio43p9f30ks58p30

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

float sphereAt = 0.0;

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

float smoothMin(float d1, float d2, float k){
    float h = exp(-k * d1) + exp(-k * d2);
    return -log(h) / k;
}

float sdPlane(vec3 p, vec4 n){
    return dot(p, n.xyz) + n.w;
}

float sdSphere(vec3 p, float r){
    return length(p) - r;
}

float tunnel(vec3 p){
    vec3 p1 = p;
    vec3 p2 = p;
    p1 = -abs(p1);
    p1.y += 0.5;
    float plane1 = sdPlane(p1, vec4(0., 1., 0., 1.)) + fbm(vec3(p1.xz, time*0.3)) * (1.2 + sin(time*0.6+422.2) * 0.2);

    p2 = -abs(p2);
    p1.x += 0.5;
    float plane2 = sdPlane(p2, vec4(1., 0., 0., 1.)) + fbm(vec3(p2.yz, time*0.4)) * (1.5 + sin(time*0.5+42.2) * 0.3);

    return min(plane1, plane2);
}

float balls(vec3 p, float z){
    float sphere1 = sdSphere(p - vec3(cos(time * 1.1 + 10.0), sin(time * 4.1 + 14.0),  z + 0.2 + time * 4.0), 0.6);
    float sphere2 = sdSphere(p - vec3(-cos(time * 2.1 + 20.0),sin(time * 3.1 + 24.0),  z + 0.3 + time * 4.0), 0.59);
    float sphere3 = sdSphere(p - vec3(cos(time * 3.1 + 30.0), -sin(time * 2.1 + 34.0), z + 0.4 + time * 4.0), 0.42);
    float sphere4 = sdSphere(p - vec3(-cos(time * 4.1 + 40.0),-sin(time * 1.1 + 44.0), z + 0.5 + time * 4.0), 0.67);

    float s = smoothMin(smoothMin(smoothMin(sphere1, sphere2, 4.0), sphere3, 4.0), sphere4, 4.0);
    sphereAt += 0.42 / abs(s);
    return s;
}

float distanceFunction(vec3 p){
    float spheres = balls(p, 6.4);
    vec3 tp = p;
    tp.xy *= rotate(tp.z * 0.4);
    float tunnel = tunnel(tp);
    float displaySpheres = balls(p, 1.0);
    return min(smoothMin(spheres, tunnel, 1.0), displaySpheres);
}

vec3 getNormal(vec3 p){
    vec2 error = vec2(0.01, 0.0);
    return normalize(vec3(distanceFunction(p + error.xyy) - distanceFunction(p - error.xyy),
                          distanceFunction(p + error.yxy) - distanceFunction(p - error.yxy),
                          distanceFunction(p + error.yyx) - distanceFunction(p - error.yyx)));
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution)/min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    vec3 camPos = vec3(cos(-time), sin(-time), -4.0 + time * 4.0);
    vec3 lookPos = vec3(0.0, 0.5, time * 4.0);
    vec3 forward = normalize(lookPos - camPos);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = normalize(cross(forward, right));
    float fov = 1.0;
    vec3 rayDir = normalize(uv.x * right + uv.y * up + forward * fov);

    vec3 lightPos = vec3(0.0, 0.0, 10.0 + time * 4.0);

    float d = 0.0;
    float df = 0.0;
    vec3 p = vec3(0.0);
    float at = 0.0;
    for(int i = 0; i < 100; i++){
        p = camPos + rayDir * d * 0.85;
        df = distanceFunction(p);
        if(df <= 0.001){
            break;
        }
        if(df > 100.0){
            break;
        }
        d += df;
        at += 1.0 / abs(df);
    }
    float fog = 1.0 - clamp(length(camPos - p)/22.0, 0.0, 1.0);

    vec3 lv = lightPos - p;
    vec3 normal = getNormal(p);
    float l = 1.0 - clamp(dot(normal, normalize(lv)), 0.0, 1.0);
    color += l * mix(vec3(0.0, 0.1843, 1.0), vec3(0.0471, 0.251, 0.5333), cos(fog * 40.0 + time * 22.0)) * pow(fog, 6.365) * pow(at, 0.262) * pow(sphereAt, 0.289);
    color += pow(0.09 / length(uv + vec2(0.0, 0.125)), 1.4646);
    
    glFragColor = vec4(color, 1.0);
}
