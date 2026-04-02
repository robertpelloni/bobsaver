#version 420

// original https://www.shadertoy.com/view/wlsSRj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
vec2 path(float z){
    float x = sin(z) + 2.0 * cos(z * 0.3) - 1.5 * sin(z * 0.12345);
    float y = cos(z) + 1.5 * sin(z * 0.3) + 2.0 * cos(z * 0.12345);
    return vec2(x,y);
}
vec2 cir(float rot){
    return vec2(cos(rot),sin(rot));
}
float rate(float t){
    return 1.0 + 0.5*sin(t);
}
float map(vec3 p){
    p.xy = fract(p.xy/5.0) * 8.0 * rate(time*2.0) - 4.0*rate(time*2.0);
    vec2 o = vec2(0,0);
    float tT1 = length(p.xy - (o/4.0) - (vec2(cir(((0.0/3.0) + (p.z/4.0)) * PI)) * 2.0)) - 0.4 *fract(p.z) ;
    float tT2 = length(p.xy - (o/4.0) - (vec2(cir(((2.0/3.0) + (p.z/4.0)) * PI)) * 2.0)) - 0.4*fract(p.z);
    float tT3 = length(p.xy - (o/4.0) - (vec2(cir(((4.0/3.0) + (p.z/4.0)) * PI)) * 2.0)) - 0.4*fract(p.z);
    return min(min(tT1,tT2),tT3);

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
    
    for(int i = 0; i < 64; ++i){
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
    vec3 r = normalize(vec3(uv,0.5));
    r.xz *= mat2(cos(0.1 * PI),-sin(0.1 * PI),sin(0.1 * PI),cos(0.1 * PI));
    r.yz *= mat2(cos(0.1 * PI),-sin(0.1 * PI),sin(0.1 * PI),cos(0.1 * PI));
    r.xy *= mat2(cos(time),-sin(time),sin(time),cos(time));
    float z = time * 12.0 ;
   
    vec2 a = path(z);
    vec3 o = vec3(a /8.0 + vec2(time) * 2.0  ,z);
    vec4 data = trace(o,r);
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.01);
    vec3 fc = mix(vec3(0.5 - data.x,0.5 -data.y,0.5-data.z),vec3(0),1.0 - fog);
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
