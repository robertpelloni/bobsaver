#version 420

// @machine_shaman
//modified by jiaotangsheng at 2019/04/10 19:07 

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// tetrahedron
//

#define rot(a) mat2(cos(a + vec4(0, 33, 11, 0)))

float plane(vec3 p, vec3 o, vec3 n) {
    return dot(p - o, n);
}

float tetrahedron(vec3 p, float s) {

    float k = .57735026919;
    
    float a = plane(p, vec3(s, s, s), vec3(-k, k, k));
    float b = plane(p, vec3(s, -s, -s), vec3(k, -k, k));
    float c = plane(p, vec3(-s, s, -s), vec3(k, k, -k));
    float d = plane(p, vec3(-s, -s, s), vec3(-k, -k, -k));
    
    // return max(a, b);
    return max(max(a, b), max(c, d));

}

float map(vec3 p) {
    p.xy *= rot(time);
    p.xz *= rot(time);
    return tetrahedron(p, .5);
    
}

vec3 normal(vec3 p) {
    float eps = .001;
    return normalize(vec3(
        map(vec3(p.x + eps, p.y, p.z)) - map(vec3(p.x - eps, p.y, p.z)),
        map(vec3(p.x, p.y + eps, p.z)) - map(vec3(p.x, p.y - eps, p.z)),
        map(vec3(p.x, p.y, p.z + eps)) - map(vec3(p.x, p.y, p.z - eps))
    ));
}

void main() {
    
    
    vec2 uv = (2. * gl_FragCoord.xy - resolution) / min(resolution.x,resolution.y);
    
    vec3 col = vec3(0.);
    vec3 ro = vec3(uv, -2);
    vec3 rd = vec3(0,0, 1);
    
    float t = 0.;
    for (int i = 0; i < 45; i++) {
        vec3 p = ro + rd * t;
        float d = map(p);
        t += .5 * d;
        col += .03 / t;
    }
    
    vec3 p = ro + rd * t;
    vec3 N = normal(p);
    vec3 L = vec3(0, 2, -6);
    
    vec3 ld = normalize(L - p);
    float diff = max(dot(ld, N), 0.);
    
    
    col += diff / (1. + t * t * .025);
    col = .5 + .5 * cos(time + col * 4. + vec3(23, 21, 0));
    
    glFragColor = vec4(col, 1.);
}
