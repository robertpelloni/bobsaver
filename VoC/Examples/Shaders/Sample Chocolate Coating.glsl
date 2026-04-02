#version 420

// original https://www.shadertoy.com/view/4tlXzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TWO_PI 6.28318530718
#define t time
#define res resolution.xy

vec3 cpos = vec3(0.0, 5.0, 5.0);
vec3 cdir = normalize(-cpos);
vec3 cside = vec3(1.0, 0.0, 0.0);
vec3 cup  = cross(cside, cdir);
vec3 light = normalize(vec3(0.6, 0.6, 1.0));

float smoothen(float d1, float d2) {
    float k = 1.5;
    return -log(exp(-k * d1) + exp(-k * d2)) / k;
}

float dist(vec3 p){
    float d = 100.0, r = 4.0;
    for (int i = 0; i < 5; i ++) {
        float m = 1.5 + float(i) * 0.4;
        d = smoothen(d, length(p - vec3(cos(t * m) * r, sin(t * m) * r, 0.0)) - 1.0);
    }
    d = smoothen(d, dot(p, vec3(0.0, 1.0, 0.0)) + 4.0);
    return d;
}

vec3 norm(vec3 p){
    vec2 d = vec2(0.001, 0.0);
    float di = dist(p);
    return normalize(vec3(di - dist(p - d.xyy), di - dist(p - d.yxy), di - dist(p - d.yyx)));
}

float shadow(vec3 o, vec3 d){
    o += norm(o) * 0.001;
    float len = 0.0, lev = 1.0;
    for(float t = 0.0; t < 32.0; t++){
        float di = dist(o + d * len);
        if (di < 0.001){ return 0.5;}
        lev = min(lev, di  * 8.0 / min(len, 1.0));
        len += di;
    }
    return max(0.5, lev) ;
}

vec3 phong(vec3 p, vec3 ray) {
    vec3 n = norm(p);
    return vec3(0.35,0.2,0.1) * clamp(dot(light, n), 0.0, 1.0)
        + pow(clamp(dot(normalize(light - ray), n), 0.0, 1.0), 128.0);
}

void main(void) {
    vec2 p = (gl_FragCoord.xy * 2.0 - res) / min(res.x, res.y);
    vec3 ray = normalize(cside * p.x + cup * p.y + cdir * 2.0);

    float len = 0.0, di=0.0;
    vec3 rhead = cpos;
    for(int i = 0; i < 64; i++){
        di = dist(rhead);
        if (abs(di) < 0.001) {
            break;
        }
        len += di;
        rhead = cpos + len * ray;
    }

    vec3 color=vec3(0.0);
    if(abs(di) < 0.001){
        color = phong(rhead, ray) * shadow(rhead, light);
    } 
    glFragColor = vec4(color, 1.0);
}
