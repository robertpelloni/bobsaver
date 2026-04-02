#version 420

// original https://www.shadertoy.com/view/wtfSRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
float map(vec3 p){
    p = mod(abs(p), 3.0) - 1.5;
    float wall = abs(dot(p.xy,vec2(cos(p.z),sin(p.z)))) + 0.1;
    float poleX = length(p.yz) - 0.1;
     float poleY = length(p.xz) - 0.1;
    return min(min(wall,poleX),poleY);
    

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
    float fog = 1.0 / (1.0 + t * t * 0.05);
    vec3 fc = mix(vec3(0.5 - data.x,0.5 -data.y,0.5-data.z),vec3(0),1.0 - fog);
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
