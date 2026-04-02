#version 420

// original https://www.shadertoy.com/view/3tKGzV

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define SURF_HIT 0.001
#define FAR_PLANE 50.
#define t time
#define S(x,y,z) smoothstep(x,y,z)

mat2 r2d(float a) {float sa=sin(a), ca=cos(a);return mat2(ca, -sa, sa, ca);}

float map(vec3 p) {
    vec3 q = p;
    float s = 5.0;
    q = mod(q, s) - s*.5;
    float d = length(q.xy) - 0.4;
    d = min(d, length(q.xz) - 0.4);
    d = min(d, length(q.yz) - 0.4);
    return d;
}

vec3 mapNormal(vec3 p) {
    vec2 e = vec2(SURF_HIT, 0);
    float m = map(p);
    return normalize(vec3(
        m - map(p - e.xyy),
        m - map(p - e.yxy),
        m - map(p - e.yyx)
    ));
}

float mapTrace(vec3 ro, vec3 rd) {
    float d = 0.;
    for (int i=0;i<128;i++) {
        float h = map(ro + rd * d);
        if (h < SURF_HIT || d >= FAR_PLANE) break;
        d += h;
    }
    return d;
}

void main(void) {
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y * 1.0;

    vec3 ro = vec3(0, 0, 0);
    vec3 rd = normalize(vec3(uv, -1));
    
    ro += vec3(0, 0, -5.*t);
    rd.xy *= r2d(mix(t * 0.5 - 1.0, t * 0.5, sin(t)));

    float d = mapTrace(ro, rd);
    vec3 p = ro + rd*d;
    vec3 n = mapNormal(p);

    vec3 fogCol = vec3(1);
    vec3 col = fogCol;
    if (d < FAR_PLANE) {
        vec3 outer = vec3(0.9);
        vec3 inner = vec3(0.1, 0.1, 0.1);
        
        float f = pow(clamp(1.0 - dot(-rd, n), 0.0, 1.0), 1.5);
        float fog = clamp(pow(d/FAR_PLANE, 1.), 0.0, 1.0);
        
        col = f * outer + (1.0 - f) * inner;        
        col = mix(col, fogCol, vec3(fog));
    }
    
    glFragColor = vec4(col, 1.0f);
}
