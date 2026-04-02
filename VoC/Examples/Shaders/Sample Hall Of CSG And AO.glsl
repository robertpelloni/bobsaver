#version 420

// original https://www.shadertoy.com/view/Xt3GRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define MAX_ITER 1000
#define MAX_DIST 100.0
#define EPSILON 0.0001
#define AO_SAMPLES 25
#define AO_STRENGTH 1.0

vec3 camPos = vec3(0.0, 0.5, time * 2.0);

float map(vec3 p){
    vec3 q = vec3(mod(p.x, 8.0) - 4.0, p.y, mod(p.z, 8.0) - 4.0);
    float cube = length(max(abs(q) - 2.0,0.0));
    float sphere = length(q) - 2.5;
    return min(-p.y + 2.0, min(p.y + 2.0, max(-sphere, cube)));
}

float trace(vec3 ro, vec3 rd){
     float t = 0.0;
    float d = 0.0;
    for(int iter = 0; iter < MAX_ITER; iter++){
        d = map(ro + rd * t);
        if(d < EPSILON){
            break;
        }
        if(t > MAX_DIST){
            t = 0.0;
            break;
        }
        t += d;
    }
    return t;
}

mat3 rotY(float d){
    float c = cos(d);
    float s = sin(d);
    
    return mat3(  c, 0.0,  -s,
                0.0, 1.0, 0.0,
                  s, 0.0,   c);
}

vec3 normal(vec3 p){
    return vec3(map(vec3(p.x + EPSILON, p.yz)) - map(vec3(p.x - EPSILON, p.yz)),
                map(vec3(p.x, p.y + EPSILON, p.z)) - map(vec3(p.x, p.y - EPSILON, p.z)),
                map(vec3(p.xy, p.z + EPSILON)) - map(vec3(p.xy, p.z - EPSILON)));
}

float occlusion(vec3 ro, vec3 rd){
    float k = 1.0;
    float d = 0.0;
    float occ = 0.0;
    for(int i = 0; i < AO_SAMPLES; i++){
        d = map(ro + 0.1 * k * rd);
        occ += 1.0 / pow(2.0, k) * (k * 0.1 - d);
        k += 1.0;
    }
    return 1.0 - clamp(AO_STRENGTH * occ, 0.0, 1.0);
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 ro = camPos;
    vec3 rd = normalize(vec3(uv, 1.0));
    rd *= rotY(time / 3.0);
    float d = trace(ro, rd);
    vec3 col;
    if(d == 0.0){
        col = vec3(0.0);
    }else{
        vec3 x = ro + (rd * d);
        vec3 n = normalize(normal(x)); 
        col = vec3(occlusion(x, n));
        col *= vec3(1.0 / exp(d * 0.08));
    }
    glFragColor = vec4(col,1.0);
}
