#version 420

#define MAX_DIST 20.0
#define EPS 0.01

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 pos){
    return length(mod(pos, 2.0)-1.0)-0.5;
}

void main( void ) {
    vec2 uv = (gl_FragCoord.xy / resolution) * 2.0 - 1.0;
    uv.x *= resolution.x/resolution.y;
    vec3 ro = vec3(0.0, sin(time), time);
    mat2 rotation = mat2(cos(time), -sin(time), sin(time), cos(time));
    vec3 rd = normalize(vec3(uv, 1.0));
    rd.xy *= rotation;
    
    vec3 pos = ro;
    float t = EPS;
    float tt = 0.0;
    for(int i = 0; i < 64; i++){
        if(t < EPS || tt > MAX_DIST) break;
        t = map(pos);
        pos += rd * t;
        tt += t;
    }
    if(t < 0.01){
        vec2 eps = vec2(0.0, EPS);
        vec3 normal = normalize(vec3(
            map(pos + eps.yxx) - map(pos - eps.yxx),
            map(pos + eps.xyx) - map(pos - eps.xyx),
            map(pos + eps.xxy) - map(pos - eps.xxy)
        ));
        float diffuse = max(dot(normalize(ro - pos), normal), 0.0);
        float fog = (15.0 - tt) / (15.0 - 1.0);
        vec3 color = vec3(sin(length(pos) + time), cos(length(pos) + time), sqrt(cos(length(pos) + time)) * sin(length(pos) + time)) * diffuse;
        glFragColor = vec4(mix(vec3(0.0), color+0.15, fog), 1.0);
    }else glFragColor = vec4(vec3(0.0), 1.0);

}
