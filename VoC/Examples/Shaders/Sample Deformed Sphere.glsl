#version 420

// original https://www.shadertoy.com/view/3tfSWl

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
mat2 genRot(float val){
    return mat2(cos(val),-sin(val),sin(val),cos(val));
}
float map(vec3 p){
    p.xz *= genRot(time);
    float s = length(p) - 1.0;
    float p1 = abs(p.y  - p.x * p.z  - smoothstep(0.0,1.0,0.5 * sin(time * 1.5 + 2.0 * PI / 3.0) + 0.5)) - 0.1;
    float p2 = abs(p.x   - p.y * p.z  - smoothstep(0.0,1.0,0.5 * sin(time * 1.5+ 4.0 * PI / 3.0) + 0.5)) - 0.1;
    float p3 = abs(p.z  - (p.x * p.y)  - smoothstep(0.0,1.0,0.5 * sin(time * 1.5+ 6.0 * PI / 3.0) + 0.5)) - 0.1;
    return max(s,-min(min(p1,p2),p3));
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
    vec3 R = vec3(resolution.xy,1.0),
    r = normalize(vec3((2.*U - R.xy )/  R.y,1.2)),
    o = vec3(0,0,-1.75);
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
