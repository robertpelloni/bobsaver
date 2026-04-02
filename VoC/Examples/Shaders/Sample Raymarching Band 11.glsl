#version 420

// original https://www.shadertoy.com/view/tlfXRX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.14159265;
float map(vec3 p){
    vec2 t = vec2(0.3, 0.05);
    vec3 q = p;
    vec3 r = p;
    p = fract(p / 2.0) * 2.0 - 0.5;
    p.yz *= mat2(cos((time - 1.0/2.0) * PI),-sin((time - 1.0/2.0) * PI)
                 ,sin((time - 1.0/2.0) * PI),cos((time - 1.0/2.0) * PI));
    vec2 r1 = vec2(length(p.xy) - t.x, p.z);
    float torus1 = length(r1) - t.y;
    q = fract(q / 2.0) * 2.0 - 1.5;
    q.yz *= mat2(cos((-time - 1.0/2.0) * PI),-sin((-time - 1.0/2.0) * PI)
                 ,sin((-time - 1.0/2.0) * PI),cos((-time - 1.0/2.0) * PI));
    vec2 r2 = vec2(length(q.xy) - t.x, q.z);
    float torus2 = length(r2) - t.y;
    r = fract(r / 2.0) * 2.0 - 1.0;
    float tubes = min(length(r.xz -vec2(0.5,0)) - 0.1,length(r.yz -vec2(0.5,0)) - 0.1);
    
    return min(min(torus2,torus1),tubes);
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
        t += d * 0.2;
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
    vec3 o = vec3(0.5,0.5,time);
    vec4 data = trace(o,r);
    float t = data.w;
    float fog = 1.0 / (1.0 + t * t * 0.2);
    vec3 fc = mix(vec3(0.5 - data.x,0.5 -data.y,0.5-data.z),vec3(0),1.0 - fog);
    vec3 col1 = vec3(sin(time),cos(time),1);
    vec3 col2 = vec3(1);
    fc = mix(col1/2.0,col2,fog);
    // Output to screen
    glFragColor = vec4(fc,1.0);
}
