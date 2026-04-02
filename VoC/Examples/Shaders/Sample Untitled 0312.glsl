#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float surf(vec2 p) {
    p = mod(p + 2.0, 4.0) - 2.0;
    
    for(int i = 0; i < 10; i++) {
        p = abs(p)/clamp(dot(p, p), 0.4, 1.0) - vec2(0.2, 0.3);
    }
    
    return smoothstep(0.0, 0.1, abs(p.y));
}

float surfcube(vec3 p, vec3 n) {
    vec3 m = pow(abs(n), vec3(10.0));
    
    float x = surf(p.yz);
    float y = surf(p.xz);
    float z = surf(p.xy);
    
    return (m.x*x + m.y*y + m.z*z)/(m.x + m.y + m.z);
}

vec3 bump(vec3 p, vec3 n) {
    vec2 h = vec2(0.005, 0.0);
    vec3 b = vec3(
        surfcube(p + h.xyy, n) - surfcube(p - h.xyy, n),
        surfcube(p + h.yxy, n) - surfcube(p - h.yxy, n),
        surfcube(p + h.yyx, n) - surfcube(p - h.yyx, n));
    
    b -= n*dot(n, b);
    return normalize(n + 4.0*b);
}

float de(vec3 p) {
    vec4 q = vec4(p, 1);

    q.xz = mod(q.xz + 2.0, 4.0) - 2.0;
    q.xyz -= 1.0;

    for(int i = 0; i < 3; i++) {
        q.xyz = abs(q.xyz + 1.0) - 1.0;
        q /= clamp(dot(q.xyz, q.xyz), 0.4, 1.0);
        q *= 1.3;
    }
    
    return min(p.y + 1.0, length(max(abs(q.xz) - vec2(1.2), 0.0))/q.w);
}

float trace(vec3 ro, vec3 rd, float mx) {
    float t = 0.0;
    for(int i = 0; i < 100; i++) {
        float d = de(ro + rd*t);
        if (d < 0.001 || t >= mx) break;
        t += d*0.6;
    }
    return t;
}

vec3 normal(vec3 p) {
    vec2 h = vec2(0.001, 0.0);
    vec3 n = vec3(
        de(p + h.xyy) - de(p - h.xyy),
        de(p + h.yxy) - de(p - h.yxy),
        de(p + h.yyx) - de(p - h.yyx));
    
    return normalize(n);
}

float ao(vec3 p, vec3 n) {
    float o = 0.0, s = 0.005, w = 1.0;
    
    for(int i = 0; i < 15; i++) {
        float d = de(p + n*s);
        o += (s - d)*w;
        w *= 0.98;
        s += s/float(i + 1);
    }
    
    return clamp(1.0 - o, 0.0, 1.0);
}

vec3 render(vec3 ro, vec3 rd) {
    vec3 col = vec3(0);
    
    float t = trace(ro, rd, 50.0);
    if(t < 50.0) {
        vec3 pos = ro + rd*t;
        vec3 nor = normal(pos);

        nor = bump(pos, nor);
        vec3 ref = reflect(rd, nor);
        
        float occ = ao(pos, nor);
        
        col = vec3(occ);
        col += pow(clamp(dot(ref, -rd), 0.0, 1.0), 2.0);
        if (pos.y > -0.99) {
            col += vec3(20.0, 0.6*sin(time), 0.0)*(1.0 - occ);
        } else {
            vec3 npos = pos;
            npos.xz = mod(npos.xz + 2.0, 4.0) - 2.0;
            col += vec3(10.0, 0.3*sin(time), 0.0)*clamp(dot(-normalize(npos), nor), 0.0, 1.0)/(0.01 + 4.0*length(npos));
        }
    }
    
    col = mix(vec3(0), col, exp(-0.5*t));
    
    return col;
}

void main( void ) {
    vec2 p = (-resolution + 2.0*gl_FragCoord.xy)/resolution.y;
    
    float t = 0.3*time;
    vec3 ro = vec3(2.0, 1.0 + 1.9*sin(t), t);
    vec3 ww = normalize(vec3(2.0 + sin(t), sin(t), t+1.0)-ro);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
    vec3 vv = normalize(cross(ww, uu));
    vec3 rd = normalize(p.x*uu + p.y*vv + 1.97*ww);
    
    vec3 col = render(ro, rd);
    
    col = 1.0 - exp(-0.1*col);
    col = pow(abs(col), vec3(1.0/2.2));
    
    glFragColor = vec4(col, 1);
}
