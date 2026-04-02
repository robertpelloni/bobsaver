#version 420

// original https://neort.io/art/c9o0bqk3p9fbkmo5o5r0

uniform vec2 resolution;
uniform float time;
uniform vec2 mouse;
uniform sampler2D backbuffer;

out vec4 glFragColor;

#define COLOR_N vec3(0.15, 0.34, 0.6)
#define COLOR_T vec3(0.313, 0.816, 0.816)
#define COLOR_M vec3(0.745, 0.118, 0.243)
#define COLOR_K vec3(0.475, 0.404, 0.765)
#define COLOR_H vec3(1.0, 0.776, 0.224)
#define COLOR_C vec3(0.98, 0.514, 0.2)
#define COLOR_KA vec3(0.898, 0.275, 0.11)
#define COLOR_CH vec3(0.976, 0.231, 0.565)
#define COLOR_JU vec3(1.0, 0.776, 0.008)
#define COLOR_RI vec3(0.537, 0.765, 0.922)
#define COLOR_NA vec3(0.549, 0.902, 0.404)
#define COLOR_S vec3(0.682, 0.706, 0.612)

float pi = acos(-1.0);

mat2 rotate(float a){
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float random2d(vec2 p){
    return fract(sin(dot(p, vec2(12.64524, 94.1241))) * 241222.21414);
}

float sdStar(vec2 uv, float s){
    float pi2 = pi * 2.0;
    float a = atan(uv.y, uv.x) / pi2;
    float seg = a * 5.0;
    a = ((floor(seg)+0.5)/5.0 + mix(s, -s, step(0.5, fract(seg)))) * pi2;
    return abs(dot(vec2(cos(a), sin(a)), uv));
}

vec3 starTextureC(vec2 uv){
    vec3 col = vec3(0.0);
    uv -= vec2(time, -time) * 0.2;
    uv *= 5.0;
    vec2 fPos = (fract(uv) - 0.5) * 2.0;
    vec2 iPos = floor(uv);

    col += COLOR_C;
    float rand = random2d(iPos);
    if(0.0 <= rand && rand < 0.2){
        col = mix(col, COLOR_KA, step(sdStar(fPos, 0.31), 0.3));
    }else if(0.2 <= rand && rand < 0.4){
        col = mix(col, COLOR_CH, step(sdStar(fPos, 0.31), 0.3));
    }else if(0.4 <= rand && rand < 0.6){
        col = mix(col, COLOR_JU, step(sdStar(fPos, 0.31), 0.3));
    }else if(0.6 <= rand && rand < 0.8){
        col = mix(col, COLOR_RI, step(sdStar(fPos, 0.31), 0.3));
    }else{
        col = mix(col, COLOR_NA, step(sdStar(fPos, 0.31), 0.3));
    }

    return col;
}

vec3 starTextureN(vec2 uv){
    vec3 col = vec3(0.0);
    uv -= vec2(time, time) * 0.2;
    uv *= 5.0;
    vec2 fPos = (fract(uv) - 0.5) * 2.0;
    vec2 iPos = floor(uv);

    col += COLOR_N;
    float rand = random2d(iPos);
    if(0.0 <= rand && rand < 0.25){
        col = mix(col, COLOR_T, step(sdStar(fPos, 0.31), 0.3));
    }else if(0.25 <= rand && rand < 0.5){
        col = mix(col, COLOR_M, step(sdStar(fPos, 0.31), 0.3));
    }else if(0.5 <= rand && rand < 0.75){
        col = mix(col, COLOR_K, step(sdStar(fPos, 0.31), 0.3));
    }else{

        col = mix(col, COLOR_H, step(sdStar(fPos, 0.31), 0.3));
    }

    return col;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    vec3 starRipple = vec3(step(sin(sdStar(uv * 10.0, 0.1) - time * 4.0), 0.0));

    color = mix(starTextureN(uv), starTextureC(uv), starRipple);
    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
