#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void rotate(inout vec2 p, float a) {
    float c = cos(a);
    float s = sin(a);
    
    p = mat2(c, s, -s, c)*p;
}

void fold(inout vec2 p) {
    if(p.x + p.y < 0.0) p.xy = -p.yx;
}

vec3 orb;
float map(vec3 p) {
    float s = 1.5;
    vec3 x = 3.0*normalize(vec3(1, 1, 1));
    
    int it = 20;
    orb = vec3(1000.0);
    for(int i = 0; i < 100; i++) {
        if(i >= it) break;
        rotate(p.xy, time*0.3);
        rotate(p.zy, time*0.3);
        
        fold(p.xy);
        fold(p.xz);
        fold(p.zy);
        
        p = p*s - x*(s - 1.0);
        
        orb.x = min(orb.x, length(p.yz));
        orb.y = min(orb.y, length(p.xz));
        orb.z = min(orb.z, length(p.xy));
    }
    
    return length(p)*pow(s, -float(it));
}

float march(vec3 ro, vec3 rd) {
    float t = 0.0;
    
    for(int i = 0; i < 100; i++) {
        float d = map(ro + rd*t);
        if(d < 0.0005*(1.0 + 3.0*t) || t >= 10.0) break;
        t += d;
    }
    
    return t;
}

vec3 normal(vec3 p) {
    vec2 h = vec2(0.001, 0.0);
    vec3 n = vec3(
        map(p + h.xyy) - map(p - h.xyy),
        map(p + h.yxy) - map(p - h.yxy),
        map(p + h.yxy) - map(p - h.yyx)
    );
    return normalize(n);
}

mat3 camera(vec3 eye, vec3 lat) {
    vec3 ww = normalize(lat - eye);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
    vec3 vv = normalize(cross(ww, uu));
    
    return mat3(uu, vv, ww);
}

void main( void ) {
    vec2 uv = -1.0 + 2.0*(gl_FragCoord.xy/resolution);
    uv.x *= resolution.x/resolution.y;
    
    vec3 col = vec3(0);
    
    vec3 ro = 3.0*vec3(1, 0, -1.0);
    vec3 rd = normalize(camera(ro, vec3(0))*vec3(uv, 1.97));
    
    float i = march(ro, rd);
    if(i < 10.0) {
        vec3 pos = ro + rd*i;
        vec3 nor = normal(pos);
        
        vec3 key = normalize(vec3(0.8, 0.7, -0.6));
        
        col  = 0.2*vec3(1);
        col += 0.7*clamp(dot(key, nor), 0.0, 1.0);
        col += 0.1*clamp(dot(-key, nor), 0.0, 1.0);
        
        vec3 mat =  mix(vec3(1), vec3(0.2, 0.8, 0.2), orb.x);
        mat = mix(mat, vec3(0.2, 0.2, .8), orb.y);
        mat = mix(mat, vec3(0.8, 0.2, 0.2), orb.z);
        
        col *= mat;
    }
    
    col = sqrt(col);
    
    glFragColor = vec4(col, 1);
}
