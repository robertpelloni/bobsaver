#version 420

// original https://www.shadertoy.com/view/MsSBWV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
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
float fbm(vec3 p) {
    float r = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    for(int i = 0; i < 8; i++) {
        r += amp * noise(freq*p);
        amp *= 0.5;
        freq *= 2.0;
    }
    return r;
}

float sdPlane(vec3 p, vec4 n) {
    return dot(p, n.xyz) + n.w;
}

float DF(vec3 p) {
    float d = sdPlane(p, vec4(0, 1, 0, 1));
    return d - fbm(vec3(p.x, 0, p.z));
}

vec3 calcNormal(vec3 p) {
    float eps = 0.001;
    return normalize(vec3(
        DF(p + vec3(eps, 0, 0)) - DF(p + vec3(-eps, 0, 0)),
        DF(p + vec3(0, eps, 0)) - DF(p + vec3(0, -eps, 0)),
        DF(p + vec3(0, 0, eps)) - DF(p + vec3(0, 0, -eps))
    ));
}

struct Ray {
    bool hit;
    vec3 hitPos;
    vec3 hitNormal;
    int steps;
    float t;
};
const int maxSteps = 200;
Ray trace(vec3 from, vec3 rayDir) {
    bool hit = false;
    vec3 hitPos = vec3(0);
    vec3 hitNormal = vec3(0);
    int steps = 0;
    float t = 0.1;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = from + t*rayDir;
        float d = DF(p);
        if(d < 0.001) {
            hit = true;
            hitPos = p;
            hitNormal = calcNormal(p);
            steps = i;
            break;
        }
        t += 0.3*d;
    }
    return Ray(hit, hitPos, hitNormal, steps, t);
}

const vec3 sunDir = normalize(vec3(0, 1, 0.5));
vec3 sky(vec3 rayDir) {
    vec3 sun = pow(max(dot(rayDir, sunDir), 0.0), 12.0) * vec3(1, 0.8, 0.3);
    float theta = atan(rayDir.y/length(vec2(rayDir.x, rayDir.z)));
    float skyfactor = (pow(sin(theta+ 0.1), 0.5) + 0.1);
    vec3 sky = skyfactor*vec3(0.6, 0.8, 0.9) + (1.0 - skyfactor)*vec3(1);
    return sky + sun;
}

float softShadow(vec3 hitPos, vec3 lightPos, float k) {
    vec3 lightDir = normalize(lightPos - hitPos);
    float ss = 1.0;
    float t = 0.1;
    for(int i = 0; i < 30; i++) {
        vec3 p = hitPos + t*lightDir;
        float d = DF(p);
        if(d < 0.001) {
            return 0.0;
        }
        ss = min(ss, k * d/t);
        t += d;
    }
    return ss;
}
float hardShadow(vec3 hitPos, vec3 lightPos) {
    Ray tr = trace(hitPos, normalize(lightPos - hitPos));
    if(tr.hit) {
        return 0.0;
    }
    else {
        return 1.0;
    }
}

float detailedAO(vec3 hitPos, vec3 hitNormal, float k) {
    float ao = 0.0;
    for(int i = 1; i <= 5; i++) {
        float d1 = float(i)/float(5) * k;
        vec3 p = hitPos + d1*hitNormal;
        ao += 1.0/pow(float(i), 2.0) * (d1 - DF(p));
    }
    return 1.0 - clamp(ao, 0.0, 1.0);
}

void main(void) {
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    vec3 camPos = vec3(3.0*cos(0.5*time), 0, time);
    camPos += vec3(0, noise(camPos), 0);
    vec3 camFront = normalize(vec3(0.2*cos(0.5*time), 0, 1));
    vec3 camRight = cross(camFront, vec3(0, 1, 0));
    vec3 camUp = cross(camRight, camFront);
    vec3 rayDir = normalize(camFront + uv.x*camRight + uv.y*camUp);
    
    vec3 color = vec3(0);
    Ray tr = trace(camPos, rayDir);
    if(tr.hit) {
        //float sAO = 1.0 - float(tr.steps)/float(maxSteps);
        float dAO = detailedAO(tr.hitPos, tr.hitNormal, 1.0);
        float ss = softShadow(tr.hitPos, tr.hitPos + sunDir, 1.0);
        //float hs = hardShadow(tr.hitPos, tr.hitPos + sunDir);
        float diffuse = max(dot(tr.hitNormal, sunDir), 0.0);
        float fog = exp(-0.1*tr.t);
        
        vec3 mat = vec3(0.5 + tr.hitPos.y, 0.7, 0);
        color = fog * (ss * diffuse * mat + 0.3*dAO*mat*vec3(0.6, 0.8, 0.9)) + (1.0 - fog)*vec3(1);
    }
    else {
        color = sky(rayDir);
    }
    
    glFragColor = vec4(color, 1.0);
}
