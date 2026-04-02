#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float random(vec3 p) {
    return fract(sin(dot(p, vec3(34.4264, 12.5919, 43.3243))) * 43532.5343);
}

float noise(vec3 p) {
    vec3 i = floor(p);
    vec3 fl = fract(p);
    
    vec3 u = smoothstep(0.0, 1.0, fl);
    
    float a = random(i + vec3(0.0, 0.0, 0.0));
    float b = random(i + vec3(1.0, 0.0, 0.0));
    float c = random(i + vec3(0.0, 1.0, 0.0));
    float d = random(i + vec3(1.0, 1.0, 0.0));
    float e = random(i + vec3(0.0, 0.0, 1.0));
    float f = random(i + vec3(1.0, 0.0, 1.0));
    float g = random(i + vec3(0.0, 1.0, 1.0));
    float h = random(i + vec3(1.0, 1.0, 1.0));
    
    return mix(mix(mix(a, b, u.x), mix(c, d, u.x), u.y), mix(mix(e, f, u.x), mix(g, h, u.x), u.y), u.z);
}

#define FBM_OCTAVES 5

float fbm(vec3 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(cos(0.5), sin(0.5), sin(0.5), -cos(0.5));
    for (int i = 0; i < FBM_OCTAVES; i++) {
        v += a * noise(p);
        p *= 2.0;
        p += 100.0;
        p.xy *= rot;
        p.yz *= rot;
        a *= 0.5;
    }    
    return v;
}

mat3 camera(vec3 ro, vec3 ta, vec3 up) {
    vec3 cz = normalize(ta - ro);
    vec3 cx = cross(cz, normalize(up));
    vec3 cy = cross(cx, cz);

    return mat3(cx, cy, cz);
}

float scene(vec3 p) {
    return smoothstep(0.7, 1.0, pow(fbm(p * 0.1), 0.5));
}

void main( void ) {

    vec2 p = (-resolution + 2.0 * gl_FragCoord.xy) / resolution;

    vec3 ro = vec3(mouse.yx, -5.0 + time* 2.0);
    vec3 ta = vec3(mouse.yx, 2.0 + time* 2.0);
    
    vec3 rd =  normalize(vec3(p.xy, 1.0));

    
    float t = 0.0;
    vec4 sum = vec4(0.0);
    for (float t = 0.0; t < 100.0; t += 5.0) {
        vec3 p = ro + t * rd;
        float v = scene(p);
        vec3 c = mix(vec3(0.8, 0.7, 0.7), vec3(1.0), v);
        float a = (1.0 - sum.a) * v;
        sum += vec4(c * a, a);
    }
    
    vec3 back = mix(vec3(0.9, 0.9, 0.7), vec3(0.6, 0.8, 1.0), rd.y * 0.5 + 0.5);
    
    vec3 col = mix(back, sum.rgb, sum.a);
    
    glFragColor = vec4(col, 1.0);
}
