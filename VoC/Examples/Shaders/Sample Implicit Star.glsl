#version 420

// original https://www.shadertoy.com/view/3dXfDr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// the equation of the star shape:
// 4(x²+2y²+z²-1)²-(5x⁴z-10x²z³+z⁵)-1=0
// or: 4(x²+2y²+z²-1)²-Im((x+zi)⁵)-1=0

float func(in vec3 p){
    vec3 u = p*p;
    float d = u.x+2.0*u.y+u.z-1.0;
    if (d>3.0) return d;  // clipping needed because its degree is odd
    return 4.0*d*d-p.z*(5.*u.x*u.x-10.*u.x*u.z+u.z*u.z)-1.0;
}

vec3 calcGrad(vec3 p){
    const float e = .0001;
    float a = func(p+vec3(e,e,e));
    float b = func(p+vec3(e,-e,-e));
    float c = func(p+vec3(-e,e,-e));
    float d = func(p+vec3(-e,-e,e));
    return vec3(a+b-c-d,a-b+c-d,a-b-c+d)*(.25/e);
}

const vec3 light = normalize(vec3(-0.3, 0.1, 1));

vec3 castRay(vec3 p, vec3 d) {
    float t = 1e-3, dt;
    if (func(p) < 0.0) return vec3(0.0, 0.0, 0.0);
    for (int i = 0; i < 1024; i++) {
        dt = func(p + t * d);
        dt /= length(calcGrad(p + t * d));
        t += 0.5*dt;
        if (dt < 1e-2) {
            p += t * d;
            vec3 n = normalize(calcGrad(p));
            if (dot(n, d) > 0.0) n = -n;
            float dif = clamp(dot(n, light), 0.0, 1.0);
            return (0.7*dif+0.2*pow(max(dot(d, light),0.0),4.0)+0.4)*vec3(1.0,0.6,0.1);
        }
        if (t > 20.0) break;
    }
    vec3 col = sin(30.0*d.x)+sin(30.0*d.y)+sin(30.0*d.z)>0.0 ?
        vec3(1.0,0.8,0.6) : vec3(0.9,0.6,0.8);
    t = max(dot(d,light), 0.0);
    return (0.3+0.7*t)*col;
}

#define AA 2
void main(void) {
    float h = 1.5*cos(0.4*time)+1.0;
    float r = sqrt(20.0-h*h)+0.2*(cos(time)+1.0);
    vec3 pos = vec3(r*cos(time), r*sin(time), h);
    float Unit = 0.5*length(resolution);

    vec3 w = normalize(pos);
    vec3 u=normalize(vec3(-w.y,w.x,0));
    vec3 v=cross(w,u);
    mat3 M=-mat3(u,v,w);

    vec3 col;
    for (int i=0;i<AA;i++) for (int j=0;j<AA;j++) {
        vec3 d=M*vec3(0.5*resolution.xy-(gl_FragCoord.xy+vec2(i,j)/float(AA)),Unit);
        col += castRay(pos,normalize(d));
    }
    col/=float(AA*AA);

    col.x=pow(col.x,0.75),col.y=pow(col.y,0.75),col.z=pow(col.z,0.75);

    glFragColor = vec4(col,1.0);
}
