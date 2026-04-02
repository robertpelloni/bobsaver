#version 420

// original https://www.shadertoy.com/view/4dsyWB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float sdfPlane(in vec3 pos, in vec3 n) {
    return dot(pos, n);
}

float sdfSphere(in vec3 pos, in float radius) {
    return length(pos) - radius;   
}

float sdfUnion(in float a, in float b) {
    return min(a, b);   
}

float samp(in vec3 pos) {
     vec3 spos = vec3(mod(pos.x, .7f) - 0.35f, pos.y, mod(pos.z, 0.7f) - 0.35f);
    float sphere = sdfSphere(spos, 0.5f);
    return sphere;
}

vec3 march(in vec3 origin, in vec3 dir, in float maxlen) {
    float dist = 0.0f;
    vec3 pos = origin;
    vec3 d = dir;
    
    while (dist < maxlen) {
        float t = samp(pos);
        if (t < 0.001f) {
            float fx = samp(vec3(pos.x + 0.0001f, pos.y, pos.z)) - samp(vec3(pos.x - 0.0001f, pos.y, pos.z));
            float fy = samp(vec3(pos.x, pos.y + 0.0001f, pos.z)) - samp(vec3(pos.x, pos.y - 0.0001f, pos.z));
            float fz = samp(vec3(pos.x, pos.y, pos.z + 0.0001f)) - samp(vec3(pos.x, pos.y, pos.z - 0.0001f));
            vec3 normal = normalize(vec3(fx, fy, fz));
            if (dot(-d, normal) < 0.0f) normal = -normal;
            return vec3(max(normal.y, 0.4f));
        }
        
        d = normalize(d + vec3(0, -0.0025f, 0));
        
        dist += 0.01f;
        pos += 0.01f * d;
    }
    
    return vec3(0.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    float time = time;
    
    vec3 campos = vec3(-1.0f + time, 1.5f, -4.0f + time);
    vec3 dir = normalize(vec3(1.5f, 1.0f, 1.0f));
    vec3 side = normalize(cross(dir, vec3(0, 1, 0)));
    vec3 up = normalize(cross(side, dir));
    float fov = 128.0f / 180.0f * 3.141592;
       float ifov = 1.0f / tan(fov / 2.0f);
    vec2 ndc = vec2(uv.x * 2.0f - 1.0f, (uv.y * 2.0f - 1.0));
    ndc.y *= resolution.y / resolution.x;
    
    vec3 rdir = normalize(side * ndc.x + up * ndc.y + dir * ifov);
    
    vec3 c = march(campos, rdir, 50.0f);
    
    glFragColor = vec4(c,1.0);
}
