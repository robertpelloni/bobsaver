#version 420

// original https://neort.io/art/c9hlj3c3p9f0i94dn0fg

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
#define COLOR_S vec3(0.682, 0.706, 0.612)

float random2d(vec2 p){
    return fract(sin(dot(p, vec2(12.64524, 94.1241))) * 241222.21414);
}

float sdRect(vec2 p, vec2 s){
    vec2 q = abs(p) - s;
    return max(q.x, q.y);
}

vec3 lattice(vec2 uv, float s){
    uv += vec2(time*0.2);
    uv *= s;
    vec3 col = vec3(0.0);
    vec2 fPos = fract(uv) - 0.5;
    vec2 iPos = floor(uv);
    vec3 sColor = COLOR_N;
    float rand = random2d(iPos);
    if(0.1 < rand && rand <= 0.3){
        sColor = COLOR_T;
    }else if(0.3 < rand && rand <= 0.5){
        sColor = COLOR_M;
    }else if(0.5 < rand && rand <= 0.7){
        sColor = COLOR_K;
    }else if(0.7 < rand && rand <= 0.9){
        sColor = COLOR_H;
    }

    float rectScale = random2d(iPos + vec2(222.3141, 1241.142));
    float rectScale2 = random2d(iPos * vec2(222.3141, 1241.142));
    float rectLen = ((sin(rectScale*222.2+time*3.0)+1.0)*0.125) + ((cos(rectScale2*22.2+time*1.0)+1.0)*0.25);
    col += smoothstep(0.1, -0.1, sdRect(fPos, vec2(rectLen))) * sColor;

    return col;
}

vec3 renderingFunc(vec2 uv){
    vec3 color = vec3(0.0);

    color += lattice(uv, 4.0);
    return color;
}

void main(){
    vec2 uv = (gl_FragCoord.xy * 2.0 - resolution) / min(resolution.x, resolution.y);
    vec3 color = vec3(0.0);

    color += renderingFunc(uv);

    glFragColor = vec4(color, 1.0);
}
