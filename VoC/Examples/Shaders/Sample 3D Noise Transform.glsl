#version 420

// original https://www.shadertoy.com/view/lsSBDy

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 colormap(float x) {
    float r = clamp(8.0 / 3.0 * x, 0.0, 1.0);
    float g = clamp(8.0 / 3.0 * x - 1.0, 0.0, 1.0);
    float b = clamp(4.0 * x - 3.0, 0.0, 1.0);
    return vec4(r, g, b, 1.0);
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

float fbm(vec3 p) {
    float r = 0.0;
    float amp = 1.0;
    float freq = 1.0;
    for(int i = 1; i <= 3; i++) {
        r += amp * noise(freq * p);
        freq *= pow(2.0, float(i));
        amp *= pow(2.0, -float(i));
    }
    return r;
}

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}
float udBox( vec3 p, vec3 b )
{
  return length(max(abs(p)-b,0.0));
}
float sdPlane(vec3 p, vec4 n) {
    return dot(p, n.xyz) + n.w;
}
float DF(vec3 p) {
    float d = sdPlane(p, vec4(0, 1, 0, 1));
    float r = fbm(p + vec3(time) + fbm(4.0*p + fbm(4.0*p + vec3(0, time, 0))));
    return max(sdSphere(p, 1.0), r - 0.9);
}

struct Ray {
    bool hit;
    vec3 hitPos;
    vec3 hitNormal;
    int steps;
    float t;
};
const int maxSteps = 30;
Ray trace(vec3 from, vec3 rayDir) {
    bool hit = false;
    vec3 hitPos = vec3(0);
    vec3 hitNormal = vec3(0);
    int steps = 0;
    float t = 0.0;
    for(int i = 0; i < maxSteps; i++) {
        vec3 p = from + t*rayDir;
        float d = DF(p);
        if(d < 0.001) {
            hit = true;
            hitPos = p;
            hitNormal = vec3(0);
            steps = i;
            break;
        }
        t += d;
    }
    return Ray(hit, hitPos, hitNormal, steps, t);
}

void main(void)
{
    vec2 uv = (2.0*gl_FragCoord.xy - resolution.xy)/resolution.y;
    
    vec3 camPos = vec3(0, 0, -2);
    vec3 camFront = vec3(0, 0, 1);
    vec3 camRight = cross(vec3(0, 1, 0), camFront);
    vec3 camUp = cross(camRight, camFront);
    vec3 rayDir = normalize(camFront + uv.x*camRight + uv.y*camUp);
    
    Ray tr = trace(camPos, rayDir);
    vec3 color = vec3(0);
    if(tr.hit) {
        float sAO = 1.0 - float(tr.steps)/float(maxSteps);
        color = sAO * colormap(sAO).xyz;
    }
    
    glFragColor = vec4(color, 1.0);
}
