#version 420

// original https://www.shadertoy.com/view/wtXXRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
mat2 makeRotMat(float val){
    return mat2(cos(val),-sin(val),sin(val),cos(val));
}
float map(vec3 p){
    float wall_in = abs(p.x*cos(p.z / 5.0)+p.y*sin(p.z / 5.0)) - 1.0;
    float wall_out = abs(p.x*cos(p.z / 5.0)+p.y*sin(p.z / 5.0)) - 1.2;
    float wall = max(wall_out, -wall_in);
    float poles = length(abs(p.xy * makeRotMat(p.z / 5.0)) - vec2(0.4,0.0)) - 0.15;
    return min(wall,poles); 
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
    
    for(int i = 0; i < 32; ++i){
        p = o + r * t;
        float d = map(p);
        t += d * 0.5;
    }
    return vec4(getNormal(p),t);
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy /resolution.xy;
    uv = uv * 2.0 - 1.0;
    uv.x *= resolution.x / resolution.y;
    vec3 r = normalize(vec3(uv,1.0));
    vec3 o = vec3(0,0,time * 3.0);
    vec4 data = trace(o,r);
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.2);
    vec3 fc = mix(vec3(0.5 - data.x,0.5 -data.y,0.5-data.z),vec3(1),1.0 - fog);
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
