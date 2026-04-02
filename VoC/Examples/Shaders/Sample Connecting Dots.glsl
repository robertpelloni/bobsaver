#version 420

// original https://www.shadertoy.com/view/Ws3SRn

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float DistLine(vec2 p, vec2 a, vec2 b) {
    
    vec2 ap = p - a;
    vec2 ab = b - a;
    
    float t = clamp(dot(ap, ab) / dot(ab, ab), 0.0, 1.0);
    
    return length(ap - ab * t);
        
}

float N21(vec2 p) {
    
     p = fract(p * vec2(233.34, 851.73));
    p += dot(p, p+23.45);
    
    return fract(p.x * p.y);
    
}

vec2 N22(vec2 p) {
    
    float n = N21(p);
    
    return vec2(n, N21(p + n));
    
}

vec2 GetPos(vec2 id, vec2 offset) {
    
    vec2 n = N22(id + offset) * time;
    
    return offset + sin(n) * 0.4;

}

float Line(vec2 p, vec2 a, vec2 b) {
    
    float d = DistLine(p, a, b);
    float m = smoothstep(0.03, 0.01, d);
    
    m *= smoothstep(1.2, 0.8, length(a - b));
    
    return m;
    
}

void main(void) {

    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
    float m = 0.0;
    
    uv *= 5.0;
    
    vec2 gv = fract(uv) - 0.5;
    vec2 id = floor(uv);
    
    vec2 p[9];
    
    int i = 0;
    for (float y = -1.0; y <= 1.0; y++) {
        for (float x = -1.0; x <= 1.0; x++) {
            vec2 offset = vec2(x, y);
            p[i++] = GetPos(id, offset);
        }
    }
    
    float t = time * 10.0;
    for (int i = 0; i < 9; i++) {
        m += Line(gv, p[4], p[i]);
        
        vec2 j = (p[i] - gv) * 20.0;
        float sparkle = 0.5 / dot(j, j);
        
        m += sparkle * (sin(t + p[i].x * 5.0) * 0.5 + 0.5);
    }
    
    m += Line(gv, p[1], p[3]);
    m += Line(gv, p[1], p[5]);
    m += Line(gv, p[7], p[3]);
    m += Line(gv, p[7], p[5]);
    
    vec3 col = vec3(m);
    
    // if (gv.x > 0.48 || gv.y > 0.48) col = vec3(1, 0, 0);

    glFragColor = vec4(col, 1.0);
    
}
