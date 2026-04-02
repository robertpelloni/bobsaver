#version 420

// original https://www.shadertoy.com/view/3tfSRf

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
float temp(){
    return (floor(time) + min(sin(fract(time) * PI / 2.0) * 2.0,1.0));
}
float map(vec3 p){
    p = mod(abs(p), 1.5) - 0.75;

    float rot = temp() * PI / 2.0;
    float size = sin(rot * 2.0 + PI / 4.0);
    p.xz *= mat2(cos(rot),-sin(rot),sin(rot),cos(rot));
    float sphere = length(p) - 0.5;
    float cube = max(max(abs(p.x) - 0.5,abs(p.y) - 0.5),abs(p.z) - 0.5);
    float obj = mix(sphere,cube,0.5 - size * 0.5);
    float poleY = length(p.xz) - 0.1 * size;
    float holes = 100000000.0;
    for(float i = -0.25; i < 0.50; i += 0.25){
        for(float j = -0.25; j < 0.50; j += 0.25){
            float holeZ = length(p.xy - vec2(i,j)) - 0.075 * (1.0 - size);
            float holeX = length(p.yz - vec2(i,j)) - 0.075 * (1.0 - size);
            holes = min(holes,holeX);
            holes = min(holes,holeZ);
        }
    }

    return max(min(obj,poleY),-holes);
    

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
    float rot = temp() * PI / 4.0;
    r.xy *= mat2(cos(rot),-sin(rot),sin(rot),cos(rot));
    vec3 o = vec3(0,0,time * 4.0);
    vec4 data = trace(o,r);
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.2);
    vec3 fc = mix(vec3(0.5 - data.x,0.5 -data.y,0.5-data.z),vec3(0),1.0 - fog);
    //fc = vec3(fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
