#version 420

// original https://neort.io/art/c0263gk3p9f30ks58rug

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

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

float sdPlane(vec3 p, vec4 n){
    return dot(p, n.xyz) + n.w;
}

float tunnel(vec3 p){
    vec3 p1 = p;
    vec3 p2 = p;
    p1 = -abs(p1);
    p1.y += 0.5;
    float plane1 = sdPlane(p1, vec4(0., 1., 0., 1.)) + sin(fbm(vec3(p1.zz, time*0.3)));

    p2 = -abs(p2);
    p1.x += 0.5;
    float plane2 = sdPlane(p2, vec4(1., 0., 0., 1.)) + fbm(vec3(p2.zz, time*0.4));

    return min(plane1, plane2);
}

float distanceFunction(vec3 p){
    p.xy *= rotate(p.z * 1.22);
    float tunnel = tunnel(p) * 0.252;
    return tunnel;
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
    vec3 camPos = vec3(cos(time) * 0.4, sin(time) * 0.4, -4.0 + time * 4.0);
    vec3 lookPos = vec3(0.0, 0.5, time * 4.0);
    vec3 forward = normalize(lookPos - camPos);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = normalize(cross(forward, right));
    float fov = 1.0;
    vec3 rayDir = normalize(uv.x * right + uv.y * up + forward * fov);

    vec3 lightPos = vec3(0.0, 0.0, -10.0 + time * 4.0);

    float d = 0.0;
    float df = 0.0;
    vec3 p = vec3(0.0);
    float at = 0.0;
    for(int i = 0; i < 100; i++){
        p = camPos + rayDir * d;
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
    float fog = 1.0 - clamp(length(camPos - p)/12.0, 0.0, 1.0);

    vec3 lv = lightPos - p;
    vec3 normal = getNormal(p);
    float l = 1.0 - clamp(dot(normal, normalize(lv)), 0.0, 1.0);
    color += l * pow(fog, 1.365) * ((sin(fog * 80.0 - time * 22.0)+1.0) / 2.0) * pow(at, 0.222) * 0.6;
    color += pow(0.05 / length(uv + vec2(cos(time) * 0.1, 0.125 + sin(time) * 0.01)), 1.4646);
    
    glFragColor = vec4(color, 1.0);
}
