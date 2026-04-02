#version 420

//original https://www.shadertoy.com/view/4djGz1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// "DE edge detection" by Kali

// implemented "cartoon mod" by WouterVanNifterick

//#define SHOWONLYEDGES

#define RAY_STEPS 100

#define BRIGHTNESS 1.2
#define GAMMA 1.5

#define detail .00005
#define t time*.3

const vec3 origin=vec3(-1.,.2,0.);
float det=0.0;
vec3 pth1;

mat2 rot(float a) {
    return mat2(cos(a),sin(a),-sin(a),cos(a));    
}

vec4 formula(vec4 p) {
        p.xz = abs(p.xz+1.)-abs(p.xz-1.)-p.xz;
        p.xy*=rot(radians(30.));
        p=p*2./clamp(dot(p.xyz,p.xyz),.05,1.);
    return p;
}

vec2 de(vec3 pos) {
    float hid=0.;
    vec3 tpos=pos;
    tpos.z=abs(2.-mod(tpos.z,4.));
    vec4 p=vec4(tpos,2.);
    float y=max(0.,.35-abs(pos.y-3.35))/.35;
    for (int i=0; i<4; i++) {p=formula(p);}
    float fr=(length(max(vec2(0.),p.yz-2.))-1.)/p.w;
    return vec2(fr,hid);
}

vec3 path(float ti) {
    vec3  p=vec3(sin(ti),(1.-sin(ti*.5)),-cos(ti*.25)*30.)*.5;
    return p;
}

float edge=0.;

// here is edge detection, set to variable "edge"
vec3 normal(vec3 pos) { 
    vec3 e = vec3(0.0,det,0.0);
    vec3 e2 = vec3(0.0,det*2.,0.0);

    vec3 p=pos;
    
    vec3 norm=normalize(vec3(
            de(p+e.yxx).x-de(p-e.yxx).x,
            de(p+e.xyx).x-de(p-e.xyx).x,
            de(p+e.xxy).x-de(p-e.xxy).x
            ));

    p=pos+e2.yxx;
    
    vec3 norm1=normalize(vec3(
            de(p+e.yxx).x-de(p-e.yxx).x,
            de(p+e.xyx).x-de(p-e.xyx).x,
            de(p+e.xxy).x-de(p-e.xxy).x
            ));

    p=pos+e2.xyx;
    
    vec3 norm2=normalize(vec3(
            de(p+e.yxx).x-de(p-e.yxx).x,
            de(p+e.xyx).x-de(p-e.xyx).x,
            de(p+e.xxy).x-de(p-e.xxy).x
            ));

    p=pos+e2.xxy;
    
    vec3 norm3=normalize(vec3(
            de(p+e.yxx).x-de(p-e.yxx).x,
            de(p+e.xyx).x-de(p-e.xyx).x,
            de(p+e.xxy).x-de(p-e.xxy).x
            ));

        p=pos+e2.yxx;
    
    vec3 norm4=normalize(vec3(
            de(p+e.yxx).x-de(p-e.yxx).x,
            de(p+e.xyx).x-de(p-e.xyx).x,
            de(p+e.xxy).x-de(p-e.xxy).x
            ));

    p=pos-e2.xyx;
    
    vec3 norm5=normalize(vec3(
            de(p+e.yxx).x-de(p-e.yxx).x,
            de(p+e.xyx).x-de(p-e.xyx).x,
            de(p+e.xxy).x-de(p-e.xxy).x
            ));

    p=pos-e2.xxy;
    
    vec3 norm6=normalize(vec3(
            de(p+e.yxx).x-de(p-e.yxx).x,
            de(p+e.xyx).x-de(p-e.xyx).x,
            de(p+e.xxy).x-de(p-e.xxy).x
            ));

    
    float d1=max(0.,dot(norm,norm1));
    float d2=max(0.,dot(norm,norm2));
    float d3=max(0.,dot(norm,norm3));
    float d4=max(0.,dot(norm,norm4));
    float d5=max(0.,dot(norm,norm5));
    float d6=max(0.,dot(norm,norm6));

    edge=1.-pow((d1+d2+d3+d4+d5+d6)/6.,150.);    
    
    return normalize(norm);
}

vec3 raymarch(in vec3 from, in vec3 dir) 

{
    edge=0.;
    vec3 p, norm;
    vec2 d=vec2(100.,0.);
    float totdist=0.;
    for (int i=0; i<RAY_STEPS; i++) {
        if (d.x>det && totdist<30.0) {
            p=from+totdist*dir;
            d=de(p);
            det=detail*(1.+totdist*20.);
            totdist+=d.x; 
        }
    }
    vec3 col=vec3(0.);
    norm=normal(p);
#ifdef SHOWONLYEDGES
    return vec3(edge*(1.+norm)-totdist*.15);
#else
    return 1.0-vec3(edge+(2.5*norm+totdist)*0.1);
#endif        
}

vec3 move(inout vec3 dir) {
    vec3 go=path(t);
    vec3 adv=path(t+.7);
    float hd=de(adv).x;
    vec3 advec=normalize(adv-go);
    float an=adv.x-go.x; an*=min(1.,abs(adv.z-go.z))*sign(adv.z-go.z)*.7;
    dir.xy*=mat2(cos(an),sin(an),-sin(an),cos(an));
    an=advec.y*1.7;
    dir.yz*=mat2(cos(an),sin(an),-sin(an),cos(an));
    an=atan(advec.x,advec.z);
    dir.xz*=mat2(cos(an),sin(an),-sin(an),cos(an));
    return go;
}

void main(void)
{
    pth1 = path(t+.3)+origin;
    vec2 uv = gl_FragCoord.xy / resolution.xy*2.-1.;
    uv.y*=resolution.y/resolution.x;
    //vec2 mouse=(iMouse.xy/resolution.xy-.5)*3.;
    //if (iMouse.z<1.) mouse=vec2(0.,-.4);
    vec3 dir=normalize(vec3(uv*.8,1.));
    //dir.yz*=rot(0);//rot(mouse.y);
    //dir.xz*=rot(0);//rot(mouse.x);
    vec3 from=origin+move(dir);
    vec3 color=raymarch(from,dir); 
    color=clamp(color,vec3(.0),vec3(1.));
    color=pow(color,vec3(GAMMA))*BRIGHTNESS;
    glFragColor = vec4(color,1.);
}
