#version 420

// original https://www.shadertoy.com/view/3tf3R8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    
    return mat2(c, s, -s, c);
}

float box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return max(max(q.x, q.y), q.z);
}

float box(vec2 p, vec2 b) {
    vec2 q = abs(p) - b;
    return max(q.x, q.y);
}

vec2 opU(vec2 a, vec2 b) {
    return a.x < b.x ? a : b;
}

float ac[16]; // store rotations.

vec2 de(vec3 p) {
    vec3 op = p;
    float at = mod(time*3.0, PI*9.0);
    
    float j = 0.0;
    for(int i = 0; i < 16; i++) {
        float s = i < 8 ? 1.0 : -1.0;
        ac[i] = s*PI*smoothstep(j*PI, (j+0.5)*PI, at);
        j += 0.5;
    }
    
    // I hate this, but I can't find a better way to do it.
    // do the rotations in reverse so the steps() don't interfer with eachother.
    p.xz *= rot(ac[15]*step(0.6, p.y)); // last rotation to happen chronologically
    p.xy *= rot(ac[14]*step(0.6, p.z));
    p.yz *= rot(ac[13]*step(0.6, p.x));
    p.xz *= rot(ac[12]*step(0.6, -p.y));
    p.xy *= rot(ac[11]*step(0.6, -p.z));
    p.yz *= rot(ac[10]*step(0.6, -p.x));
    p.xz *= rot(ac[9]*step(0.6, p.y));
    p.xy *= rot(ac[8]*step(0.6, p.z));
    
    p.xy *= rot(ac[7]*step(0.6, p.z));
    p.xz *= rot(ac[6]*step(0.6, p.y));
    p.yz *= rot(ac[5]*step(0.6, -p.x));
    p.xy *= rot(ac[4]*step(0.6, -p.z));
    p.xz *= rot(ac[3]*step(0.6, -p.y));
    p.yz *= rot(ac[2]*step(0.6, p.x));
    p.xy *= rot(ac[1]*step(0.6, p.z));
    p.xz *= rot(ac[0]*step(0.6, p.y)); // first rotation to happen chronologically
    
    // hacky way to get the different colors.
    float m = 0.0;
    if(p.x > 1.73) m = 1.0;
    else if(p.y > 1.73) m = 2.0;
    else if(p.z > 1.73) m = 3.0;
    else if(p.x < -1.73) m = 4.0;
    else if(p.z < -1.73) m = 5.0;
    else if(p.y < -1.73) m = 6.0;
    
    p = abs(p) - vec3(0.6);
    p = abs(p) - vec3(0.6);

    float b = box(p, vec3(0.55));
        
    float c = box(p, vec3(0.56));
    c = max(c, -box(p.xz, vec2(0.5)));
    c = max(c, -box(p.xy, vec2(0.5)));
    c = max(c, -box(p.yz, vec2(0.5)));
        
    vec2 t = vec2(b, m);
    vec2 s = vec2(length(op) - 1.7, 7.0);
    vec2 u = vec2(c, 7.0);
    
    return opU(t, opU(s, u));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy - 0.5*resolution.xy)/resolution.y;
    
    vec3 col = vec3(0);
    vec3 bcol = col = vec3(0.3, 0.4, 1.0);
    
    float a = 6.7;
    float at = time*0.6;
    
    vec3 ro = vec3(a*cos(at), 3, -a*sin(at));
    vec3 ww = normalize(vec3(0, 0, 0)-ro);
    vec3 uu = cross(vec3(0, 1, 0), ww);
    vec3 vv = cross(ww, uu);
    vec3 rd = normalize(mat3(uu, vv, ww)*vec3(uv, 1.0));
    
    float t = 0.0, m = -1.0, mx = 50.0;
    for(int i = 0; i < 300; i++) {
        vec2 d = de(ro + rd*t);
        if(abs(d.x) < 0.0001 || t >= mx) break;
        t += d.x*0.25;
        m = d.y;
    }
    
    vec3 ld = normalize(vec3(0.6, 0.5, -0.5));
    
    if(t < mx) {
        vec3 p = ro + rd*t;
        vec2 h = vec2(0.001, 0.0);
        vec3 n = normalize(vec3(
            de(p + h.xyy).x - de(p - h.xyy).x,
            de(p + h.yxy).x - de(p - h.yxy).x,
            de(p + h.yyx).x - de(p - h.yyx).x
        ));
                
        vec3 ld = normalize(p);
        
        float glo = 16.0;
        vec3 alb = vec3(0.9);
        
        if(m == 1.0) alb = vec3(1.0, 0.3, 0.3);
        else if(m == 2.0) alb = vec3(0.3, 1.0, 0.3);
        else if(m == 3.0) alb = vec3(0.3, 0.3, 1.0);
        else if(m == 4.0) alb = vec3(3.0);
        else if(m == 5.0) alb = vec3(1.0, 1.0, 0.3);
        else if(m == 6.0) alb = vec3(1.0, 0.3, 1.0);
        else if(m == 7.0) alb = vec3(0);
        
        float occ = exp2(-pow(max(0.0, 1.0 - de(p + n*0.05).x/0.05), 2.0));
        float dif = max(0.0, dot(ld, n));
        float spe = pow(max(0.0, dot(reflect(-ld, n), -rd)), glo);
        float fre = pow(1.0 + dot(rd, n), 4.0);
        
        col = 0.5*mix(occ*(alb*(0.25 + dif) + spe), bcol, fre);
    }
    
    glFragColor = vec4(pow(col, vec3(0.4545)), 1);
}
