#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

void rotate(inout vec2 p, float a) {
    float s = sin(a);
    float c = cos(a);
    
    p = mat2(c, s, -s, c)*p;
}

vec4 orb;
float de(vec3 p) {
    p.z += time;
    p.z = mod(p.z + 5.0, 10.0) - 5.0;
    
    vec4 q = vec4(p, 1);
    vec4 o = q;
    
    orb = vec4(100000.0);
    for(int i = 0; i < 10; i++) {
        rotate(q.xy, 0.5 + 0.1*length(cos(q.xyz)));
        q.xyz = 2.0*clamp(q.xyz, -1.0, 1.0) - q.xyz;
        float r = dot(q.xyz, q.xyz);
        q *= clamp(1.0/r, 1.0, 1.0/0.3);
        
        orb = min(orb, vec4(abs(q.xyz), sqrt(r)));
        q = 3.0*q - o;
    }
    
    return 0.25*(length(q.xy)/q.w) - 0.001;
}

void main( void ) {
    vec2 p = -1.0 + 2.0*gl_FragCoord.xy/resolution;
    p.x *= resolution.x/resolution.y;

    float time = time*0.3;
    
    vec3 col = vec3(0);

    vec3 ro = 4.0*vec3(cos(time), (4.0/4.0)*sin(time), -sin(time));
    vec3 ww = normalize(-ro);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
    vec3 vv = normalize(cross(ww, uu));
    vec3 rd = normalize(p.x*uu + p.y*vv + 1.97*ww);
    
    float t = 0.0;
    for(int i = 0; i < 100; i++) {
        float d = de(ro + rd*t);
        if(d < 0.001*t || t >= 10.0) break;
        t += d;
    }
    
    if(t < 10.0) {
        vec3 pos = ro + rd*t;
        vec2 eps = vec2(0.001, 0.0);
        vec3 nor = normalize(vec3(
            de(pos + eps.xyy) - de(pos - eps.xyy),
            de(pos + eps.yxy) - de(pos - eps.yxy),
            de(pos + eps.yyx) - de(pos - eps.yyx)
        ));
        
        vec3 oc = vec3(0.1, 0.1, 1.0)*orb.x
            + vec3(1.0, 0.6, 0.4)*orb.y
            + vec3(0.1, 0.1, 1.0)*orb.z
            + vec3(1.0, 0.3, 0.2)*orb.w;
        
        col = mix(vec3(1), oc, 1.0);
        
        float o = 0.0, w = 1.0, s = 0.05;
        for(int i = 0; i < 10; i++) {
            float d = de(pos + nor*s);
            o += (s - d)*w;
            w *= 0.7;
            s += s/(float(i) + 1.0);
        }
        
        
        col *= vec3(1.0 - clamp(o, 0.0, 1.0));
    }
    
    glFragColor = vec4(col, 1);
}
