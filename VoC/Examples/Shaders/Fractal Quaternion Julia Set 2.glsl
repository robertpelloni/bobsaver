#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 qmult(vec4 a, vec4 b) {
    vec4 r;
    r.x = a.x * b.x - dot(a.yzw, b.yzw);
    r.yzw = a.x * b.yzw + b.x * a.yzw + cross(a.yzw, b.yzw);
    return r;
}

void julia(inout vec4 z, inout vec4 dz, in vec4 c) {
    for(int i = 0; i < 10; i++) {
        dz = 2.0 * qmult(z, dz);
        z = qmult(z, z) + c;
        
        if(dot(z, z) > 3.0) {
            break;
        }
    }
}

vec3 transform(vec3 p) {
    float t = time * 1.3;
    p.xy *= mat2(cos(t), sin(t), -sin(t), cos(t));
    t = time * 1.7;
    p.zx *= mat2(cos(t), sin(t), -sin(t), cos(t));
    return p;
}

float dist(in vec3 p) {
    p = transform(p);
    vec4 z = vec4(p, 0.0);
    vec4 dz = vec4(1.0, 0.0, 0.0, 0.0);
    
    vec2 m = mouse * 2.0 - 1.0;
    vec4 c = vec4(m.x, m.y, 0.0, 0.0);
        
    julia(z, dz, c);
        
    float lz = length(z);
    float d = 0.5 * log(lz) * lz / length(dz) ; 
    
    return d;
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
    for (int i = 0; i < 128; i++) {
        steps = i;
        vec3 p = ori + t * dir;
        float d = dist(p);
        if (d < 0.001 || t > 10.0) break;
        t += d;
    }
    
    vec3 c = vec3(1.0);
    if (t < 10.0) {
        c = vec3(vec3(1.0 - float(steps) / 64.0));
    }
    
    glFragColor = vec4(c, 1.0);
}
