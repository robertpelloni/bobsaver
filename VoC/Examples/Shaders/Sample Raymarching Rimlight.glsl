#version 420

// original https://www.shadertoy.com/view/wtlXD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 p){

        p.xz *= mat2(cos(time),-sin(time)
             ,sin(time),cos(time));
    p.xy *= mat2(cos(0.3),-sin(0.3)
             ,sin(0.3),cos(0.3));
    p.yz *= mat2(cos(0.3),-sin(0.3)
             ,sin(0.3),cos(0.3));
            float edge = p.x;
    float box1 = length(max(abs(p)-vec3(0.5,0.5,0.5),0.0))-0.1;
            p.xz *= mat2(cos(time),-sin(time)
             ,sin(time),cos(time));
        float box2 = length(max(abs(p - vec3(0.5,0.5,0.5))-vec3(0.5,0.5,0.5),0.0))-0.1;
            p.xz *= mat2(cos(-3.0 * time),-sin(-3.0 * time)
             ,sin(-3.0 * time),cos(-3.0 * time));
        float box3 = length(max(abs(p - vec3(-0.5,-0.5,-0.5))-vec3(0.5,0.5,0.5),0.0))-0.1;
    return max(length(p) - 1.0,-min(min(box2,box3),length(p) - 0.5));
}

const float EPS = 0.001;
vec3 getNormal(vec3 p) {
    return normalize(vec3(
        map(p + vec3(EPS, 0.0, 0.0)) - map(p + vec3(-EPS,  0.0,  0.0)),
        map(p + vec3(0.0, EPS, 0.0)) - map(p + vec3( 0.0, -EPS,  0.0)),
        map(p + vec3(0.0, 0.0, EPS)) - map(p + vec3( 0.0,  0.0, -EPS))
    ));
}

vec4 trace (vec3 o, vec3 r){
    float t = 0.0;
    vec3 p = vec3(0.0,0.0,0.0);
    
    for(int i = 0; i < 96; ++i){
        p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    return vec4(getNormal(p),t);
}

void main(void)
{
    vec2 U=gl_FragCoord.xy;
    // Normalized pixel coordinates (from 0 to 1)
    vec3 R = vec3(resolution,1.0),
    r = normalize(vec3((2.*U - R.xy )/  R.y,1.2)),
    o = vec3(0,0,-1.5);
    vec4 data = trace(o,r);
    vec3 n = vec3(data.xyz);
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.2);
    vec3 fc = t > 10000.0 ? vec3(0.8) : mix((vec3(data.x,data.y,data.z) + 1.0)/1.5
                                            ,vec3(0.0), - pow(dot(n,r),1.0));
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
