#version 420

// @machine_shaman

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 p) {
    
    
    
    p.y += sin(p.x / 2. + time);
    p.y += sin(p.z / 2. + time);
    vec2 i = floor(p.xz);
    p.xz = 2. * fract(p.xz) - 1.;
    
    p.y += .5 * sin(i.x * 2. - time);
    p.y += .5 * sin(i.y * 2. - time);
    return length(max(abs(p) - .5, 0.)) - .5;
    
}

vec3 normal(vec3 p) {
    float e = 0.01;
    return normalize(vec3(
        map(p + vec3(e, 0, 0)) - map(p - vec3(e, 0, 0)),
        map(p + vec3(0, e, 0)) - map(p - vec3(0, e, 0)),
        map(p + vec3(0, 0, e)) - map(p - vec3(0, 0, e))
    ));
}

vec3 render(vec3 ro, vec3 rd) {
    vec3 p = ro.xxx;
    float t = 0.;
    
    for (int i = 0; i < 60; i++) {
        p = ro + rd  * t;
        t += 0.5 * map(p);
    }
    
    vec3 l = vec3(0, 2, time);
    vec3 nor = normal(p);
    vec3 ld = l - p;
    float len = length(ld);
    
    float diff = max(dot(ld, nor), 0.);

    vec3 pr = normalize(p - ro);
    vec3 ref = normalize(reflect(-ld, nor));
    
    float spec = pow(max(dot(pr, ref), 0.), 50.);
    
    return vec3(( 0.5 * diff + spec) / (1. + len * len * .1));
    
}

void main() {

    vec2 uv = (2. * gl_FragCoord.xy - resolution) / resolution.y;
    vec3 col = vec3(0.);
    uv.y = .2 - abs(uv.y);
    vec3 ro = vec3(0, 4, time);
    vec3 rd = normalize(vec3(uv, 1));
    
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 o = vec2(i, j) / resolution;
            col += render(ro, rd - vec3(o, 0.));
        }
    }
    col /= 9.;

    glFragColor = vec4(col, 1.);

}
