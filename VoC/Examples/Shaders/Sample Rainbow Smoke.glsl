#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/3tBGRG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define UI0 1597334673U
#define UI1 3812015801U
#define UI2 uvec2(UI0, UI1)
#define UI3 uvec3(UI0, UI1, 2798796415U)
#define UIF (1.0 / float(0xffffffffU))

// Hash Without Sine 2 https://www.shadertoy.com/view/XdGfRR
float hash13(in uvec3 q) {
    q *= UI3;
    uint n = (q.x ^ q.y ^ q.z) * UI0;
    return float(n) * UIF;
}
float hash13(in vec3 p) {
    return hash13(uvec3(ivec3(p)) * UI3);
}

vec3 hash33(in uvec3 q) {
    q *= UI3;
    q = (q.x ^ q.y ^ q.z)*UI3;
    return vec3(q) * UIF;
}

vec3 hash33(vec3 p) {
    return hash33(uvec3(ivec3(p)));
}

float noise(in vec3 p) {
    vec3 vf = floor(p);
    uvec3 i = uvec3(ivec3(vf));
    vec3 f = p - vf;
    vec3 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(dot(hash33(i + uvec3(0,0,0)), f - vec3(0.0,0.0,0.0)),
                       dot(hash33(i + uvec3(1,0,0)), f - vec3(1.0,0.0,0.0)), u.x),
                   mix(dot(hash33(i + uvec3(0,1,0)), f - vec3(0.0,1.0,0.0)),
                       dot(hash33(i + uvec3(1,1,0)), f - vec3(1.0,1.0,0.0)), u.x), u.y),
                  mix(mix(dot(hash33(i + uvec3(0,0,1)), f - vec3(0.0,0.0,1.0)),
                          dot(hash33(i + uvec3(1,0,1)), f - vec3(1.0,0.0,1.0)), u.x),
                      mix(dot(hash33(i + uvec3(0,1,1)), f - vec3(0.0,1.0,1.0)),
                       dot(hash33(i + uvec3(1,1,1)), f - vec3(1.0,1.0,1.0)), u.x), u.y), u.z);
}

const mat3 noisemat1 = mat3(
    -0.45579627,  0.75217353,  0.47590413,
     0.03119306, -0.5208463 ,  0.85308038,
    -0.88953738, -0.40367575, -0.21393721);
const mat3 noisemat2 = mat3(
     0.89766414,  0.22826049, -0.37695654,
    -0.03212991,  0.88702091,  0.46061001,
     0.4395074 , -0.40136151,  0.80358085);

vec3 noise3(in vec3 p) {
    return vec3(noise(p), noise(noisemat1 * p), noise(noisemat2 * p));
}

float fogdensity(in vec3 pos, float r, vec2 sc) {
    vec3 offset = noise3(1.2 * pos + vec3(8.0, sc));
    offset += 0.5 * noise3(2.0 * pos + vec3(-8.0, sc));
    float a = r - 5.0;
    return clamp(3.0 * noise(pos * 0.6 + offset) - 0.2 - 0.2 * a * a, 0.0, 1.0);
}

vec4 fog(in vec3 pos, vec2 sc) {
    float r = length(pos);
    float density = fogdensity(pos, r, sc);
    if (density < 0.001) {
        return vec4(0.0);
    }
    vec3 lightdir = normalize(vec3(0.0, 0.0, 4.0) - pos);
    vec3 pos2 = pos + 0.1 * lightdir;
    float density2 = fogdensity(pos2, length(pos2), sc);
    float occlusion = 1.0 - density2 * 2.0;
    vec3 color = abs(pos);
    color = smoothstep(
        min(min(color.r, color.g), color.b),
        max(max(color.r, color.g), color.b),
        color);
    return vec4(color * density * occlusion, density);
}

vec4 render(in vec3 origin, in vec3 dir, float jitter) {
    vec2 sc = vec2(sin(time * 0.5), cos(time * 0.5));
    vec4 color = vec4(0.0);
    for (int i = 0; i < 40; i++) {
        float t = (float(i) + jitter) * 0.2;
        vec3 pos = origin + t * dir;
        vec4 fcolor = fog(pos, sc);
        color += fcolor * (1.0 - color.a);
    }
    return color;
}

void main(void) {
    vec2 uv = (2.0 * gl_FragCoord.xy - resolution.xy) / resolution.y;
    uv *= 0.6;

    float s = sin(time), c = cos(time);
    vec3 pos = vec3(s, -c, 0.0) * 4.0;
    mat3 rot = mat3(c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0);
    vec3 dir = vec3(-s, c, 0.0);
    
    float jitter = hash13(vec3(gl_FragCoord.xy, time * 60.0));
    glFragColor = render(pos, rot * normalize(vec3(1.0, -uv.x, uv.y + sin(time * 0.4))), jitter);
}
