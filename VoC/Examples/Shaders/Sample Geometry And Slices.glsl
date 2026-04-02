#version 420

// original https://www.shadertoy.com/view/wtVBWm

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Author: paperu
// Title: geometry and slices

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

float t;
float aa;
#define P 6.283185307

vec4 mod289(vec4 g){return g-floor(g*(1./289.))*289.;}vec4 permute(vec4 g){return mod289((g*34.+1.)*g);}vec4 taylorInvSqrt(vec4 g){return 1.79284-.853735*g;}vec2 fade(vec2 g){return g*g*g*(g*(g*6.-15.)+10.);}float cnoise(vec2 g){vec4 v=floor(g.rgrg)+vec4(0.,0.,1.,1.),d=fract(g.rgrg)-vec4(0.,0.,1.,1.);v=mod289(v);vec4 r=v.rbrb,a=v.ggaa,p=d.rbrb,e=d.ggaa,c=permute(permute(r)+a),f=fract(c*(1./41.))*2.-1.,t=abs(f)-.5,b=floor(f+.5);f=f-b;vec2 m=vec2(f.r,t.r),o=vec2(f.g,t.g),l=vec2(f.b,t.b),u=vec2(f.a,t.a);vec4 n=taylorInvSqrt(vec4(dot(m,m),dot(l,l),dot(o,o),dot(u,u)));m*=n.r;l*=n.g;o*=n.b;u*=n.a;float i=dot(m,vec2(p.r,e.r)),x=dot(o,vec2(p.g,e.g)),s=dot(l,vec2(p.b,e.b)),S=dot(u,vec2(p.a,e.a));vec2 I=fade(d.rg),y=mix(vec2(i,s),vec2(x,S),I.r);float q=mix(y.r,y.g,I.g);return 2.3*q;}
float rand(in vec2 st){ return fract(sin(dot(st.xy,vec2(12.9898,78.233)))*43758.585); }
mat2 rot(in float a) { return mat2(cos(a),sin(a),-sin(a),cos(a)); }

float sph(in vec3 p, in float r) { return length(p) - r; }
float box(in vec3 p, in vec3 s) { p = abs(p) - s; return max(max(p.x, p.y), p.z); }
float los(in vec3 p, in float s) { p = abs(p); return (p.x+p.y+p.z-s)*0.57735027; }
float slices(in vec3 p, in float nb, in float f) {
    float i = 1./nb;
    return abs(mod(p.y, i) - i*.5) - i*f;
}

vec3 pgen;
float df(in vec3 p) {
    vec3 pp[4];
    p.xz *= rot(t*2.);
    p.xy *= rot(t*.5);
    mat2 rotV1 = rot(-t);
    
    pp[0] = p + vec3(-0.672,0.562,-0.081);
    pp[0].xz *= rotV1;
    pp[0].xy *= rotV1;
    float d0 = max(box(pp[0].yxz, vec3(.1,.1,.75)),slices(pp[0].yzx + t, 5., .25));
    
    pp[1] = p + vec3(0.928,-0.698,-0.081);
    pp[1].xz *= -rotV1;
    pp[1].xy *= rotV1;
    float d1 = max(max(los(pp[1], .5),slices(pp[1], 10., .125)),pp[1].y);
    
    pp[2] = p + vec3(0.328,0.622,-0.081);
    pp[2].xz *= rotV1;
    pp[2].xy *= -rotV1;
    float d2 = max(sph(pp[2], .3),slices(pp[2] - t, 5., .25));
    
    pp[3] = p + vec3(-0.104,-0.359,0.306);
    float k = slices(pp[3].zxy, 10., .2);
    pp[3].xz *= -rotV1;
    pp[3].xy *= -rotV1;
    float d3 = max(box(pp[3], vec3(.35)),k);
    
    float d = min(d0,min(d1,min(d2,d3)));
    pgen = d == d0 ? pp[0]
        : d == d1 ? pp[1]
        : d == d2 ? pp[2]
        : d == d3 ? pp[3] : vec3(0.);
    return d;
}

#define LIM .001
vec3 normal(in vec3 p) { float d = df(p); vec2 u = vec2(0.,LIM); return normalize(vec3(df(p + u.yxx),df(p + u.xyx),df(p + u.xxy)) - d); }

#define MAX_D 10.
#define MAX_IT 30
struct rmRes { vec3 pos; int it; bool hit; };
rmRes rm(in vec3 c, in vec3 r) {
    rmRes res;
    res.pos = c;
    res.hit = false;
    for(int i = 0; i < MAX_IT; i++) {
        float d = df(res.pos);
        if(d < LIM) { res.hit = true; break; }
        if(distance(c,res.pos) > MAX_D) break;
        res.pos += d*r;
        res.it = i;
    }
    return res;
}

void main(void) {
    vec2 st = (gl_FragCoord.xy - .5*resolution.xy)/resolution.y;
    t = time*.1;
    
    vec3 c = vec3(0.,0.,-2.);
    vec3 r = normalize(vec3(st,.5));

    rmRes res = rm(c,r);
    
    vec3 colors[3];
    colors[0] = mix(vec3(1.000,0.151,0.638),vec3(0.965,0.754,0.044),length(st)*2.5);
    colors[1] = vec3(0.092,0.089,0.095) - rand(st+fract(t))*.1;
    colors[2] = vec3(0.062,0.161,0.455) / length(st);
    
    float d1 = cnoise(st*5.+t)+cnoise(st*10.)-2.+length(st)*5.864;
    float d2 = cnoise(st*5.+t+.1245)+cnoise(st*10.+8.5456)-2.+length(st)*5.864;
    vec3 color = mix(colors[0],colors[1],vec3(step(0.,abs(d1)-.1)));
    color = mix(color,colors[2],vec3(step(0.,d2)));
    color = mix(colors[1],color,vec3(step(0.,abs(d2) - .1)));
    
    if(res.hit && step(0.,d2) != 1.) {
        vec3 n = normal(res.pos);
        vec3 l = normalize(vec3(-1.));
        
        float div = .075;
        vec2 pp = vec2(mod(pgen.x, div) - div*(1. - dot(n,l)),pgen.y);
        float d = dot(pp,vec2(1.,0.));
        d = step(0.,d);
        color = mix(colors[0],colors[1],d);
    } else  {
        color += pow(float(res.it)*.02,2.)*colors[2];
    }

    glFragColor = vec4(color,1.);
}
