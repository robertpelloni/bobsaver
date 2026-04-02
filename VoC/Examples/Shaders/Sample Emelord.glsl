#version 420

// original https://www.shadertoy.com/view/ssScWG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI = acos(-1.);

mat2 rot(float a){
    float s = sin(a), c = cos(a);
    return mat2(c, s, -s, c);
}

float rand(vec2 p){
    return fract(sin(dot(p, vec2(321.52, 92.324))) * 5321.532);
}

float sdBox(vec3 p, vec3 b){
    vec3 d = abs(p) - b;
    return length(max(d, 0.)) + min(max(max(d.x, d.y), d.z), 0.);
}

float sdSphere(vec3 p, float r){
    return length(p) - r;
}

float map(vec3 p){
    vec3 q = p;
    p = mod(p, 2.) - 1.;
    float s = 1.;
    
    float t = floor(time) + smoothstep(.5, .7, fract(time));
    p.z += sin(p.z) * .2;
    for(int i = 0; i < 5; i++){
        p = abs(p) - .3;
        p.xy *= rot(.6);
        p = abs(p) - .1;
        p.xz *= rot(.28 * t);
        p *= 1.5;
        s *= 1.5;
    }
    q.xy *= rot(PI / 4.);
    q = abs(q);
    float d1 = max(q.x, q.y) - .1;
    return max(-d1, sdBox(p, vec3(.2, .1, .2)) / s);
}

vec3 genNormal(vec3 p){
    vec2 d = vec2(0.01, 0.);
    return normalize(vec3(
        map(p + d.xyy) - map(p - d.xyy),
        map(p + d.yxy) - map(p - d.yxy),
        map(p + d.yyx) - map(p - d.yyx)
        ));
}

void main(void) {

    vec2 p = ( gl_FragCoord.xy * 2. - resolution.xy ) / min(resolution.x, resolution.y);

    vec3 col = vec3(0.0);
    
    vec3 cp = vec3(0., 0., -2. + time);
    vec3 t = vec3(0., 0., 0. + time);
    vec3 f = normalize(t - cp);
    vec3 u = vec3(0., 1., 0.);
    vec3 s = normalize(cross(u, f));
    u = normalize(cross(f, s));
    vec3 rd = normalize(p.x * s + p.y * u + f * (1. + .05 * (1. - dot(p, p))));
    
    float dd, d;
    int k;
    float ac;
    
    cp += rand(p * time) * rd * .1;
    
    for(int i = 0; i < 100; i++){
        dd = map(cp + d * rd);
        if(dd < 0.001){
            break;
        }
        ac += exp(-d * .3);
        k = i;
        d += dd;
    }
    col += 1.-float(k) / 100.;
    col -= ac * 0.1 * vec3(1., .1, .2);
        
    vec3 ip = cp + d * rd;
    
    col = mix(vec3(1.), col, exp(-.1 * d));
    col = pow(col, vec3(0.4545));
    glFragColor = vec4(col, 1.0 );

}
