#version 420

// original https://www.shadertoy.com/view/3t33Rj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define IT 64
#define SD .0005
#define MD 10.

mat2 rot(float a) {
    float s = sin(radians(a));
    float c = cos(radians(a));
    return mat2(c,-s,s,c);
}

float dist(vec3 p) {
    float d = dot(normalize(p),vec3(0.,1.,0.));
    float s = sin(atan(p.x,p.z)*5.) * pow(1.-d,.75);
    float c = cos(d*3.1415*2.5+time*2.);
    return length(p)-2.+s*c*.3;
}

vec3 raymarch(vec3 ro, vec3 rd) {
    vec3 p = ro;
    float td;
    for (int i; i < IT; i++) {
        float d = dist(p);
        td += d;
        p += rd * d;
        if (abs(d) < SD || td > MD) break;
    }
    return p;
}

vec3 normal(vec3 p) {
    vec2 o = vec2(SD,0);
    return normalize(vec3(
    dist(p+o.xyy)-dist(p-o.xyy),
    dist(p+o.yxy)-dist(p-o.yxy),
    dist(p+o.yyx)-dist(p-o.yyx)));
}

void main(void) {
    vec2 uv = (gl_FragCoord.xy-.5*resolution.xy)/resolution.y;
    vec3 ro = vec3(0,3,-5);
    vec3 rd = normalize(vec3(uv,1));
    rd.yz *= rot(31.);
    ro.xz *= rot(time*18.);
    rd.xz *= rot(time*18.);
    vec3 p = raymarch(ro,rd);
    vec3 n = normal(p);
    vec3 ld = normalize(vec3(0,3,-1));
    float l = length(raymarch(p+n*SD*2.,ld)-p) < MD ? 0. : max(dot(n,ld),0.);
    float b = dot(rd,ld)*.5+.5;
    float s = pow(max(dot(reflect(rd,n),ld),0.),50.);
    vec3 obj = mix(vec3(0.,.1,.2),vec3(.7,.8,1.),l)+s*l;
    vec3 sky = mix(vec3(0.,.05,.1),vec3(.4,.6,.9),b);
    vec3 col = length(p) < 5. ? obj : sky;
    glFragColor = vec4(col,1.);
}
