#version 420

// original https://www.shadertoy.com/view/wtXXWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float XOR (float a,float b){
    float tmp1 = max(a,b);
    float tmp2 = min(a,b);
    return max(tmp2,-tmp1);
    
}
float map(vec3 p){
    p.xy *= mat2(cos(time),-sin(time),sin(time),cos(time));
    p = fract(p);
    float s  = length(p - vec3(0.5)) - 0.25;
    float po = min(min(length(p.xy - vec2(0.5)) - 0.1,length(p.yz - vec2(0.5)) - 0.1),length(p.xz - vec2(0.5)) - 0.1);
    return min(s,po);
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
    vec2 U = gl_FragCoord.xy;
    // Normalized pixel coordinates (from 0 to 1)
    vec3 R = vec3(resolution.xy,1.0),
    r = normalize(vec3((2.*U - R.xy )/  R.y,1.0)),
    o = vec3(0,0,-1.5 + time * 2.0);
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
