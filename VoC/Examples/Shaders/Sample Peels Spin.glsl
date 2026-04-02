#version 420

// original https://www.shadertoy.com/view/wlfXDj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 p){

        p.xz *= mat2(cos(time),-sin(time)
             ,sin(time),cos(time));
    float s1 = max(abs(length(p) - 1.8) - 0.05, max(p.x,-p.z));
        p.yz *= mat2(cos(time),-sin(time)
             ,sin(time),cos(time));
    float s2 = max(abs(length(p) - 1.5) - 0.05,max(p.y,-p.z));
        p.xy *= mat2(cos(time),-sin(time)
             ,sin(time),cos(time));
    float s3 = max(abs(length(p) - 1.2) - 0.05,max(p.x,-p.y));
            p.xz *= mat2(cos(time),-sin(time)
             ,sin(time),cos(time));
    float s4 = max(abs(length(p) - 0.9) - 0.05, max(-p.x,p.z));
            p.yz *= mat2(cos(time),-sin(time)
             ,sin(time),cos(time));
    float s5 = max(abs(length(p) - 0.6) - 0.05,max(-p.y,p.z));
            p.xy *= mat2(cos(time),-sin(time)
             ,sin(time),cos(time));
    float s6 = max(abs(length(p) - 0.3) - 0.05,max(-p.x,p.y));
    float holes = min((length(p.xy) - 0.2),min((length(p.xz) - 0.2),(length(p.yz) - 0.2)));
    return max(min(min(s1,min(s2,s3)),min(s4,min(s5,s6))),  -holes);
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
    // Normalized pixel coordinates (from 0 to 1)
    float PI = 3.14159265;
    vec2 uv = gl_FragCoord.xy /resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 r = normalize(vec3(uv,1.2));
    
    vec3 o = vec3(0,0,-2.5);
    vec4 data = trace(o,r);
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.1);
    vec3 fc = mix(vec3(0.5 - data.x,0.5 -data.y,0.5-data.z),vec3(1.0),1.0 - fog);
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
