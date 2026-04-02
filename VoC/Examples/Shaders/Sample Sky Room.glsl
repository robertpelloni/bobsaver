#version 420

// original https://neort.io/art/c01er043p9f30ks58lsg

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;

out vec4 glFragColor;

float random(vec3 v) { 
    return fract(sin(dot(v, vec3(12.9898, 78.233, 19.8321))) * 43758.5453);
}

float random(vec2 v) { 
    return fract(sin(dot(v, vec2(12.9898, 78.233))) * 43758.5453);
}

float random(float v) {
    return fract(sin(v * 12.9898) * 43758.5453);
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

float sdBox(vec3 p, vec3 b){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdPlaneY(vec3 p){
    return p.y;
}

float distanceFunction(vec3 p){
    float box = sdBox(p - vec3(0.0, 30.0, 80.0), vec3(250.0, 60.0, 5.0));
    return box;
}

float distancePlane(vec3 p){
    float planeY = sdPlaneY(p);
    return planeY;
}

vec3 getNormal(vec3 p){
    vec2 error = vec2(0.01, 0.0);
    return normalize(vec3(distanceFunction(p + error.xyy) - distanceFunction(p - error.xyy),
                          distanceFunction(p + error.yxy) - distanceFunction(p - error.yxy),
                          distanceFunction(p + error.yyx) - distanceFunction(p - error.yyx)));
}

vec3 skyTexture(vec2 uv){
    vec3 backgroundColorTop = vec3(0.0353, 0.4653, 1.0);
    vec3 backgroundColorBottom = vec3(0.1294, 0.5961, 0.9333);

    vec3 color = vec3(0.0);
    // background
    color += mix(backgroundColorBottom, backgroundColorTop, uv.y);

    float cloud = fbm(vec3(uv * 3.0 + vec2(time), 9.0)) * 0.6;
    color += cloud;
    cloud = fbm(vec3(uv * 2.0 + vec2(time), 9.0)) * 0.3;
    color += cloud;
    cloud = fbm(vec3(uv * 2.0 + vec2(time), 9.0)) * 0.2;
    color += cloud;
    cloud = 1.0 - smoothstep(abs(fbm(vec3(uv * 2.0 + vec2(time, 0.0), 0.0))), 0.2, 0.1);
    color += cloud;
    cloud = 1.0 - smoothstep(abs(fbm(vec3(uv * 4.0 + vec2(time * 1.2, 0.0), 0.0))), 0.3, 0.1);
    color += cloud;
    cloud = 1.0 - smoothstep(abs(fbm(vec3(uv * 3.0 + vec2(time, 0.0), 0.0))), 0.4, 0.1);
    color += cloud;

    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution)/min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);
    vec3 camPos = vec3(0.0, 3.0, -4.0);
    vec3 lookPos = vec3(0.0, 1.5, 0.0);
    vec3 forward = normalize(lookPos - camPos);
    vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), forward));
    vec3 up = normalize(cross(forward, right));
    float fov = 1.0;
    vec3 rayDir = normalize(uv.x * right + uv.y * up + forward * fov);

    vec3 lightPos = vec3(1.0, 3.0, -1.5);

    float d = 0.0;
    float df;
    vec3 p;
    vec3 color1 = vec3(0.0);
    for(int i = 0; i < 100; i++){
        p = camPos + rayDir * d;
        df = distancePlane(p);
        if(df <= 0.001){
            color1 += skyTexture(p.xz * 0.3);
            break;
        }
        if(df > 100.0){
            break;
        }
        d += df * float(i) / 110.0;
    }

    d = 0.0;
    df = 0.0;
    p = vec3(0.0);
    vec3 color2 = vec3(0.0);
    for(int i = 0; i < 100; i++){
        p = camPos + rayDir * d;
        df = distanceFunction(p);
        if(df <= 0.001){
            color2 += skyTexture(p.xy * 0.02) * 0.7;
            break;
        }
        if(df > 100.0){
            break;
        }
        d += df;
    }
    color = max(color1, color2);

    glFragColor = vec4(color, 1.0);
}
