#version 420

// original https://www.shadertoy.com/view/tdGSRt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
vec2 c2p(vec2 c){return vec2(atan(c.y,c.x),length(c));}
vec2 p2c(vec2 p){return vec2(cos(p.x)*p.y,sin(p.x)*p.y);}
vec2 crep(vec2 uv, float c){
    uv=c2p(uv);
    uv.x=uv.x+PI;
    uv.x=mod(uv.x,2.*PI/c);
    uv.x=abs(uv.x-PI/c);
    uv.x=uv.x-PI;
    return p2c(uv);
}
vec3 look(vec2 uv, vec3 o, vec3 t)
{
    vec3 fwd=normalize(t-o);
    vec3 right=normalize(cross(fwd,vec3(0.,1.,0.)));
    vec3 up=normalize(cross(fwd,right));
    return fwd+right*uv.x+up*uv.y;
}
float box(vec3 p, float s)
{
    float d=abs(p.y)-s;
    d=max(d,abs(p.x)-s);
    d=max(d,abs(p.z)-s);
    return d;
}
float map(vec3 p)
{
    p-=6.5;
    p=mod(p,13.)-6.5;
    for(int i=0;i<5;i++)
    {
        p.xz=crep(p.xz,9.-float(i));
        p.xz+=0.7-0.01;
        float t=p.x;
        p.x=p.y;
        p.y=p.z;
        p.z=t;
    }
    float d=box(p,0.45);
    return d;
}
vec3 gradient(vec3 p)
{
    vec2 e=vec2(0.,0.001);
    return normalize(vec3(map(p+e.yxx)-map(p-e.yxx),
                map(p+e.xyx)-map(p-e.xyx),
                map(p+e.xxy)-map(p-e.xxy)));
}
float march(vec3 o, vec3 r)
{
    float t=0.2;
    for(int i=0;i<70;i++)
    {
        float d=map(o+r*t);
        if(d<0.004) return t;
        t+=d*0.8;
    }
    return 0.;
}
void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv=uv-0.5;
    uv.x=uv.x*resolution.x/resolution.y;

    vec3 o=vec3(cos(time),cos(time),sin(time))*(sin(time*0.6)+1.15)*4.;
    vec3 t=vec3(0.);
    vec3 r=look(uv,o,t);
    float d=march(o,r);

    glFragColor=vec4(0.);
    if(d==0.) return;
    float shade=dot(normalize(vec3(o)),gradient(o+r*d))/pow(1.1,d);
    // Output to screen
    glFragColor = vec4(vec3(shade),1.0);
}
