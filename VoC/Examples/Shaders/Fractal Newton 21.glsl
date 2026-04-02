#version 420

// original https://www.shadertoy.com/view/NdGSRz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 mul(vec2 a, vec2 b) { return vec2(a.x*b.x-a.y*b.y, a.x*b.y+a.y*b.x); }
vec2 inv(vec2 a) { return vec2(a.x, -a.y) / (a.x*a.x + a.y*a.y); }

const int deg = 10;
vec2 roots[deg];

vec2 f(vec2 a) {
    vec2 ret = vec2(1.0, 0.0);
    for (int i = 0; i < deg; i++) {
        ret = mul(ret, a-roots[i]);
    }
    return ret;
}

vec2 fp(vec2 a) {
    vec2 sum = vec2(0.0, 0.0);
    for (int i = 0; i < deg; i++) {
        sum += inv(a-roots[i]);
    }
    return inv(sum);
}

void main(void) {
    vec2 a = 2.5 * (gl_FragCoord.xy - resolution.xy / 2.0) / min(resolution.x, resolution.y);
    glFragColor = vec4(0.0, 0.0, 0.0, 1.0);
    
    for (int i = 0; i < deg; i++) {
        float rot = 0.1 * time * (float(i)+1.0);
        roots[i] = vec2(cos(rot), sin(rot));
    }
    
    vec2 u = a;
    for (int i = 0; i < 10; i++) {
        u -= fp(u);
    }
    int closestI = 0;
    float closestDistance = distance(u, roots[0]);
    for (int i = 1; i < deg; i++) {
        float d = distance(u, roots[i]);
        if (d < closestDistance) {
            closestDistance = d;
            closestI = i;
        }
    }
    glFragColor.rgb = vec3(float(closestI) / float(deg));
    
    for (int i = 0; i < deg; i++) {
        if (distance(roots[i], a) < 0.05) {
            glFragColor.r = 1.0;
        }
    }
}
