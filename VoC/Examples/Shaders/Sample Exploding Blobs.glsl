#version 420

// original https://www.shadertoy.com/view/WdtXzj

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float a){
    float c=cos(a);
    float s=sin(a);
    return mat2(c,-s,s,c);
}

float smin(float a, float b, float h){
    float k=clamp((a-b)/h*.5+.5,0.,1.);
    return mix(a,b,k)-k*(1.-k)*h;
}

vec3 smin(vec3 a, vec3 b, float h){
    vec3 k=clamp((a-b)/h*.5+.5,0.,1.);
    return mix(a,b,k)-k*(1.-k)*h;
}

vec3 kifs(vec3 p, float t){
    float s=-2.+4.6*exp(fract(time*.25));
    for(int i=0;i<4;i++){
        p.xz*=rot(t+float(i));
        p.xy*=rot(.7*(t+float(i)));
        p=smin(p,-p,-3.);
        p-=s;
        s*=.7;
    }
    return p;
}

float at=0.;
float dist(vec3 p){
    vec3 p1=kifs(p,time*.1);
    vec3 p2=kifs(p+vec3(2.,2.,-3.),time*.13);
    float d1=length(p1)-1.5;
    float d2=length(p2)-1.4;
    float m1=smin(d1,d2,-1.);
    at+=.075/(.15+abs(m1));
    return m1;
}

void main(void)
{
    vec2 uv = -.5 + gl_FragCoord.xy/resolution.xy;
    uv/=vec2(resolution.y/resolution.x,1.);
    
    //camera stuff
    float zoom = 1.;
    vec3 ro = vec3(0.,0.,-50.);
    ro.xz*=rot(time*.8);
    ro.xy*=rot(time*.4);
    vec3 t = vec3(0.,0.,0.);
    vec3 f = normalize(t-ro);
    vec3 r = normalize(cross(f,vec3(0.,1.,0.)));
    vec3 u = normalize(cross(r,f));
    vec3 rd = normalize(f*zoom + r*uv.x + u*uv.y);
    
    //colour
    vec3 c = vec3(0.);
    
    //raymarching loop
    vec3 p = ro;
    float d;
    for(int i=0;i<100;i++){
        d = dist(p);
        if(d<.001) {d=.1;}
        if(d>50.) break;
        p += d*rd;
        c += pow(at*.01,3.)*vec3(1.,.102,0.);
    }
    
    //get normal
    vec2 e = vec2(0.,.01);
    vec3 n = normalize(dist(p)-vec3(dist(p-e.yxx),dist(p-e.xyx),dist(p-e.xxy)));
    
    glFragColor = vec4(c,1.);
}

