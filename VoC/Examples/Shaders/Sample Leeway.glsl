#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/tdXfWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define ss(v) smoothstep(0.01, 0.00, v)

float rand(float x) {
    return fract(sin(x)*233332.32432);
}

float dCircle(vec2 p, float r) {
    return length(p)-r;
}

float dBox(vec2 p, vec2 s) {
    p = abs(p);
    p -= s;
    return max(p.x, p.y);
}

float dTriangle(vec2 p) {
    float r3 = sqrt(3.0);
    p.y -= -r3*0.25;
    return max(-p.y, p.y+r3*abs(p.x)-r3*0.5);
}

float sigmoid(float x, float a) {
    return 1.0/(1.0+exp(-a*x));
}

mat2 rot(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

void main(void)
{
    vec2 p = (2.0*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec2 ip = gl_FragCoord.xy;
    
    float asr = resolution.x/resolution.y;
    float pi = acos(-1.0);
    float tau = acos(-1.0)*2.0;
    
    float t = time*0.6;
    float cy = floor(t);
    float mcy = mod(cy, 3.0);
    float dcy = mod(floor(t-0.5), 13.0);
    float ph = fract(t);
    float dph = fract(t-0.5)+0.5;
    float sigPh = sigmoid(cos(ph*pi), -30.0);
    
    p *= rot(sigmoid(sin(t*0.9), 15.0)*tau);
    
    vec2 q = p;
    q.x = abs(q.x);
    q.x -= asr*(smoothstep(0.01, 0.99, sigmoid(pow(cos(ph*pi), 2.0), -4.0))*3.0)+0.015;
    
    vec2 d;
    vec2 dc = vec2(dCircle(p, 0.5), dCircle(q, 0.7));
    vec2 db = vec2(dBox(p, vec2(0.5)), dBox(q, vec2(0.7)));
    vec2 qq = vec2(q.x, q.y-0.05);
    vec2 dt = vec2(dTriangle(p), dTriangle(qq*0.71)/0.71);
    
    vec2 dFrom, dTo;
    
    if(mcy == 0.0) {
        dFrom = dc;
        dTo = db;
    } else if(mcy == 1.0) {
        dFrom = db;
        dTo = dt;
    } else {
        dFrom = dt;
        dTo = dc;
    }
    d = vec2(mix(dFrom.x, dTo.x, sigPh),
             max(-q.x, -mix(dFrom.y, dTo.y, sigPh)));
    
    vec3 c = mix(vec3(rand(dcy), rand(dcy+2.0), rand(dcy+13.0)),
                 vec3(rand(dcy+1.0), rand(dcy+2.0+1.0), rand(dcy+13.0+1.0)),
                 sigmoid(dph, 20.0));
    c = normalize(c);
    
    vec3 col = vec3(0.0);
    col += sin(length(p))*0.2*c*ss(-d.y);
    
    col += ss(d.x)*c*rand(d.x+time)*2.0;
    
    int ix = int(q.x*40.0);
    int iy = int(abs(q.y)*40.0);
    float v = mod(float(ix^iy), (11.0+dcy))/(10.0+dcy);
    
    col += ss(d.y)*clamp(v, 0.2, 1.0)*pow(c, vec3(0.2));
    col += -exp(length(p))*0.1;
    col = pow(col, vec3(0.5));
    
    glFragColor = vec4(col,1.0);
}
