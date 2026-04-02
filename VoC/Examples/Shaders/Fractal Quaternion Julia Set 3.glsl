#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float getTime() {
    return time;
}

vec4 qmult(vec4 a, vec4 b) {
    vec4 r;
    r.x = a.x * b.x - dot(a.yzw, b.yzw);
    r.yzw = a.x * b.yzw + b.x * a.yzw + cross(a.yzw, b.yzw);
    return r;
}

void julia(inout vec4 z, inout vec4 dz, in vec4 c) {
    for(int i = 0; i < 100; i++) {
        dz = 2.0 * qmult(dz, z);
        z = qmult(z, z) + c;
        
        if(dot(z, z) > 3.0) {
            break;
        }
    }
}

vec3 transform(vec3 p) {
    float t = getTime();
    p.xy *= mat2(cos(t), sin(t), -sin(t), cos(t));
    t = time;
    p.zx *= mat2(cos(t), sin(t), -sin(t), cos(t));
    return p;
}

float dist(in vec3 p) {
    p = transform(p);
    vec4 z = vec4(p, 0.0);
    vec4 dz = vec4(1.0, 0.0, 0.0, 0.0);
    
    float t = getTime();
    vec2 m = vec2(0.5 + 0.25 * cos(t), 0.6 + sin(t*2.) * .25) * 2.0 - 1.0;
    vec4 c = vec4(m.x, m.y, 0.0, 0.0);
        
    julia(z, dz, c);
        
    float lz = length(z);
    float d = 0.5 * log(lz) * lz / length(dz) ; 
    
    return d;
}

float rand(vec2 n) {
    return fract(cos(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 n) {
    const vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n), f = smoothstep(vec2(0.0), vec2(1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float fbm(vec2 n) {
    float total = 0.0, amplitude = 2.0;
    for (int i = 0; i < 18; i++) {
        total += (noise(n) * amplitude);
        n += n;
        amplitude *= atan(0.4345);
    }
    return total;
}

vec4 getColor() {
    const vec3 c1 = vec3(26.0/255.0, 111.0/255.0, 97.0/255.0);
    const vec3 c2 = vec3(73.0/255.0, 64.0/255.0, 181.4/255.0);
    const vec3 c3 = vec3(0.9, 0., 0.0);
    const vec3 c4 = vec3(64.0/255.0, 1.0/255.0, 114.4/255.0);
    const vec3 c5 = vec3(0.1);
    const vec3 c6 = vec3(0.3, 0.4, 0.2);
    
    vec2 p = abs(gl_FragCoord.xy) * 5.0 / (resolution.xx);
    float t = getTime();
    float q =abs(exp2(fbm(p - sin(t) * 0.08)));
    vec2 r = abs(vec2(fbm(p + q + cos(t) * 0.125 - p.x - p.y), fbm(p + q - cos(t) * 1.0)));
    vec3 c = mix(c1, c2, fbm(p + r)) + mix(c3, c4, r.x) - mix(c5, c6, r.y);  
    return abs(vec4((c )* sqrt(1.), 1.0));
}

void main( void ) {

    vec2 st = (gl_FragCoord.xy * 2.0 - resolution) / resolution.y;
    
    vec3 ori = vec3(0.0, 0.0, 2.0);
    vec3 tar = vec3(0.0, 0.0, 0.0);
    vec3 cz = normalize(tar - ori);
    vec3 cx = cross(cz, vec3(0.0, 1.0, 0.0));
    vec3 cy = cross(cx, cz);
    vec3 dir = normalize(cx * st.x + cy * st.y + cz * 1.0);
    
    float t = 0.0;
    int steps = 0;
    for (int i = 0; i < 1024; i++) {
        steps = i;
        float d = dist( ori + t * dir);
        if (d < 0.0005 || t > 200.0) break;
        t += d;
    }
    
    vec3 c = vec3(1.0);
    if (t < 10.0) {
        c = vec3(vec3(1.0 - float(steps) / 64.0 / getColor()));
    }
        
    glFragColor = vec4(c, 1.0);
}
