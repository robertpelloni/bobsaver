#version 420

// original https://www.shadertoy.com/view/WsSBWh

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define t time*.15
float id=0.;
vec3 col;

float hash(vec2 p)
{
    vec3 p3=fract(vec3(p.xyx)*.1031);
    p3+=dot(p3,p3.yzx+33.33);
    return fract((p3.x+p3.y)*p3.z);
}

mat2 rot(float a) 
{
    float s=sin(a),c=cos(a);
    return mat2(c,s,-s,c);
}

float de(vec3 p)
{
    vec3 pp=p;
    float sc = 1.;
    p.xy*=rot(pp.z*.2+t*.5+sin(p.z*.05+t*2.)*4.);
    p.xy = abs(2. - mod(p.xy, 4.));
    p.z=abs(1.5-mod(p.z,3.));
    vec3 cp=p;
    for (int i=0;i<2;i++) 
    {
        p.xy=abs(p.xy+1.)-abs(p.xy-1.)-p.xy;
        float s=10./clamp(dot(p,p),.1,1.2);
        p=p*s-11.;
        sc=sc*s;
    }
    float f=length(p.xy)/sc;
    float o=min(length(cp.yz),length(cp.xz));
    float l=length(pp.xy)+cos(pp.z*2.1)*.4;
    float d=min(l,min(f,o));
    id=step(o,d);
    col=vec3(.0,.3,1.);
    col*=step(abs(fract(t+pp.z*.01)-.5),.02);
    col+=id;
    col+=vec3(.5,.1,0)*step(l,d);
    return (d-.02)*.5;
}

vec3 normal(vec3 p) {
    vec3 e=vec3(0.,.01,0.);
    return normalize(vec3(de(p+e.yxx),de(p+e.xyx),de(p+e.xxy))-de(p));
}

vec3 march(vec3 from, vec3 dir) 
{
    float d,td=0.;
    vec3 p,c=vec3(0),ot=vec3(1000),g=c;
    for (int i=0;i<200;i++) 
    {
        p=from+dir*td;
        d=de(p);
        td+=d;
        if (d<.001||td>50.) break;
        g+=exp(-.5*d)*col; 
    }
    if (d<.01) {
        p-=dir*.01;
        vec3 n=normal(p);
        c=(.5+col+fract(p.z*20.))*pow(max(0.,dot(dir,-n)),2.)+id;
        c.rb*=rot(dir.y);
    }
    
       return mix(vec3(0,.05,.2),(c+g*.2),exp(-.1*td));
}

void main(void)
{
    vec2 uv=gl_FragCoord.xy/resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;
    uv*=rot(-t);
    vec3 dir=normalize(vec3(uv,sin(t)*2.));
    vec3 from=vec3(sin(t),0.5,t*10.);
    vec3 c=march(from,dir);
    c=mix(length(c)*vec3(.7),c,.7);
     c*=vec3(1.2,.8,.5)*exp(-1.*length(uv));
    glFragColor=vec4(c,1.0)*min(1.,time*.5);
}
