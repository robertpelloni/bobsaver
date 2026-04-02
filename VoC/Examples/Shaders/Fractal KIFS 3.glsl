#version 420

// original https://www.shadertoy.com/view/4sVXDt

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
    orb = vec4(10000.0);
    for(int i = 0; i < 8; i++) {
        rotate(p.xy, 0.8);
        rotate(p.xz, 0.4 + 0.4*cos(time));
        p = abs(p);
        p = 2.0*p - 1.0;
        
        orb = min(orb, vec4(abs(p), length(p)));
    }
    
    return length(p.xz)*pow(2.0, -8.0) - 0.01;
}

void main(void) {
    vec2 p = -1.0 + 2.0*gl_FragCoord.xy/resolution.xy;
    p.x *= resolution.x/resolution.y;
    
    float atime = time*0.3;
    
    vec3 ro = 2.0*vec3(cos(atime), 0, -sin(atime));
    vec3 ww = normalize(vec3(0, sin(time), 0) - ro);
    vec3 uu = normalize(cross(vec3(0, 1, 0), ww));
    vec3 vv = normalize(cross(ww, uu));
    vec3 rd = normalize(uu*p.x + vv*p.y + 1.97*ww);
    
    vec3 col = vec3(0.0,0.0,0.0);//textureCube(iChannel0, -rd).xyz;
    
    float t = 0.0;
    
    for(int i = 0; i < 100; i++) {
        float d = de(ro + rd*t);
        if(d < 0.001*t || t >= 10.0) break;
        t += d;
    }
    
    if(t < 10.0) {
        vec3 pos = ro + rd*t;
        vec2 h = vec2(0.001, 0.0);
        vec3 nor = normalize(vec3(
            de(pos + h.xyy) - de(pos - h.xyy),
            de(pos + h.yxy) - de(pos - h.yxy),
            de(pos + h.yyx) - de(pos - h.yyx)
        ));
        
        float o = 0.0, w = 1.0, s = 0.01;
        for(int i = 0; i < 15; i++) {
            float d = de(pos + nor*s);
            o += (s - d)*w;
            w *= 0.9;
            s += s/(float(i) + 1.0);
        }
        
        vec3 orbitColor = cos(vec3(0.1,0.6,1.6))*orb.x
            + sin(vec3(0.0,0.6,1.0))*orb.y 
            + cos(vec3(0.8,0.78,1.0))*orb.z 
            + sin(vec3(0.1,0.7,0.4))*orb.w;
        
        col = mix(vec3(1, 0.4, 0.4), 3.0*orbitColor, 0.1);
        
        col *= vec3(1.0 - clamp(o, 0.0, 1.0));
    } else {
        
    }
    
    glFragColor = vec4(col, 1);
}
