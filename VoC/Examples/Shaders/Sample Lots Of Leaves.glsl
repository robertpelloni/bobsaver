#version 420

// original https://www.shadertoy.com/view/cd3SzS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define R (resolution.xy)
#define T (time)
mat2 rot(in float a) { float c = cos(a); float s = sin(a); return mat2(c, s, -s, c); }

uint hash21u(in vec2 ip, in float seed) {
    uvec2 p = uvec2(floatBitsToUint(ip.x), floatBitsToUint(ip.y));
    uint s = floatBitsToUint(seed);
    s ^= ~s >> 3U;
    p ^= (p << 17U);
    s ^= (~p.x);
    s ^= (~p.y);
    p ^= (p >> 11U);
    p ^= (p << 5U);
    p ^= (s << 3U);
    return ((p.x + p.y) ^ (p.x * s + p.y))*293U;
}

float hash21(in vec2 ip, in float seed) { return float(hash21u(ip, seed)) / float(0xFFFFFFFFU); }
vec3 hash23(in vec2 ip, in float seed) {
    uint n = hash21u(ip, seed);
    n ^= (n >> 13U);
    return vec3(float((n >> 16U) & 0xFFU), float((n >> 8U) & 0xFFU), float(n & 0xFFU)) / float(0xFFU);
}

float line(in vec2 p, in vec2 a, in vec2 b, in float t) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return clamp(01.0-length(pa - ba * h)/t, 0.0, 1.0);
}

vec3 leaf(in vec2 uv, in vec2 id, in float ra) {
    float ra0 = fract(((ra-id.x)*44.4929811)+id.y*3.3921);
    if (floor(ra0+ra+0.1) <= 0.) return vec3(0.); // randomly discard some leaves
    float v = 0.0;
    float len = 0.9;
    float s = smoothstep(len/2., 0.0, abs(uv.y))*smoothstep(len/3., 0.1, -uv.y+0.01);
    vec2 start = vec2(0,-len/2.);
    vec2 end = vec2(0, len/2.);
    start.x += 0.1*s;
    end.x += 0.1*s;
    v += line(abs(uv), start, end, 0.01);
    v += smoothstep(0.0, 0.01, dot(vec2(abs(uv.x)-(0.1*s), uv.y), (start-end).yx));
    vec3 col = vec3(0.3, 0.33, 0.1);
    col = mix(col, vec3(0.9, 0.9, 0.5), s*s*s);
    vec3 c1 = vec3(0.3, 0.33, 0.2);
    vec3 c2 = vec3(0.8, 0.8, 0.3);
    vec3 c3 = vec3(0.2, 0.5, 0.04);
    vec3 c4 = vec3(0.0, 0.4, 0.02);
    vec3 n = hash23(id, ra);
    vec3 a = mix(c1, c2, n.x);
    vec3 b = mix(c3, c4, n.y);
    vec3 c = mix(a, b, n.z);
    col = mix(col, c, ra*ra);
    float ra2 = fract((ra*10.98938281)+(id.x*3.392912+id.y));
    col = mix(col, (col*c3)+(c2*c3*s), ra2*ra2*0.39);
    return col*v;
}

vec3 leafs(in vec2 uv, in float iseed) {
    vec3 col = vec3(0.0);
    float tile = 4.0;
    float seed = 3.329291 + iseed;
    float div = 1.0;
    for (int i = 0; i < 24; i++) {
        vec2 id = floor(uv*tile);
        vec2 lv = fract(uv*tile);
        vec2 slv = lv*lv*(3.0-2.0*lv);
        float n = hash21(id, seed);
        float n2 = hash21(id, seed+id.x+id.y+0.329812);
        lv = fract(uv*tile);
        lv = (0.5-lv)*rot(n*6.28);
        col = max(col, leaf(lv, id, fract((n+n2+id.x+id.y)*10.4992))/div);
        seed += 13.937272;
        tile += 1.;
        uv *= mat2(6.28, 8.0, -6.28, 8.)*0.1;
        div += 0.2;
    }
    return col / (1.0 + max(col-0.56, 0.0));
}

void main(void)
{
    vec3 col = vec3(0.0);
    vec2 uv = (gl_FragCoord.xy-0.5*R.xy)/R.y;
    float s = 1.0;
    float uvs = 0.3;
    vec2 shift = vec2(0.0);
    float seed = 0.039291;
    float mag = 1.0;
    for (int i = 0; i < 6; i++)
    {
        vec2 uv = (uv)+shift;
        uv *= 0.5 + (0.5+sin(T)*0.5)*s;
        uv += vec2(cos(T*0.15), sin(T*0.15))*s;
        col += leafs(uv*uvs, seed)*smoothstep(0.45, 0., length(col)*2.3)*mag;
        s -= 0.15;
        s *= s;
        uvs *= 1.7;
        shift += 0.02;
        seed += 2.1231237;
        mag /= 1.2;
    }
    glFragColor = vec4(col, 1.0);
}
