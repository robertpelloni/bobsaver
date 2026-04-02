#version 420

// original https://www.shadertoy.com/view/MsBBWK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float rand(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}
float noise(vec2 p){
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u*u*(3.0-2.0*u);
    
    float res = mix(
        mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
        mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
    return res*res;
}
float fbm2(vec2 p) {
    float r = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    for(int i = 0; i < 5; i++) {
        r += amp * noise(freq*p);
        amp *= 0.5;
        freq *= 2.0;
    }
    return r;
}

float mod289(float x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 mod289(vec4 x){return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec4 perm(vec4 x){return mod289(((x * 34.0) + 1.0) * x);}
float noise(vec3 p){
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}
float fbm3(vec3 p) {
    float r = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    for(int i = 0; i < 5; i++) {
        r += amp * noise(freq*p);
        amp *= 0.5;
        freq *= 2.0;
    }
    return r;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}
float sdPlane(vec3 p, vec4 n) {
    return dot(p, n.xyz) + n.w;
}

vec2 dmin(vec2 d1, vec2 d2) {
    if(d1.x < d2.x) {
        return d1;
    }
    else {
        return d2;
    }
}

vec2 DF(vec3 p) {
    vec3 q = p;
    q.xz = mod(q.xz, 4.0) - 2.0;
    vec2 s1 = vec2(sdSphere(q, 1.0), 1);
    vec2 s2 = vec2(sdPlane(p, vec4(0, 1, 0, 1)), 2);
    return dmin(s1, s2);
}

vec3 calcNormal(vec3 p) {
    float eps = 0.001;
    return normalize(vec3(
        DF(p + vec3(eps, 0, 0)).x - DF(p + vec3(-eps, 0, 0)).x,
        DF(p + vec3(0, eps, 0)).x - DF(p + vec3(0, -eps, 0)).x,
        DF(p + vec3(0, 0, eps)).x - DF(p + vec3(0, 0, -eps)).x
    ));
}

struct Ray {
    bool hit;
    vec3 hitPos;
    vec3 hitNormal;
    int steps;
    float t;
    int hitObj;
};
const int maxSteps = 100;
Ray trace(vec3 from, vec3 rayDir) {
    bool hit = false;
    vec3 hitPos = vec3(0);
    vec3 hitNormal = vec3(0);
    int steps = 0;
    float t = 0.0;
    int hitObj = 0;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = from + t*rayDir;
        float d = DF(p).x;
        if(d < 0.001) {
            hit = true;
            hitPos = p;
            hitNormal = calcNormal(p);
            steps = i;
            hitObj = int(DF(p).y);
            break;
        }
        t += d;
    }
    return Ray(hit, hitPos, hitNormal, steps, t, hitObj);
}

float detailedAO(vec3 hitPos, vec3 hitNormal, float k) {
    float ao = 0.0;
    for(int i = 1; i <= 5; i++) {
        float d1 = float(i)/float(5) * k;
        vec3 p = hitPos + d1*hitNormal;
        ao += 1.0/pow(2.0, float(i)) * (d1 - DF(p).x);
    }
    return 1.0 - clamp(ao, 0.0, 1.0);
}

float softShadow(vec3 hitPos, vec3 lightPos, float k) {
    vec3 lightDir = normalize(lightPos - hitPos);
    float ss = 1.0;
    float t = 0.1;
    for(int i = 0; i < 100; i++) {
        vec3 p = hitPos + lightDir*t;
        float d = DF(p).x;
        if(d < 0.001) {
            return 0.0;
        }
        ss = min(ss, k * d/t);
        t += d;
    }
    return ss;
}

vec3 phong(vec3 hitPos, vec3 hitNormal, vec3 rayDir, vec3 lightPos, vec3 dc, vec3 sc) {
    vec3 lightDir = normalize(lightPos - hitPos);
    float diffuse = max(dot(lightDir, hitNormal), 0.0);
    float specular = pow(max(dot(reflect(-lightDir, hitNormal), -rayDir), 0.0), 8.0);
    return 0.5*diffuse*dc + 0.5*specular*sc;
}

vec3 marble(float u, float v) {
    vec2 p = vec2(u, v);
    vec2 q = vec2(0);
    vec2 r = vec2(0);
    q.x = fbm2(p + vec2(1, 1));
    q.y = fbm2(p + vec2(2, 2));
    r.x = fbm2(p + 2.0*q + vec2(1, 1));
    r.y = fbm2(p + 2.0*q + vec2(2, 2));
    return fbm2(p + 4.0*r) * vec3(0, q.x + r.x, q.y + r.y);
}
vec3 checkerboard(float u, float v, float interval) {
    u = floor(u/interval*2.0);
    v = floor(v/interval*2.0);
    float p = mod(u + v, 2.0);
    return vec3(0.1 + 0.9*p);
}

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    float t = 0.4*time;
    vec3 camPos = 3.0 * vec3(sin(t), 0.5, cos(t));
    vec3 camFront = -normalize(camPos);
    vec3 camRight = cross(camFront, vec3(0, 1, 0));
    vec3 camUp = cross(camRight, camFront);
    vec3 rayDir = normalize(1.5*camFront + uv.x*camRight + uv.y*camUp);
    
    vec3 lightPos = vec3(2, 5, 0);
    
    Ray tr = trace(camPos, rayDir);
    vec3 color = vec3(0);
    if(tr.hit) {
        float sAO = 1.0 - float(tr.steps)/float(maxSteps);
        float dAO = detailedAO(tr.hitPos, tr.hitNormal, 1.2);
        float fog = exp(-0.2*tr.t);
        
        float ss = softShadow(tr.hitPos, lightPos, 12.0);
        
        vec3 mat = vec3(1);
        vec3 brdf = vec3(1);
        if(tr.hitObj == 1) {
            float u = atan(tr.hitNormal.y, length(tr.hitNormal.xz)) + 3.14;
            float v = atan(tr.hitNormal.z, tr.hitNormal.x) + 3.14;
            mat = marble(u, v);
            brdf = phong(tr.hitPos, tr.hitNormal, rayDir, lightPos, mat, vec3(1));
        }
        else if(tr.hitObj == 2) {
            mat = checkerboard(tr.hitPos.x, tr.hitPos.z, 1.0);
            brdf = phong(tr.hitPos, tr.hitNormal, rayDir, lightPos, mat, vec3(1));
        }
        
        float geo = 100.0/pow(distance(tr.hitPos, lightPos), 2.0);
        
        color = 0.7 * ss * geo * brdf + 0.3*dAO*mat;
        color *= fog;
    }
    
    glFragColor = vec4(color, 1.0);
}
