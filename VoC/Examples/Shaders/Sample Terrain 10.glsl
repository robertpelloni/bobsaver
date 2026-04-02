#version 420

#define PI 3.141592

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int perlinMaxOctaves = 64;

float hash (float v) {
    return fract (cos (v) * 576854.321687);
}

float hash (vec2 p) {
    return fract (sin (dot (p, vec2 (-36.39912, 18.085192))) * 99315.38895);
}

float noise(vec2 p, float freq ){
    float unit = 1.0 / freq;
    vec2 ij = floor(p/unit);
    vec2 xy = mod(p,unit)/unit;
    xy = .5*(1.-cos(PI*xy));
    float a = hash(ij + vec2(0.,0.));
    float b = hash(ij + vec2(1.,0.));
    float c = hash(ij + vec2(0.,1.));
    float d = hash(ij + vec2(1.,1.));
    float x1 = mix(a, b, xy.x);
    float x2 = mix(c, d, xy.x);
    return mix(x1, x2, xy.y);
}

float perlin(vec2 p, int res){
    float persistance = .5;
    float n = 0.;
    float normK = 0.;
    float f = 4.;
    float amp = 1.;
    for (int i = 0; i < perlinMaxOctaves; i++){
        n += amp * noise(p, f);
        f *= 2.0;
        normK += amp;
        amp *= persistance;
        if (i >= res) break;
    }
    float nf = n / normK;
    return nf * nf * nf * nf;
}

float height (vec2 p) {
    return perlin (p, 8);
}

float map (vec3 p) {
    return p.y - height (p.xz);
}

vec3 normal (vec3 p) {
    return normalize (
        vec3 (
            map (vec3(p.x - 0.001, p.y, p.z)) - map (vec3(p.x + 0.001, p.y, p.z)),
            map (vec3(p.x, p.y - 0.001, p.z)) - map (vec3(p.x, p.y + 0.001, p.z)),
            map (vec3(p.x, p.y, p.z - 0.001)) - map (vec3(p.x, p.y, p.z + 0.001))
        )
    );
}

vec3 getRay(vec2 p, float fov, vec3 eye, vec3 target, vec3 up) {
    vec3 dir = normalize(eye - target);
    vec3 side = normalize(cross(up, dir));
    float z = - up.y / tan(radians(fov) * 0.5);
    return normalize(side * p.x + up * p.y + dir * z);
}

vec3 background (in vec3 rd) {
    return vec3 (0.77, 0.76, 0.72);
}

const float marchStep = 0.01;
const int marchIterations = 256;

vec3 march (in vec3 ro, in vec3 rd) {
    float total = 0.0;
    vec3 point = ro;
    bool hit = false;
    float lastH = 0.0;
    float lastY = 0.0;
    float dt = marchStep;
    float t = 0.0;
    float far = float(marchIterations) * dt;
    for (int i = 0; i < marchIterations; i++) {
        
        t = t + dt;
        point = ro + t * rd;
        float h = height (point.xz);
        if (point.y < h) {
            total = t - marchStep + marchStep * (lastH - lastY) / (point.y - lastY - h + lastH);
            hit = true;
            break;
        }
        lastH = h;
        lastY = point.y;
        
    }
    
    point = ro + total * rd;
    float fog = pow(total / far, 8.0 * (1.0 - point.y));
    vec3 bg = background (rd);
    
    if (hit) {
        vec3 color =  pow(vec3(point.y), vec3(4.0));
        return mix(color, bg, fog);
    } else {
        return bg;
    }
}

void main( void ) {

    vec2 uv = gl_FragCoord.xy / resolution.xy;
    vec3 ro = vec3 (0.0, 1.6, 0.0);
    vec3 dir = normalize (vec3 (0.0, -1.0, 0.6));
    ro = ro + time * vec3(dir.x, 0.0, dir.z) * 0.25;
    
    vec3 rd = getRay (uv * 2.0 - 1.0, 60.0, ro, ro + dir, vec3 (0.0, 1.0, 0.0));
    
    vec3 color = march (ro, rd);
    glFragColor = vec4 (color, 1.0);

}
