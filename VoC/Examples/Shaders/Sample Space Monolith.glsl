#version 420

// original https://www.shadertoy.com/view/4sVXzK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float tmax = 20.0;

float map(vec3 p) {
    p.xy = mod(p.xy + 1.0, 2.0) - 1.0;
    p.z = abs(p.z) - 0.75;
    vec4 q = vec4(p, 1.0);
    
    for(int i = 0; i < 15; i++) {
        q.xyz = abs(q.xyz) - vec3(0.3, 1.0, -0.0);
        q = 2.0*q/clamp(dot(q.xyz, q.xyz), 0.5, 1.0) - vec4(1.0, 0.0, 0.3, 0.0);
    }
    
    return abs(q.x + q.y + q.z)/q.w;
}

float march(vec3 ro, vec3 rd) {
    float d = 1.0;
    float e, t = 0.0;
    
    for(int i = 0; i < 200; i++) {
        if(abs(d) < e || t >= tmax) break;
        d = map(ro + rd*t);
        e = 0.001*(1.0 + t*4.0);
        t += d*(0.55 + 0.05*t);
    }
    
    return t;
}

vec3 normal(vec3 p) {
    vec2 h = vec2(0.01, 0.0);
    vec3 n = vec3(
        map(p + h.xyy) - map(p - h.xyy),
        map(p + h.yxy) - map(p - h.yxy),
        map(p + h.yyx) - map(p - h.yyx)
    );
    return normalize(n);
}

mat3 camera(vec3 eye, vec3 lat) {
    vec3 ww = normalize(lat - eye);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
    vec3 vv = normalize(cross(ww, uu));
    
    return mat3(uu, vv, ww);
}

float hash2(vec2 n) {
    return fract(sin(dot(n, vec2(27.233, 71.989)))*43758.5453);
}

void main(void) {
    vec2 uv = -1.0 + 2.0*(gl_FragCoord.xy/resolution.xy);
    uv.x *= resolution.x/resolution.y;
    
    vec3 col = vec3(1)*step(0.997, hash2(uv));
    
    vec3 ro = vec3(time*0.5, 1.0*sin(time*0.3), 0.25*cos(time*0.2));
    vec3 rd = normalize(camera(ro, ro + vec3(3.0, 0, 4.0*sin(time*0.5)))*vec3(uv, 1.97));
    
    float i = march(ro, rd);
    if(i < tmax) {
        vec3 pos = ro + rd*i;
        vec3 nor = normal(pos);

        col = vec3(0.0);

        col += 0.1*pow(clamp(1.0 + dot(rd, nor), 0.0, 1.0), 2.0)*smoothstep(-8.0, -6.0, -i);

        float y = mod(pos.y + time, 2.0);
        col += 40.0*pow(clamp(1.0 + dot(rd, nor), 0.0, 1.0), 20.0)*vec3(1.0, 0.0, 0)
            *smoothstep(0.0, 0.2, y)
            *smoothstep(-0.2, 0.0, -y);
    }

    col = pow(col, vec3(.454545));
    
    glFragColor = vec4(col, 1);
}
