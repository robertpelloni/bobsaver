#version 420

// original https://www.shadertoy.com/view/Xd2cDt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 rot(vec2 p, float a) {
    return vec2(
        p.x * cos(a) - p.y * sin(a),
        p.x * sin(a) + p.y * cos(a));
    
}

float map(vec3 p) {
    float tp0 = 4.0 - dot(abs(p), vec3(0,1,0));
    float tp1 = 4.0 - dot(abs(p), vec3(1,0,0));
    float ts = length(mod(p, 2.0) - 1.0) - 0.5;
    float tx = length(mod(p.yz, 2.0) - 1.0) - 0.3;
    float ty = length(mod(p.zx, 2.0) - 1.0) - 0.3;
    float tz = length(mod(p.xy, 2.0) - 1.0) - 0.3;
    float txs = length(mod(p.yz, 4.0) - 2.0) - 1.9;
    float tys = length(mod(p.zx, 4.0) - 2.0) - 1.9;
    float tzs = length(mod(p.xy, 4.0) - 2.0) - 1.9;
    float txp = length(mod(p.yz, 0.2) - 0.1) - 0.04;
    float typ = length(mod(p.zx, 0.2) - 0.1) - 0.04;
    float tzp = length(mod(p.xy, 0.2) - 0.1) - 0.04;
    float t = 10000.0;
    t = min(tp0, t);
    t = min(tp1, t);
    t = max(-tx, t);
    t = max(-ty, t);
    t = max(-tz, t);
    t = max(-txp, t);
    t = max(-typ, t);
    t = max(-tzp, t);
    t = max(-txs, t);
    t = max(-tys, t);
    t = max(-tzs, t);
    t = min(ts, t);
    t = max(-txp, t);
    t = max(-typ, t);
    t = max(-tzp, t);
    t = max(-tx, t);
    t = max(-ty, t);
    t = max(-tz, t);
    return t;
}

vec3 getnormal(vec3 p){
    float d = 0.001;
        return normalize(vec3(
        map(p + vec3(  d, 0.0, 0.0)) - map(p + vec3( -d, 0.0, 0.0)),
        map(p + vec3(0.0,   d, 0.0)) - map(p + vec3(0.0,  -d, 0.0)),
        map(p + vec3(0.0, 0.0,   d)) - map(p + vec3(0.0, 0.0,  -d))
    ));
}

vec4 getcolor(vec2 uv, float z) {
    uv.x += z;
    float rad = 0.3;
    
    vec3 dir = normalize(vec3(uv, 1.0));
    vec3 pos = vec3(rad, rad, time * 3.0 + sin(time) * 2.0);
    pos.xy = rot(pos.xy, time * 0.5);
    dir.xz = rot(dir.xz, time * 0.2);
    dir.yz = rot(dir.yz, time * 0.1);
    
    float t = 0.0;
    for(int i = 0; i < 75; i++) {
        float temp = map(dir * t + pos);
        if(temp < 0.01) break;
        t += temp;
    }
    vec3 ip = dir * t + pos;
    vec3 V = normalize(-ip);
    vec3 N = getnormal(ip);
    vec3 L = normalize(vec3(3,4,-1));
    vec3 H = normalize(L + V);
    float Kd = max(dot(L, N), 0.0);
    float Ks = pow(max(dot(H, N), 0.0), 16.0);
    vec4 D = vec4(Kd) * vec4(1,0.3,0.3,1);
    vec4 S = vec4(Ks) * vec4(1,1,0.3,1);
    vec4 F = vec4(t * 0.1) * vec4(0.4,0.7,2,1);
    return vec4((D + S + F).xyz + dir * 0.2, 1.0);
}

void main(void) {
    vec2 uv = ( gl_FragCoord.xy / resolution.xy )  * 2.0 - 1.0;
    uv.y *= resolution.y / resolution.x;
    float Z = 0.007;
    vec4 R = getcolor(uv, -Z);
    vec4 G = getcolor(uv, 0.0);
    vec4 B = getcolor(uv, Z);
    glFragColor.x = R.x;
    glFragColor.y = G.y;
    glFragColor.z = B.z;
    glFragColor.w = 1.0;
    float v = glFragColor.x * 0.298912 + glFragColor.y *  0.586611 + glFragColor.z * 0.114478;
    glFragColor.xyz *= mix(vec3(0.5,0.6,0.9), vec3(0.5,0.6,0.9).zyx, v);
    glFragColor.xyz *= clamp(glFragColor.xyz, vec3(0.0), vec3(1.0));
    glFragColor.xyz *= clamp(1.0 - dot(uv * 0.7, uv), 0.0, 1.0);
}
