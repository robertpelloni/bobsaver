#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const vec3 lightDir = vec3(0.577, 0.577, -0.5777);

mat2 rot(float a) {
    float c = cos(a), s = sin(a);
    return mat2(c, s, -s, c);
}

const float pi = 3.141592653589793;
const float pi2 = pi * 2.;

vec2 pmod(vec2 p, float r) {
    float a = atan(p.x, p.y) + pi/r;
    float n = pi2 / r;
    a = floor(a/n) * n;
    return p * rot(-a);
}

float sdSphere(vec3 p, float r) {
    float d = length(p) - r;
    return d;
}

float sdPlane(vec3 p) {
    float d = p.y;
    return d;
}

float sdBox(vec3 p, float s) {
    p = abs(p) - s;
    return max(max(p.x,p.y),p.z);
}

float sdf(vec3 p) {
    p.xy = pmod(p.xy, 5.);
    for(int i=0;i<4;i++) {
        p = abs(p) - 1.;
        p.xz *= rot(0.4 * time);
        p.xy *= rot(0.6 + time);
    }
    p.xy = pmod(p.xy, 5.0);
    
    return sdBox(p, 0.4);
}

vec3 normal(vec3 p) {
    vec2 d = vec2(0.0001,0.);
    return normalize(vec3(
        sdf(p+d.xyy)-sdf(p),
        sdf(p+d.yxy)-sdf(p),
        sdf(p+d.yyx)-sdf(p)
    ));
}

vec3 hsv(float h, float s, float v){
    vec4 t = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(vec3(h) + t.xyz) * 6.0 - vec3(t.w));
    return v * mix(vec3(t.x), clamp(p - vec3(t.x), 0.0, 1.0), s);
}

void main( void ) {
    vec2 p = (gl_FragCoord.xy * 2. - resolution.xy) / min(resolution.x, resolution.y);
    
    
    vec3 cPos = vec3(0.,0.,-5.);
    vec3 cDir = vec3(0.,0.,1.);
    vec3 cUp= vec3(0.,1.,0.);
    vec3 cSide = cross(cDir, cUp);
    float screenZ = 1.;
    
    vec3 ray = normalize(cSide * p.x + cUp * p.y + cDir * screenZ);
    ray.z = sqrt(max(ray.z * ray.z - dot(ray.xy, ray.xy) * 0.8, 0.));
    
    float depth = 2.;
    float ac = 0.;
    vec3 col = vec3(0.);
    for(int i=0;i<64;i++) {
        vec3 rayPos = cPos + ray * depth;
        float dist = sdf(rayPos);
        
        if (dist < 0.0001) {
            vec3 normal = normal(rayPos);
            float diff = clamp(dot(lightDir, normal) * 0.5 + 0.5, 0.1, 1.0);
            col = vec3(diff) * hsv(depth / 10., 1., 1.);
            break;
        }
        depth += dist;
    }
    glFragColor = vec4(col, 1.0);
}
